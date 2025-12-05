import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/outfit.dart';

class OutfitController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  Outfit? currentOutfit;
  bool isLoading = false;

  Future<void> generateOutfit({
    required String usage,
    required String season,
    required String color,
    String? anchorItemId,
    required List<String> slots, // ["Top", "Bottom", "Outerwear"]
  }) async {
    try {
      isLoading = true; notifyListeners();

      final res = await _supabase.functions.invoke(
        'outfit-recommender',
        body: {
          'constraints': {'usage': [usage], 'season': [season], 'baseColour': [color]},
          'anchor_id': anchorItemId,
          'required_slots': slots,
          'user_id': _supabase.auth.currentUser!.id,
        },
      );

      if (res.data != null) {
        currentOutfit = Outfit.fromJson(res.data);
      }
    } catch (e) {
      debugPrint("Recommendation Error: $e");
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  // New: Mark as Worn Logic
  Future<void> markAsWorn() async {
    if (currentOutfit == null) return;
    for (var item in currentOutfit!.items) {
      // Use RPC if you created one, or simpler update logic:
      // Note: Incrementing safely usually requires an RPC or two calls. 
      // Simplified here for clarity:
      await _supabase.from('clothing_items').update({
        'wear_count': item.wearCount + 1,
        'last_worn_date': DateTime.now().toIso8601String(),
      }).eq('id', item.id);
    }
  }
}