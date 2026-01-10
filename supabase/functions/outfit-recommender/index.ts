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
  current_temperature?: number;
  result_offset?: number; // ✅ NEW: Controls which "rank" of outfit to show
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

function areItemsCompatible(baseItems: ClothingItem[], newItem: ClothingItem, activeSeasons: string[], activeUsage: string[]): boolean {
  // 1. Season Logic
  const hasSeasonConstraint = activeSeasons.length > 0;
  
  if (!hasSeasonConstraint) {
    const newItemSeason = newItem.season.toLowerCase();
    for (const item of baseItems) {
      const currentSeason = item.season.toLowerCase();
      if (newItemSeason === 'all seasons' || currentSeason === 'all seasons') continue;
      if (newItemSeason === '' || currentSeason === '') continue;
      
      // Conflict: Summer vs Winter
      if ((newItemSeason === 'summer' && currentSeason === 'winter') ||
          (newItemSeason === 'winter' && currentSeason === 'summer')) {
        return false; 
      }
    }
  }

  // 2. Usage Logic
  const hasUsageConstraint = activeUsage.length > 0;
  
  if (!hasUsageConstraint) {
    const newItemUsage = newItem.usage.toLowerCase();
    for (const item of baseItems) {
      const currentUsage = item.usage.toLowerCase();
      // Conflict: Sports vs Formal
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

  const { constraints, user_id, required_slots, current_temperature } = payload;
  
  // ✅ NEW: Read the offset parameter (defaults to 0 = Best result)
  const resultOffset = payload.result_offset ?? 0;

  const usage = constraints?.usage ?? [];
  let season = constraints?.season ?? []; 
  const baseColour = constraints?.baseColour ?? [];
  const slots = required_slots && required_slots.length > 0 ? required_slots : ['Top', 'Bottom'];

  // Weather Logic
  if (season.length === 0 && current_temperature !== undefined && current_temperature !== null) {
      if (current_temperature >= 25) season = ['Summer'];
      else if (current_temperature >= 20) season = ['Summer', 'Spring'];
      else if (current_temperature >= 15) season = ['Spring', 'Fall'];
      else if (current_temperature >= 10) season = ['Fall', 'Winter'];
      else season = ['Winter'];
  }

  try {
    const { data: closetData, error } = await supabase
      .from('clothing_items')
      .select('*')
      .eq('user_id', user_id);

    if (error) throw error;
    
    let closet = closetData as ClothingItem[];
    const anchorItems = closet.filter(i => anchorIds.includes(i.id));

    // --- REFINED CANDIDATE SELECTION ---
    const getCandidatesForCategory = (category: string) => {
        // 1. Force Anchor if exists
        const anchor = anchorItems.find(i => i.sub_category === category);
        if (anchor) return [anchor];

        // 2. Strict Usage Filtering
        let candidates = closet.filter(item => {
            if (item.sub_category !== category) return false;
            if (usage.length > 0) {
                return usage.some(u => u.toLowerCase() === item.usage.toLowerCase());
            }
            return true;
        });

        if (candidates.length === 0) return []; 

        // 3. Try Strict Match (Season & Color)
        const strictMatch = candidates.filter(item => {
            const matchSeason = season.length === 0 || season.some(s => s.toLowerCase() === item.season.toLowerCase());
            const matchColor = baseColour.length === 0 || baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase());
            return matchSeason && matchColor;
        });

        if (strictMatch.length > 0) return strictMatch;

        // 4. Try Strict Season (Relax Color)
        const strictSeason = candidates.filter(item => {
            const matchSeason = season.length === 0 || season.some(s => s.toLowerCase() === item.season.toLowerCase());
            return matchSeason;
        });

        if (strictSeason.length > 0) return strictSeason;

        // 5. Smart Season Fallback
        const smartFallback = candidates.filter(item => {
            if (season.length === 0) return true;
            const itemSeason = item.season.toLowerCase();
            if (itemSeason === 'all seasons' || itemSeason === '') return true;

            const requestedSpring = season.some(s => s.toLowerCase() === 'spring');
            const requestedFall = season.some(s => s.toLowerCase() === 'fall');
            const requestedSummer = season.some(s => s.toLowerCase() === 'summer');

            if (requestedSpring && (itemSeason === 'summer' || itemSeason === 'fall')) return true;
            if (requestedFall && (itemSeason === 'summer' || itemSeason === 'spring')) return true;
            if (requestedSummer && (itemSeason === 'spring' || itemSeason === 'fall')) return true;
            return false;
        });

        return smartFallback;
    };

    const tops = getCandidatesForCategory('Topwear');
    const bottoms = getCandidatesForCategory('Bottomwear');
    const dresses = getCandidatesForCategory('Dress');
    const jumpsuits = getCandidatesForCategory('Jumpsuit');
    const sets = getCandidatesForCategory('Set');
    
    const outerwear = slots.includes('Outerwear') ? getCandidatesForCategory('Outerwear') : [];
    const footwear = slots.includes('Footwear') ? getCandidatesForCategory('Footwear') : [];
    const accessories = slots.includes('Accessory') ? getCandidatesForCategory('Accessory') : [];

    const shuffle = (array: ClothingItem[]) => array.sort(() => Math.random() - 0.5);
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

    // One-Piece Logic
    if (slots.includes('Dress') || anchorItems.some(i => i.sub_category === 'Dress')) {
        safeDresses.forEach(d => baseOutfits.push([d]));
    } 
    else if (slots.includes('Jumpsuit') || anchorItems.some(i => i.sub_category === 'Jumpsuit')) {
        safeJumpsuits.forEach(j => baseOutfits.push([j]));
    }
    else if (slots.includes('Set') || anchorItems.some(i => i.sub_category === 'Set')) {
        safeSets.forEach(s => baseOutfits.push([s]));
    }
    // Separates Logic
    else if (slots.includes('Top') || slots.includes('Bottom')) {
        for (const t of safeTops) {
            for (const b of safeBottoms) {
                if (areItemsCompatible([t], b, season, usage)) {
                    baseOutfits.push([t, b]);
                }
            }
        }
    }

    // Add Layers
    const addLayer = (currentOutfits: ClothingItem[][], layerPool: ClothingItem[]) => {
        if (layerPool.length === 0) return currentOutfits;
        let newOutfits: ClothingItem[][] = [];
        for (const outfit of currentOutfits) {
            for (const item of layerPool) {
                if (areItemsCompatible(outfit, item, season, usage)) {
                    newOutfits.push([...outfit, item]);
                }
            }
        }
        return newOutfits.length > 0 ? newOutfits : currentOutfits;
    };

    if (outerwear.length > 0) baseOutfits = addLayer(baseOutfits, safeOuter);
    if (footwear.length > 0) baseOutfits = addLayer(baseOutfits, safeFoot);
    if (accessories.length > 0) baseOutfits = addLayer(baseOutfits, safeAcc.slice(0, 3));

    // Filter Anchors
    const validOutfits = baseOutfits.filter(outfit => {
        const outfitIds = outfit.map(i => i.id);
        return anchorIds.every(anchorId => {
            const anchor = anchorItems.find(i => i.id === anchorId);
            if (!anchor) return true;
            return outfitIds.includes(anchorId);
        });
    });

    const recommendations: OutfitRecommendation[] = [];

    for (const outfit of validOutfits) {
        const score = calculateHarmony(outfit);
        recommendations.push({ score, items: outfit });
    }

    // Sort by Score (Best to Worst)
    recommendations.sort((a, b) => b.score - a.score);

    // Take top 15 results
    const topResults = recommendations.slice(0, 15); 

    if (topResults.length === 0) {
        return new Response(
            JSON.stringify({ items: [], harmonyScore: 0, suggestionLogic: `No outfits found matching your constraints.`, alternatives: [] }),
            { headers: { "Content-Type": "application/json" } }
        );
    }

    // ✅ FIXED: SELECTION LOGIC
    // Use the requested offset to pick the 1st, 2nd, 3rd best result sequentially.
    // If offset exceeds valid results, use modulo to loop back to start.
    const selectedIndex = resultOffset % topResults.length;
    const bestOutfit = topResults[selectedIndex];
    
    // Provide alternatives (next 2 items in the sorted list)
    const nextIndex = (selectedIndex + 1) % topResults.length;
    const nextNextIndex = (selectedIndex + 2) % topResults.length;
    
    const alternatives = [
        topResults[nextIndex], 
        topResults[nextNextIndex]
    ].filter(x => x).map(r => ({
        items: r.items, 
        score: Math.round(r.score * 100)
    }));

    return new Response(
      JSON.stringify({
        items: bestOutfit.items,
        harmonyScore: Math.round(bestOutfit.score * 100),
        suggestionLogic: `Rank #${selectedIndex + 1} recommendation based on style harmony.`,
        alternatives: alternatives.map(a => ({
            items: a.items, harmonyScore: a.score, suggestionLogic: "Alternative option."
        }))
      }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})