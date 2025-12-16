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
  anchor_ids?: number[]; // ✅ CHANGED: Accepts multiple IDs now
  constraints: {
    usage?: string[];
    season?: string[];
    baseColour?: string[];
  };
  required_slots?: string[];
}

interface OutfitRecommendation {
  score: number;
  items: ClothingItem[];
}

// ... (Helper functions: parseEmbedding, cosineSimilarity, calculateHarmony remain the same) ...
function parseEmbedding(embedding: string | number[] | null | undefined): number[] {
  if (!embedding) return [];
  if (Array.isArray(embedding)) return embedding;
  if (typeof embedding === 'string') {
    try { return JSON.parse(embedding); } catch (e) { return []; }
  }
  return [];
}

function cosineSimilarity(vecA: number[], vecB: number[]): number {
  if (!vecA || !vecB || vecA.length === 0 || vecB.length === 0 || vecA.length !== vecB.length) return 0;
  let dotProduct = 0; let normA = 0; let normB = 0;
  for (let i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
    normA += vecA[i] * vecA[i];
    normB += vecB[i] * vecB[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

function calculateHarmony(items: ClothingItem[]): number {
  let score = 0;
  let count = 0;
  // Calculate average similarity between all pairs in the outfit
  for (let i = 0; i < items.length; i++) {
    for (let j = i + 1; j < items.length; j++) {
      const vecA = parseEmbedding(items[i].embedding);
      const vecB = parseEmbedding(items[j].embedding);
      score += cosineSimilarity(vecA, vecB);
      count++;
    }
  }
  return count > 0 ? score / count : 0;
}

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const payload = await req.json() as RequestPayload;
  
  // Handle both single 'anchor_id' (legacy) and 'anchor_ids' (new)
  const incomingAnchorId = (payload as any).anchor_id;
  let anchorIds: number[] = payload.anchor_ids ?? [];
  if (incomingAnchorId && !anchorIds.includes(incomingAnchorId)) {
    anchorIds.push(incomingAnchorId);
  }

  const { constraints, user_id, required_slots } = payload;
  
  const usage = constraints?.usage ?? [];
  const season = constraints?.season ?? [];
  const baseColour = constraints?.baseColour ?? [];
  const slots = required_slots && required_slots.length > 0 ? required_slots : ['Top', 'Bottom'];

  try {
    const { data: closetData, error } = await supabase
      .from('clothing_items')
      .select('*')
      .eq('user_id', user_id);

    if (error) throw error;
    
    let closet = closetData as ClothingItem[];

    // --- 1. Identify Anchor Items ---
    const anchorItems = closet.filter(i => anchorIds.includes(i.id));

    // --- 2. Helper to filter candidates ---
    const filterItems = (items: ClothingItem[], strictSeason: boolean, strictColor: boolean) => {
        return items.filter((item) => {
            // ✅ CRITICAL FIX: If item is an anchor, ALWAYS include it regardless of filters
            if (anchorIds.includes(item.id)) return true;

            // Usage Check
            const matchUsage = usage.length === 0 || usage.some(u => u.toLowerCase() === item.usage.toLowerCase());
            
            // Season Check
            const matchSeason = !strictSeason || 
                                season.length === 0 || 
                                season.includes('All Seasons') || 
                                season.some(s => s.toLowerCase() === item.season.toLowerCase());
            
            // Color Check (Allow neutrals for non-strict)
            const isNeutral = ['white', 'black', 'grey', 'silver', 'gold', 'beige', 'navy'].includes(item.base_colour.toLowerCase());
            
            const matchColor = baseColour.length === 0 || 
                               baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase()) || 
                               (!strictColor && isNeutral);

            const hasEmbedding = item.embedding !== null;
            return matchUsage && matchSeason && matchColor && hasEmbedding;
        });
    };

    // --- 3. Get Candidates ---
    // Start with strict filtering for core items
    const coreCandidates = filterItems(closet, true, true);

    // --- 4. Define Pools with Anchor Enforcement ---
    const getPool = (category: string, candidates: ClothingItem[]) => {
        // Check if we have an anchor for this category
        const anchorForCat = anchorItems.find(i => i.sub_category === category);
        
        // If yes, the pool is ONLY that anchor item
        if (anchorForCat) return [anchorForCat];

        // Otherwise, return filtered candidates for that category
        return candidates.filter(i => i.sub_category === category);
    };

    let tops = getPool('Topwear', coreCandidates);
    let bottoms = getPool('Bottomwear', coreCandidates);
    let dresses = getPool('Dress', coreCandidates);
    let jumpsuits = getPool('Jumpsuit', coreCandidates);
    let sets = getPool('Set', coreCandidates);

    // --- 5. Add-on Pools (Smart Fallback Logic) ---
    const getBestAddonPool = (category: string) => {
        // A. Is there an anchor?
        const anchorForCat = anchorItems.find(i => i.sub_category === category);
        if (anchorForCat) return [anchorForCat];

        // B. Strict Season + Strict Color
        let pool = filterItems(closet, true, true).filter(i => i.sub_category === category);
        
        // C. Fallback: Strict Season + Relaxed Color (Neutrals)
        if (pool.length === 0) {
             pool = filterItems(closet, true, false).filter(i => i.sub_category === category);
        }

        // D. Fallback: Relaxed Season (Any item in category)
        if (pool.length === 0) {
             pool = filterItems(closet, false, false).filter(i => i.sub_category === category);
        }
        return pool;
    };

    const outerwear = slots.includes('Outerwear') ? getBestAddonPool('Outerwear') : [];
    const footwear = slots.includes('Footwear') ? getBestAddonPool('Footwear') : [];
    const accessories = slots.includes('Accessory') ? getBestAddonPool('Accessory') : [];

    // --- 6. Optimization: Slice large pools (But never slice an anchor) ---
    const safeSlice = (arr: ClothingItem[], limit: number) => {
        if (arr.length <= limit) return arr;
        // If array contains anchors (though getPool returns size 1 usually), keep them
        const anchors = arr.filter(i => anchorIds.includes(i.id));
        const others = arr.filter(i => !anchorIds.includes(i.id)).slice(0, limit);
        return [...anchors, ...others];
    };

    const safeTops = safeSlice(tops, 15);
    const safeBottoms = safeSlice(bottoms, 15);
    const safeDresses = safeSlice(dresses, 15);
    const safeJumpsuits = safeSlice(jumpsuits, 15);
    const safeSets = safeSlice(sets, 15);
    const safeOuter = safeSlice(outerwear, 5);
    const safeFoot = safeSlice(footwear, 5);
    const safeAcc = safeSlice(accessories, 5);

    // --- 7. Generate Base Outfits ---
    let baseOutfits: ClothingItem[][] = [];

    // Helper: Check if outfit contains ALL required anchors compatible with this base type
    const containsRelevantAnchors = (outfit: ClothingItem[]) => {
        // We only care about anchors that fit into the current "slots" being built
        // e.g. If building a Dress outfit, we don't care if Top anchor is missing
        return true; 
    };

    // One-Piece Logic
    if (slots.includes('Dress')) {
        safeDresses.forEach(d => baseOutfits.push([d]));
    } 
    else if (slots.includes('Jumpsuit')) {
        safeJumpsuits.forEach(j => baseOutfits.push([j]));
    }
    else if (slots.includes('Set')) {
        safeSets.forEach(s => baseOutfits.push([s]));
    }
    // Separates Logic
    else if (slots.includes('Top') || slots.includes('Bottom')) {
        // Special case: If user selected ONLY a Top anchor and no Bottom anchor (or vice versa),
        // we must ensure we don't return empty list if one pool is empty.
        
        if (safeTops.length > 0 && safeBottoms.length > 0) {
            for (const t of safeTops) {
                for (const b of safeBottoms) {
                    baseOutfits.push([t, b]);
                }
            }
        }
    }

    // --- 8. Layering Logic ---
    const addLayer = (currentOutfits: ClothingItem[][], layerPool: ClothingItem[]) => {
        if (layerPool.length === 0) return currentOutfits;
        
        let newOutfits: ClothingItem[][] = [];
        for (const outfit of currentOutfits) {
            for (const item of layerPool) {
                newOutfits.push([...outfit, item]);
            }
        }
        return newOutfits.length > 0 ? newOutfits : currentOutfits;
    };

    if (outerwear.length > 0) baseOutfits = addLayer(baseOutfits, safeOuter);
    if (footwear.length > 0) baseOutfits = addLayer(baseOutfits, safeFoot);
    
    // For accessories, assume 1 accessory max for combinatorics to prevent timeouts
    if (accessories.length > 0) {
        const limitedAcc = safeAcc.slice(0, 3);
        baseOutfits = addLayer(baseOutfits, limitedAcc);
    }

    // --- 9. Final Validation: Must contain ALL requested anchors ---
    // If user asked for specific Top + Specific Shoe, discard outfits that don't have both.
    const validOutfits = baseOutfits.filter(outfit => {
        const outfitIds = outfit.map(i => i.id);
        // Check if every requested anchor ID is present in this outfit
        // BUT only if that anchor's category is actually part of this outfit structure
        // (This prevents filtering out a valid Dress outfit just because a Top anchor exists in the request)
        
        return anchorIds.every(anchorId => {
            const anchor = anchorItems.find(i => i.id === anchorId);
            if (!anchor) return true; // Should not happen
            
            // Is this anchor's category represented in the current outfit?
            // e.g. If anchor is a Shoe, does this outfit have a Shoe slot?
            // Simplest check: If we have an anchor, it MUST be in the outfit.
            // If the algorithm decided to skip that category (e.g. no outerwear slot), then it's fine.
            // BUT here we forced inclusion in steps 4 & 5. So if it's not there, it's wrong.
            return outfitIds.includes(anchorId);
        });
    });

    const recommendations: OutfitRecommendation[] = [];

    // --- 10. Calculate Harmony ---
    for (const outfit of validOutfits) {
        const score = calculateHarmony(outfit);
        recommendations.push({ score, items: outfit });
    }

    // --- 11. Sort & Return ---
    recommendations.sort((a, b) => b.score - a.score);
    const topResults = recommendations.slice(0, 3);

    if (topResults.length === 0) {
        return new Response(
            JSON.stringify({ 
                items: [],
                harmonyScore: 0,
                suggestionLogic: `No valid outfits found including your selected items. Try fewer constraints.`,
                alternatives: []
            }),
            { headers: { "Content-Type": "application/json" } }
        );
    }

    const bestOutfit = topResults[0];
    const alternatives: OutfitRecommendation[] = topResults.slice(1).map(r => ({
        items: r.items, score: Math.round(r.score * 100)
    }));

    return new Response(
      JSON.stringify({
        items: bestOutfit.items,
        harmonyScore: Math.round(bestOutfit.score * 100),
        suggestionLogic: `Styled ${anchorItems.length > 0 ? 'around your selection' : 'for you'}.`,
        alternatives: alternatives.map(a => ({
            items: a.items, harmonyScore: a.score, suggestionLogic: "Alternative style."
        }))
      }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})