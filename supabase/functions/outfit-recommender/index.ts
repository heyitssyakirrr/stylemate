import { createClient } from 'jsr:@supabase/supabase-js@2'

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
  anchor_ids?: number[];
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

// Helper: Parse embedding string/array
function parseEmbedding(embedding: string | number[] | null | undefined): number[] {
  if (!embedding) return [];
  if (Array.isArray(embedding)) return embedding;
  if (typeof embedding === 'string') {
    try { return JSON.parse(embedding); } catch (e) { return []; }
  }
  return [];
}

// Helper: Math for Visual Similarity
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

// Helper: Calculate Total Outfit Harmony
function calculateHarmony(items: ClothingItem[]): number {
  let score = 0;
  let count = 0;
  // Compare every item against every other item (Visual Consistency)
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

// Helper: Internal Logic Checker (Fixes "Puffer + Shorts" issue)
function areItemsCompatible(baseItems: ClothingItem[], newItem: ClothingItem, constraints: any): boolean {
  // 1. Season Logic
  // If user DID NOT specify a season, we must ensure the outfit has internal consistency.
  // We don't want a 'Winter' jacket with 'Summer' shorts.
  const userHasSeasonFilter = constraints.season && constraints.season.length > 0;
  
  if (!userHasSeasonFilter) {
    const newItemSeason = newItem.season.toLowerCase();
    
    // Check against existing items
    for (const item of baseItems) {
      const currentSeason = item.season.toLowerCase();
      
      // Allow 'All Seasons' to match anything
      if (newItemSeason === 'all seasons' || currentSeason === 'all seasons') continue;
      if (newItemSeason === '' || currentSeason === '') continue;

      // Conflict: Summer vs Winter
      if ((newItemSeason === 'summer' && currentSeason === 'winter') ||
          (newItemSeason === 'winter' && currentSeason === 'summer')) {
        return false; // Incompatible
      }
    }
  }

  // 2. Usage Logic
  // If user DID NOT specify usage, prevent 'Sports' items mixing with 'Formal'
  const userHasUsageFilter = constraints.usage && constraints.usage.length > 0;
  
  if (!userHasUsageFilter) {
    const newItemUsage = newItem.usage.toLowerCase();
    
    for (const item of baseItems) {
      const currentUsage = item.usage.toLowerCase();
      if (newItemUsage === 'sports' && currentUsage === 'formal') return false;
      if (newItemUsage === 'formal' && currentUsage === 'sports') return false;
    }
  }

  return true;
}

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const payload = await req.json() as RequestPayload;
  
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
    const anchorItems = closet.filter(i => anchorIds.includes(i.id));

    // --- SMART FILTERING ---
    // Instead of filtering strictly and failing, we retrieve pools based on priority.
    
    const getCandidatesForCategory = (category: string) => {
        // 1. Force Anchor
        const anchor = anchorItems.find(i => i.sub_category === category);
        if (anchor) return [anchor];

        // 2. Strict Match (User Constraints)
        const strictMatch = closet.filter(item => {
            if (item.sub_category !== category) return false;
            
            const matchUsage = usage.length === 0 || usage.some(u => u.toLowerCase() === item.usage.toLowerCase());
            const matchSeason = season.length === 0 || season.some(s => s.toLowerCase() === item.season.toLowerCase());
            const matchColor = baseColour.length === 0 || baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase());
            
            return matchUsage && matchSeason && matchColor;
        });

        if (strictMatch.length > 0) return strictMatch;

        // 3. Fallback: Relax Season (e.g. No 'Spring' items? Check 'All Seasons')
        const seasonFallback = closet.filter(item => {
            if (item.sub_category !== category) return false;
            
            const matchUsage = usage.length === 0 || usage.some(u => u.toLowerCase() === item.usage.toLowerCase());
            // Allow 'All Seasons' or items with empty season
            const matchSeason = item.season.toLowerCase() === 'all seasons' || item.season === ''; 
            const matchColor = baseColour.length === 0 || baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase());
            
            return matchUsage && matchSeason && matchColor;
        });

        if (seasonFallback.length > 0) return seasonFallback;

        // 4. Fallback: Relax Usage (e.g. No 'Party' shoes? Check Neutral items)
        const usageFallback = closet.filter(item => {
            if (item.sub_category !== category) return false;
            // Relax Usage completely if we are desperate
            const matchSeason = season.length === 0 || season.some(s => s.toLowerCase() === item.season.toLowerCase()) || item.season.toLowerCase() === 'all seasons';
            const matchColor = baseColour.length === 0 || baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase());
            
            return matchSeason && matchColor;
        });

        if (usageFallback.length > 0) return usageFallback;

        // 5. Ultimate Fallback (Just give me something from that category!)
        // Only do this for 'Required' slots.
        if (slots.includes(category) || category === 'Top' || category === 'Bottom') {
             return closet.filter(i => i.sub_category === category);
        }

        return [];
    };

    // Get pools
    const tops = getCandidatesForCategory('Topwear');
    const bottoms = getCandidatesForCategory('Bottomwear');
    const dresses = getCandidatesForCategory('Dress');
    const jumpsuits = getCandidatesForCategory('Jumpsuit');
    const sets = getCandidatesForCategory('Set');
    
    // Add-ons
    const outerwear = slots.includes('Outerwear') ? getCandidatesForCategory('Outerwear') : [];
    const footwear = slots.includes('Footwear') ? getCandidatesForCategory('Footwear') : [];
    const accessories = slots.includes('Accessory') ? getCandidatesForCategory('Accessory') : [];

    // Safety Slice (randomize before slicing to ensure variety on regenerate)
    const shuffle = (array: ClothingItem[]) => array.sort(() => Math.random() - 0.5);
    
    // Keep anchors, shuffle rest
    const safePool = (arr: ClothingItem[], limit: number) => {
        const anchors = arr.filter(i => anchorIds.includes(i.id));
        const others = shuffle(arr.filter(i => !anchorIds.includes(i.id))).slice(0, limit);
        return [...anchors, ...others];
    };

    const safeTops = safePool(tops, 10);
    const safeBottoms = safePool(bottoms, 10);
    const safeDresses = safePool(dresses, 10);
    const safeJumpsuits = safePool(jumpsuits, 10);
    const safeSets = safePool(sets, 10);
    const safeOuter = safePool(outerwear, 5);
    const safeFoot = safePool(footwear, 5);
    const safeAcc = safePool(accessories, 5);

    // --- GENERATE OUTFITS ---
    let baseOutfits: ClothingItem[][] = [];

    // One-Piece
    if (slots.includes('Dress') || anchorItems.some(i => i.sub_category === 'Dress')) {
        safeDresses.forEach(d => baseOutfits.push([d]));
    } 
    else if (slots.includes('Jumpsuit') || anchorItems.some(i => i.sub_category === 'Jumpsuit')) {
        safeJumpsuits.forEach(j => baseOutfits.push([j]));
    }
    else if (slots.includes('Set') || anchorItems.some(i => i.sub_category === 'Set')) {
        safeSets.forEach(s => baseOutfits.push([s]));
    }
    // Separates
    else if (slots.includes('Top') || slots.includes('Bottom')) {
        for (const t of safeTops) {
            for (const b of safeBottoms) {
                // Internal Consistency Check
                if (areItemsCompatible([t], b, constraints)) {
                    baseOutfits.push([t, b]);
                }
            }
        }
    }

    // Add Layers with Consistency Checks
    const addLayer = (currentOutfits: ClothingItem[][], layerPool: ClothingItem[]) => {
        if (layerPool.length === 0) return currentOutfits;
        
        let newOutfits: ClothingItem[][] = [];
        for (const outfit of currentOutfits) {
            for (const item of layerPool) {
                // Only add if it makes sense (e.g. No Puffer with Shorts)
                if (areItemsCompatible(outfit, item, constraints)) {
                    newOutfits.push([...outfit, item]);
                }
            }
        }
        return newOutfits.length > 0 ? newOutfits : currentOutfits;
    };

    if (outerwear.length > 0) baseOutfits = addLayer(baseOutfits, safeOuter);
    if (footwear.length > 0) baseOutfits = addLayer(baseOutfits, safeFoot);
    if (accessories.length > 0) baseOutfits = addLayer(baseOutfits, safeAcc.slice(0, 3));

    // Filter for Anchors
    const validOutfits = baseOutfits.filter(outfit => {
        const outfitIds = outfit.map(i => i.id);
        return anchorIds.every(anchorId => {
            const anchor = anchorItems.find(i => i.id === anchorId);
            if (!anchor) return true;
            return outfitIds.includes(anchorId);
        });
    });

    const recommendations: OutfitRecommendation[] = [];

    // Calculate Scores
    for (const outfit of validOutfits) {
        const score = calculateHarmony(outfit);
        recommendations.push({ score, items: outfit });
    }

    // Sort by Score
    recommendations.sort((a, b) => b.score - a.score);

    // --- FIX 3: Random Selection from Top Results ---
    // Instead of always taking index 0, we take the top 5 (which are all good)
    // and pick one randomly. This fixes the "Regenerate" issue.
    const topResults = recommendations.slice(0, 5); 

    if (topResults.length === 0) {
        return new Response(
            JSON.stringify({ 
                items: [],
                harmonyScore: 0,
                suggestionLogic: `No outfits found. Try removing some filters.`,
                alternatives: []
            }),
            { headers: { "Content-Type": "application/json" } }
        );
    }

    // Pick random from top 5 for variety
    const randomIndex = Math.floor(Math.random() * topResults.length);
    const bestOutfit = topResults[randomIndex];
    
    // Alternatives are the others from the top pool
    const alternatives = topResults.filter((_, idx) => idx !== randomIndex).map(r => ({
        items: r.items, score: Math.round(r.score * 100)
    }));

    return new Response(
      JSON.stringify({
        items: bestOutfit.items,
        harmonyScore: Math.round(bestOutfit.score * 100),
        suggestionLogic: `Styled based on ${season.join('/') || 'context'} and harmony.`,
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