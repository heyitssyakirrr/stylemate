// lib/controllers/outfit_controller.dart

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
    required List<String> slots, // e.g. ["Top", "Bottom", "Outerwear"]
  }) async {
    try {
      isLoading = true; notifyListeners();

      // Ensure user is logged in
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      // Call the Supabase Edge Function (Python/TS backend)
      final res = await _supabase.functions.invoke(
        'outfit-recommender',
        body: {
          'user_id': userId,
          'constraints': {
            'usage': [usage],        // e.g. "Casual"
            'season': [season],      // e.g. "Summer"
            'baseColour': [color]    // e.g. "Blue" (Maps to ColorPreference)
          },
          'anchor_id': anchorItemId, // Specific Item ID (e.g. the Blue Jeans)
          'required_slots': slots,   // e.g. ["Top", "Bottom"]
        },
      );

      if (res.data != null) {
        currentOutfit = Outfit.fromJson(res.data);
      } else {
        // Handle case where function returns null (no valid outfit found)
        currentOutfit = null;
      }
    } catch (e) {
      debugPrint("Recommendation Error: $e");
      currentOutfit = null;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  // Mark as Worn Logic
  Future<void> markAsWorn() async {
    if (currentOutfit == null) return;
    
    // We iterate through items and update them.
    // In a real scenario, you might batch this or call a specific RPC function.
    for (var item in currentOutfit!.items) {
      try {
        await _supabase.from('clothing_items').update({
          'wear_count': item.wearCount + 1,
          'last_worn_date': DateTime.now().toIso8601String(),
        }).eq('id', item.id);
      } catch (e) {
        debugPrint("Error marking item ${item.id} as worn: $e");
      }
    }
  }
}