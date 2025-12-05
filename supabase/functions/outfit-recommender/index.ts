import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// --- 1. Helper: Cosine Similarity ---
// Calculates the cosine similarity between two vectors (range -1 to 1)
// Higher is better (more visually similar/harmonious)
function cosineSimilarity(vecA: number[], vecB: number[]): number {
  if (vecA.length !== vecB.length) return 0;
  
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  
  for (let i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
    normA += vecA[i] * vecA[i];
    normB += vecB[i] * vecB[i];
  }
  
  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// --- 2. Helper: Calculate Outfit Harmony ---
// Averages the similarity scores between items in an outfit
function calculateHarmony(items: any[], anchorId: number | null): number {
  let score = 0;
  let count = 0;

  if (anchorId) {
    // SCENARIO A: User picked an Anchor Item (Visual Constraint)
    // We strictly score how well other items match the Anchor.
    const anchor = items.find((i: any) => i.id === anchorId);
    if (!anchor) return 0;
    
    // Parse anchor vector (Supabase might return it as a JSON string or raw array)
    const vecAnchor = typeof anchor.embedding === 'string' 
      ? JSON.parse(anchor.embedding) 
      : anchor.embedding;

    for (const item of items) {
      if (item.id !== anchorId) {
        const vecB = typeof item.embedding === 'string' 
          ? JSON.parse(item.embedding) 
          : item.embedding;
          
        score += cosineSimilarity(vecAnchor, vecB);
        count++;
      }
    }
  } else {
    // SCENARIO B: No Anchor (Internal Consistency)
    // We measure how well all items match each other.
    for (let i = 0; i < items.length; i++) {
      for (let j = i + 1; j < items.length; j++) {
        const vecA = typeof items[i].embedding === 'string' ? JSON.parse(items[i].embedding) : items[i].embedding;
        const vecB = typeof items[j].embedding === 'string' ? JSON.parse(items[j].embedding) : items[j].embedding;
        
        score += cosineSimilarity(vecA, vecB);
        count++;
      }
    }
  }
  
  return count > 0 ? score / count : 0;
}

// --- 3. Main Handler ---
serve(async (req) => {
  // Setup Supabase Client
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  // Parse Request Body from Flutter
  const { constraints, anchor_id, user_id, required_slots } = await req.json();
  const { usage, season, baseColour } = constraints;

  try {
    // A. FETCH CLOSET (Stage 1 Filter: Database Level)
    // We get ALL items for the user. 
    // Optimization: In a real app with 1000s of items, use .contains() or .in() filters here.
    const { data: closet, error } = await supabase
      .from('clothing_items')
      .select('*')
      .eq('user_id', user_id);

    if (error) throw error;

    // B. REFINE FILTER (Memory Level)
    // JavaScript is flexible for filtering the specific arrays sent by Flutter.
    const candidates = closet.filter((item: any) => {
      // Logic: If constraints are provided, item must match AT LEAST one value in the list.
      // If constraint list is empty, we assume "Any".
      
      const matchUsage = usage.length === 0 || usage.includes(item.usage);
      
      // Special logic for 'All' season or exact match
      const matchSeason = season.length === 0 || season.includes('All') || season.includes(item.season);
      
      const matchColor = baseColour.length === 0 || baseColour.includes(item.base_colour);
      
      return matchUsage && matchSeason && matchColor;
    });

    // C. GROUP BY SLOT (Mapping logic)
    // We map common article_type strings to logical "Slots" (Top, Bottom).
    // You should expand these lists based on your label_maps.json content.
    
    const topTypes = ['Tshirts', 'Shirts', 'Tops', 'Sweaters', 'Jackets', 'Kurtas', 'Blazers'];
    const bottomTypes = ['Jeans', 'Trousers', 'Shorts', 'Track Pants', 'Skirts', 'Leggings', 'Capris'];

    const tops = candidates.filter((i: any) => topTypes.includes(i.article_type));
    const bottoms = candidates.filter((i: any) => bottomTypes.includes(i.article_type));

    // D. GENERATE OUTFITS (Combinations)
    let recommendations = [];

    // Safety: Slice lists to prevent timeouts if user has huge closets (max 50x50 = 2500 combos)
    const safeTops = tops.slice(0, 50);
    const safeBottoms = bottoms.slice(0, 50);

    // Loop: Top + Bottom
    for (const top of safeTops) {
      for (const btm of safeBottoms) {
        const outfitItems = [top, btm];
        
        // E. SCORE OUTFIT (Stage 2: KNN/Harmony)
        const score = calculateHarmony(outfitItems, anchor_id);
        
        // Push result
        recommendations.push({ score, items: outfitItems });
      }
    }

    // F. SORT & STRUCTURE RESPONSE
    // Sort by highest harmony score descending
    recommendations.sort((a, b) => b.score - a.score);
    
    // Take top 3
    const topResults = recommendations.slice(0, 3);

    // Handle case with no results
    if (topResults.length === 0) {
        return new Response(
            JSON.stringify({ recommendations: [], message: "No valid outfits found matching constraints." }),
            { headers: { "Content-Type": "application/json" } }
        );
    }

    // Construct the final JSON structure expected by Flutter Outfit.fromJson
    const bestOutfit = topResults[0];
    const alternatives = topResults.slice(1).map(r => ({
        items: r.items,
        harmonyScore: Math.round(r.score * 100),
        suggestionLogic: "Great alternative based on your closet."
    }));

    const responsePayload = {
        // Primary Recommendation
        items: bestOutfit.items,
        harmonyScore: Math.round(bestOutfit.score * 100),
        suggestionLogic: `High visual match for ${usage.join('/')} in ${season.join('/')}`,
        
        // List of alternatives
        alternatives: alternatives
    };

    return new Response(
      JSON.stringify(responsePayload),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})
