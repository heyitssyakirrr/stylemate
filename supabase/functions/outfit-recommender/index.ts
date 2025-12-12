import { createClient } from '@supabase/supabase-js'

// --- Interfaces for Type Safety ---

interface ClothingItem {
  id: number;
  user_id: string;
  article_type: string;
  base_colour: string;
  season: string;
  usage: string;
  sub_category: string;
  // Fix: Explicitly allow string (from DB text) or number array (from JSON)
  embedding: string | number[]; 
}

interface RequestPayload {
  user_id: string;
  anchor_id?: number;
  // We removed required_slots to fix "unused variable" warning
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

// --- Helper Functions ---

// Fix: Input type is specific, not 'any'
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
  
  // Default to just Top+Bottom if not specified
  const slots = required_slots && required_slots.length > 0 ? required_slots : ['Top', 'Bottom'];

  try {
    const { data: closetData, error } = await supabase
      .from('clothing_items')
      .select('*')
      .eq('user_id', user_id);

    if (error) throw error;
    
    // Explicit cast avoids implicit 'any' issues downstream
    const closet = closetData as ClothingItem[];

    // 1. Filter Candidates
    const candidates = closet.filter((item) => {
      // ✅ Relaxed matching (Case-insensitive)
      const matchUsage = usage.length === 0 || usage.some(u => u.toLowerCase() === item.usage.toLowerCase());
      
      // ✅ Correct logic for "All Seasons"
      const matchSeason = season.length === 0 || season.includes('All Seasons') || season.some(s => s.toLowerCase() === item.season.toLowerCase());
      
      const matchColor = baseColour.length === 0 || baseColour.some(c => c.toLowerCase() === item.base_colour.toLowerCase());
      
      const hasEmbedding = item.embedding !== null;

      return matchUsage && matchSeason && matchColor && hasEmbedding;
    });

    // 2. Define Separate Pools based on your label_maps.json
    // We separate "Inner Tops" from "Outerwear" so we can layer them.
    const innerTopTypes = ['Tshirts', 'Shirts', 'Tops', 'Kurtas', 'Tunics', 'Waistcoat', 'Camisoles', 'Vest'];
    const outerwearTypes = ['Jackets', 'Sweaters', 'Blazers', 'Sweatshirts', 'Rain Jacket', 'Shrug']; // ✅ Outerwear specific
    const bottomTypes = ['Jeans', 'Trousers', 'Shorts', 'Track Pants', 'Skirts', 'Leggings', 'Capris', 'Salwar', 'Churidar', 'Patiala', 'Palazzos'];
    const footwearTypes = ['Casual Shoes', 'Flats', 'Heels', 'Formal Shoes', 'Sports Shoes', 'Sandals', 'Flip Flops'];
    const accessoryTypes = ['Watches', 'Belts', 'Handbags', 'Sunglasses', 'Earrings', 'Necklace and Chains', 'Bags', 'Wallets'];

    // 3. Pool Candidates
    const tops = candidates.filter((i) => 
      innerTopTypes.includes(i.article_type) || (i.sub_category === 'Topwear' && !outerwearTypes.includes(i.article_type))
    );
    
    const layers = candidates.filter((i) => 
      outerwearTypes.includes(i.article_type) // ✅ Pool for Outerwear
    );

    const bottoms = candidates.filter((i) => 
      (i.sub_category === 'Bottomwear') || bottomTypes.includes(i.article_type)
    );

    const shoes = candidates.filter((i) => 
      footwearTypes.includes(i.article_type) || i.sub_category === 'Shoes' || i.sub_category === 'Footwear'
    );

    const accessories = candidates.filter((i) => 
      accessoryTypes.includes(i.article_type) || ['Accessories', 'Watches', 'Jewellery', 'Bags', 'Eyewear'].includes(i.sub_category)
    );

    const recommendations: OutfitRecommendation[] = [];

    // Limit combinations to prevent timeouts
    const safeTops = tops.slice(0, 15);
    const safeBottoms = bottoms.slice(0, 15);
    const safeLayers = layers.slice(0, 5);
    const safeShoes = shoes.slice(0, 5);
    const safeAccs = accessories.slice(0, 5);

    // 4. Generate Combinations with Dynamic Slots
    for (const top of safeTops) {
      for (const btm of safeBottoms) {
        let baseOutfit = [top, btm];

        // --- Try adding Outerwear if requested ---
        let outfitOptions: ClothingItem[][] = [baseOutfit];
        if (slots.includes('Outerwear') && safeLayers.length > 0) {
            let newOptions: ClothingItem[][] = [];
            for (const layer of safeLayers) {
                // For each existing option, branch it with this layer
                outfitOptions.forEach(opt => newOptions.push([...opt, layer]));
            }
            if (newOptions.length > 0) outfitOptions = newOptions;
        }

        // --- Try adding Footwear if requested ---
        if (slots.includes('Footwear') && safeShoes.length > 0) {
            let newOptions: ClothingItem[][] = [];
            for (const shoe of safeShoes) {
                outfitOptions.forEach(opt => newOptions.push([...opt, shoe]));
            }
            if (newOptions.length > 0) outfitOptions = newOptions;
        }

        // --- Try adding Accessories if requested ---
        if (slots.includes('Accessory') && safeAccs.length > 0) {
            let newOptions: ClothingItem[][] = [];
            // Just add top 3 accessories to avoid loop explosion
            const limitedAccs = safeAccs.slice(0, 3);
            for (const acc of limitedAccs) {
                 outfitOptions.forEach(opt => newOptions.push([...opt, acc]));
            }
            if (newOptions.length > 0) outfitOptions = newOptions;
        }

        // Score all generated combinations
        for (const outfit of outfitOptions) {
            const score = calculateHarmony(outfit, anchor_id);
            recommendations.push({ score, items: outfit });
        }
      }
    }

    // 5. Sort & Shuffle
    recommendations.sort((a, b) => b.score - a.score);
    
    // ✅ Add simple shuffling to top 15 results to show variety
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
                // Helpful debugging message
                suggestionLogic: `No outfits found. Tops: ${tops.length}, Bottoms: ${bottoms.length}, Outerwear: ${layers.length}. Try relaxing filters.`,
                alternatives: []
            }),
            { headers: { "Content-Type": "application/json" } }
        );
    }

    const bestOutfit = topResults[0];
    
    // Fix: Explicitly type the mapped alternative object
    const alternatives: OutfitRecommendation[] = topResults.slice(1).map(r => ({
        items: r.items,
        score: Math.round(r.score * 100) // We map score -> harmonyScore in the response payload below
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
    // Fix: Explicit string conversion for unknown error types
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})