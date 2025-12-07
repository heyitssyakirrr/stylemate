import { createClient } from '@supabase/supabase-js'

// --- Interfaces for Type Safety ---

interface ClothingItem {
  id: number;
  user_id: string;
  article_type: string;
  base_colour: string;
  season: string;
  usage: string;
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
  const { constraints, anchor_id, user_id } = payload;
  
  const usage = constraints?.usage ?? [];
  const season = constraints?.season ?? [];
  const baseColour = constraints?.baseColour ?? [];

  try {
    const { data: closetData, error } = await supabase
      .from('clothing_items')
      .select('*')
      .eq('user_id', user_id);

    if (error) throw error;
    
    // Explicit cast avoids implicit 'any' issues downstream
    const closet = closetData as ClothingItem[];

    const candidates = closet.filter((item) => {
      const matchUsage = usage.length === 0 || usage.includes(item.usage);
      const matchSeason = season.length === 0 || season.includes('All') || season.includes(item.season);
      const matchColor = baseColour.length === 0 || baseColour.includes(item.base_colour);
      const hasEmbedding = item.embedding !== null;

      return matchUsage && matchSeason && matchColor && hasEmbedding;
    });

    const topTypes = ['Tshirts', 'Shirts', 'Tops', 'Sweaters', 'Jackets', 'Kurtas', 'Blazers'];
    const bottomTypes = ['Jeans', 'Trousers', 'Shorts', 'Track Pants', 'Skirts', 'Leggings', 'Capris'];

    const tops = candidates.filter((i) => topTypes.includes(i.article_type));
    const bottoms = candidates.filter((i) => bottomTypes.includes(i.article_type));

    // Fix: recommendations is strictly typed, removing the "implicitly any[]" warning
    const recommendations: OutfitRecommendation[] = [];

    const safeTops = tops.slice(0, 50);
    const safeBottoms = bottoms.slice(0, 50);

    for (const top of safeTops) {
      for (const btm of safeBottoms) {
        const outfitItems = [top, btm];
        const score = calculateHarmony(outfitItems, anchor_id);
        recommendations.push({ score, items: outfitItems });
      }
    }

    recommendations.sort((a, b) => b.score - a.score);
    
    const topResults = recommendations.slice(0, 3);

    if (topResults.length === 0) {
        return new Response(
            JSON.stringify({ 
                items: [],
                harmonyScore: 0,
                suggestionLogic: "No valid outfits found matching constraints.",
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
        suggestionLogic: `High visual match for ${(usage || []).join('/')} in ${(season || []).join('/')}`,
        // Map the typed alternatives to the structure expected by Flutter
        alternatives: alternatives.map(a => ({
            items: a.items,
            harmonyScore: a.score,
            suggestionLogic: "Great alternative based on your closet."
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