import { createClient } from '@supabase/supabase-js'

interface ClothingItem {
  id: number;
  user_id: string;
  article_type: string;
  base_colour: string;
  season: string;
  usage: string;
  sub_category: string;
  embedding: string | number[]; 
}

interface RequestPayload {
  user_id: string;
  anchor_id?: number;
  constraints: {
    usage?: string[];
    season?: string[];
    baseColour?: string[];
  };
  required_slots?: string[]; // ✅ Added to support dynamic slots like Outerwear
}

interface OutfitRecommendation {
  score: number;
  items: ClothingItem[];
}

function parseEmbedding(embedding: string | number[] | null | undefined): number[] {
  if (!embedding) return [];
  if (Array.isArray(embedding)) return embedding;
  if (typeof embedding === 'string') {
    try {
      return JSON.parse(embedding);
    } catch (e) {
      console.error("Error parsing embedding JSON:", e);
      return [];
    }
  }
  return [];
}

function cosineSimilarity(vecA: number[], vecB: number[]): number {
  if (!vecA || !vecB || vecA.length === 0 || vecB.length === 0 || vecA.length !== vecB.length) return 0;
  
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

function calculateHarmony(items: ClothingItem[], anchorId: number | undefined): number {
  let score = 0;
  let count = 0;

  if (anchorId) {
    const anchor = items.find((i) => i.id === anchorId);
    if (!anchor) return 0;
    
    const vecAnchor = parseEmbedding(anchor.embedding);

    for (const item of items) {
      if (item.id !== anchorId) {
        const vecB = parseEmbedding(item.embedding);
        score += cosineSimilarity(vecAnchor, vecB);
        count++;
      }
    }
  } else {
    for (let i = 0; i < items.length; i++) {
      for (let j = i + 1; j < items.length; j++) {
        const vecA = parseEmbedding(items[i].embedding);
        const vecB = parseEmbedding(items[j].embedding);
        score += cosineSimilarity(vecA, vecB);
        count++;
      }
    }
  }
  
  return count > 0 ? score / count : 0;
}

// --- Main Handler ---

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const payload = await req.json() as RequestPayload;
  const { constraints, anchor_id, user_id, required_slots } = payload;
  
  const usage = constraints?.usage ?? [];
  const season = constraints?.season ?? [];
  const baseColour = constraints?.baseColour ?? [];
  
  // Default to Top+Bottom if not specified
  const slots = required_slots && required_slots.length > 0 ? required_slots : ['Top', 'Bottom'];

  try {
    const { data: closetData, error } = await supabase
      .from('clothing_items')
      .select('*')
      .eq('user_id', user_id);

    if (error) throw error;
    
    const closet = closetData as ClothingItem[];

    // 1. Filter Candidates
    const candidates = closet.filter((item) => {
      const matchUsage = usage.length === 0 || usage.some(u => u.toLowerCase() === item.usage.toLowerCase());
      
      // ✅ Accessories often don't have seasons/usage strictness, relax it for them
      const isAccessory = ['Accessory', 'Footwear'].includes(item.sub_category);
      
      const matchSeason = isAccessory || season.length === 0 || season.includes('All Seasons') || season.some(s => s.toLowerCase() === item.season.toLowerCase());
      const matchColor = baseColour.length === 0 || baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase());
      const hasEmbedding = item.embedding !== null;

      return matchUsage && matchSeason && matchColor && hasEmbedding;
    });

    // 2. Define Pools based on the new Parent Categories (sub_category)
    const tops = candidates.filter(i => i.sub_category === 'Topwear');
    const bottoms = candidates.filter(i => i.sub_category === 'Bottomwear');
    const dresses = candidates.filter(i => i.sub_category === 'Dress');
    const jumpsuits = candidates.filter(i => i.sub_category === 'Jumpsuit');
    const sets = candidates.filter(i => i.sub_category === 'Set');
    
    // Add-on Pools
    const outerwear = candidates.filter(i => i.sub_category === 'Outerwear');
    const footwear = candidates.filter(i => i.sub_category === 'Footwear');
    const accessories = candidates.filter(i => i.sub_category === 'Accessory');

    const recommendations: OutfitRecommendation[] = [];

    // Limit pools to prevent timeouts
    const safeTops = tops.slice(0, 15);
    const safeBottoms = bottoms.slice(0, 15);
    const safeDresses = dresses.slice(0, 15);
    const safeJumpsuits = jumpsuits.slice(0, 15);
    const safeSets = sets.slice(0, 15);
    
    const safeOuter = outerwear.slice(0, 5);
    const safeFoot = footwear.slice(0, 5);
    const safeAcc = accessories.slice(0, 5);

    // 3. Generate Base Outfits (The Core Layer)
    let baseOutfits: ClothingItem[][] = [];

    if (slots.includes('Dress')) {
        safeDresses.forEach(d => baseOutfits.push([d]));
    } 
    else if (slots.includes('Jumpsuit')) {
        safeJumpsuits.forEach(j => baseOutfits.push([j]));
    }
    else if (slots.includes('Set')) {
        safeSets.forEach(s => baseOutfits.push([s]));
    }
    else if (slots.includes('Top') || slots.includes('Bottom')) {
        // Separates Logic: Create pairs
        for (const t of safeTops) {
            for (const b of safeBottoms) {
                baseOutfits.push([t, b]);
            }
        }
    }

    // 4. Layering Logic: Add requested Add-ons to ALL base outfits
    
    // Add Outerwear?
    if (slots.includes('Outerwear') && safeOuter.length > 0) {
        let newBases: ClothingItem[][] = [];
        for (const base of baseOutfits) {
            for (const layer of safeOuter) {
                newBases.push([...base, layer]);
            }
        }
        if (newBases.length > 0) baseOutfits = newBases;
    }

    // Add Footwear?
    if (slots.includes('Footwear') && safeFoot.length > 0) {
        let newBases: ClothingItem[][] = [];
        for (const base of baseOutfits) {
            for (const shoe of safeFoot) {
                newBases.push([...base, shoe]);
            }
        }
        if (newBases.length > 0) baseOutfits = newBases;
    }

    // Add Accessory?
    if (slots.includes('Accessory') && safeAcc.length > 0) {
        let newBases: ClothingItem[][] = [];
        // Just add top 2 accessories per outfit to avoid massive list
        const limitedAcc = safeAcc.slice(0, 2); 
        for (const base of baseOutfits) {
            for (const acc of limitedAcc) {
                newBases.push([...base, acc]);
            }
        }
        if (newBases.length > 0) baseOutfits = newBases;
    }

    // 5. Calculate Harmony Score
    for (const outfit of baseOutfits) {
        const score = calculateHarmony(outfit, anchor_id);
        recommendations.push({ score, items: outfit });
    }

    // 6. Sort & Shuffle
    recommendations.sort((a, b) => b.score - a.score);
    
    const topPool = recommendations.slice(0, 15);
    // Fisher-Yates shuffle
    for (let i = topPool.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [topPool[i], topPool[j]] = [topPool[j], topPool[i]];
    }

    const topResults = topPool.slice(0, 3);

    if (topResults.length === 0) {
        return new Response(
            JSON.stringify({ 
                items: [],
                harmonyScore: 0,
                suggestionLogic: `No valid outfits found. Base items found: ${baseOutfits.length}. Check if you have uploaded matching items for the requested slots.`,
                alternatives: []
            }),
            { headers: { "Content-Type": "application/json" } }
        );
    }

    const bestOutfit = topResults[0];
    
    const alternatives: OutfitRecommendation[] = topResults.slice(1).map(r => ({
        items: r.items,
        score: Math.round(r.score * 100) 
    }));

    const responsePayload = {
        items: bestOutfit.items,
        harmonyScore: Math.round(bestOutfit.score * 100),
        suggestionLogic: `Styled ${bestOutfit.items.length}-piece look based on your ${usage.join('/')} needs.`,
        alternatives: alternatives.map(a => ({
            items: a.items,
            harmonyScore: a.score,
            suggestionLogic: "Great alternative."
        }))
    };

    return new Response(
      JSON.stringify(responsePayload),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})