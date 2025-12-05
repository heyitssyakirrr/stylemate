import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// --- HELPER: Cosine Similarity ---
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
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// --- HELPER: Calculate Outfit Harmony Score ---
function calculateHarmonyScore(outfitItems: any[], anchorId: number | null): number {
  if (outfitItems.length < 2) return 0;
  
  let totalScore = 0;
  let pairCount = 0;

  // If anchor exists, score based on similarity to anchor
  if (anchorId) {
    const anchorItem = outfitItems.find((i: any) => i.id === anchorId);
    if (!anchorItem) return 0;

    for (const item of outfitItems) {
      if (item.id !== anchorId) {
        // Convert 'vector' string from DB back to array if needed
        const vecA = JSON.parse(anchorItem.embedding_vector); 
        const vecB = JSON.parse(item.embedding_vector);
        totalScore += cosineSimilarity(vecA, vecB);
        pairCount++;
      }
    }
    return pairCount > 0 ? totalScore / pairCount : 0;
  } 
  
  // Fallback: Internal consistency (Average pairwise)
  for (let i = 0; i < outfitItems.length; i++) {
    for (let j = i + 1; j < outfitItems.length; j++) {
      const vecA = JSON.parse(outfitItems[i].embedding_vector);
      const vecB = JSON.parse(outfitItems[j].embedding_vector);
      totalScore += cosineSimilarity(vecA, vecB);
      pairCount++;
    }
  }
  
  return pairCount > 0 ? totalScore / pairCount : 0;
}


serve(async (req) => {
  // 1. Setup Supabase Client
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  // 2. Parse Request Body
  const { constraints, anchor_id, user_id } = await req.json();
  const { usage, season, baseColour } = constraints;

  try {
    // 3. Stage 1: Filtering (Query Database)
    // We fetch ALL items that match ANY of the constraints to perform logic in memory
    // Note: In production SQL, you'd be more specific.
    let query = supabaseClient.from('clothing_items').select('*').eq('user_id', user_id);
    
    // Simple filter: fetch closet. (Refine filtering in memory for complex OR logic)
    const { data: closetItems, error } = await query;
    if (error) throw error;

    // Filter in Memory (JavaScript)
    // Keep item if it matches usage OR season OR color (adjust logic as needed)
    const filteredItems = closetItems.filter((item: any) => {
        const usageMatch = usage.includes(item.usage);
        const seasonMatch = season.includes('All') || season.includes(item.season); // 'All' allows everything
        const colorMatch = baseColour.includes(item.base_colour);
        return usageMatch && seasonMatch && colorMatch;
    });

    // 4. Group by Slot
    const tops = filteredItems.filter((i: any) => ['T-Shirt', 'Top', 'Shirt', 'Sweater'].includes(i.article_type));
    const bottoms = filteredItems.filter((i: any) => ['Jeans', 'Trousers', 'Shorts', 'Skirt'].includes(i.article_type));
    
    // 5. Generate Combinations (Cartesian Product)
    const outfits = [];
    
    // Limit to 50x50 to prevent timeout
    const safeTops = tops.slice(0, 50);
    const safeBottoms = bottoms.slice(0, 50);

    for (const top of safeTops) {
      for (const bottom of safeBottoms) {
        const currentOutfit = [top, bottom];
        
        // 6. Stage 2: Scoring
        const score = calculateHarmonyScore(currentOutfit, anchor_id);
        
        outfits.push({
          score: score,
          items: [top, bottom] 
        });
      }
    }

    // 7. Sort and Return Top 3
    outfits.sort((a, b) => b.score - a.score);
    const topRecommendations = outfits.slice(0, 3);

    return new Response(
      JSON.stringify({ recommendations: topRecommendations }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
```

### **Step 4: Deploy the Function**

1.  **Deploy Command:**
    Run this in your terminal:
    ```bash
    supabase functions deploy outfit-recommender --project-ref your_project_ref
    ```
    *Replace `your_project_ref` with your actual Supabase project ID (found in Dashboard URL `app.supabase.com/project/xyz...` -> `xyz`).*

2.  **Set Secrets:**
    The function needs access to your database. Run:
    ```bash
    supabase secrets set SUPABASE_URL=your_supabase_url SUPABASE_ANON_KEY=your_anon_key
    ```

### **Step 5: Call it from Flutter**

Your Flutter code (which I provided in the previous response) uses:

```dart
await _supabase.functions.invoke('outfit-recommender', body: { ... })