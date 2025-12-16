// lib/controllers/outfit_controller.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/outfit.dart';

class OutfitController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  Outfit? currentOutfit;
  bool isLoading = false;

  Future<void> generateOutfit({
    String? usage,
    String? season,
    String? color,
    List<String>? anchorItemIds, // ✅ CHANGED: Accepts a list of IDs
    required List<String> slots,
  }) async {
    try {
      isLoading = true; notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final usageFilter = usage != null ? [usage] : [];
      final seasonFilter = season != null ? [season] : [];
      final colorFilter = color != null ? [color] : [];

      // ✅ NEW: Prepare List of Integers
      List<int> anchors = [];
      if (anchorItemIds != null) {
        anchors = anchorItemIds
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .toList();
      }

      final res = await _supabase.functions.invoke(
        'outfit-recommender',
        body: {
          'user_id': userId,
          'constraints': {
            'usage': usageFilter,       
            'season': seasonFilter,     
            'baseColour': colorFilter   
          },
          'anchor_ids': anchors, // ✅ SENDING PLURAL
          'required_slots': slots,
        },
      );

      if (res.data != null) {
        currentOutfit = Outfit.fromJson(res.data);
      } else {
        currentOutfit = null;
      }
    } catch (e) {
      debugPrint("Recommendation Error: $e");
      currentOutfit = null;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> markAsWorn() async {
    if (currentOutfit == null) return;
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