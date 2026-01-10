import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/outfit.dart';

class OutfitController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  Outfit? currentOutfit;
  bool isLoading = false;
  
  // ✅ NEW: Store the parameters of the last request to enable regeneration
  Map<String, dynamic>? _lastRequestParams;
  int _currentResultOffset = 0;

  /// Call this when the user clicks "Generate" on the form page.
  /// It resets the offset to 0 (Best result).
  Future<void> generateOutfit({
    String? usage,
    String? season,
    String? color,
    List<String>? anchorItemIds, 
    required List<String> slots,
    double? temperature,
  }) async {
    _currentResultOffset = 0; // Reset logic
    
    // Save params for regeneration
    _lastRequestParams = {
      'usage': usage,
      'season': season,
      'color': color,
      'anchorItemIds': anchorItemIds,
      'slots': slots,
      'temperature': temperature,
    };

    await _fetchOutfit();
  }

  /// Call this when the user clicks "Regenerate" on the result page.
  /// It increases the offset to fetch the next best result.
  Future<void> regenerateOutfit() async {
    if (_lastRequestParams == null) return;

    // Increment offset to get next best option
    _currentResultOffset++;
    
    await _fetchOutfit();
  }

  /// Internal method to perform the API call
  Future<void> _fetchOutfit() async {
    try {
      isLoading = true; 
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");
      if (_lastRequestParams == null) throw Exception("No constraints set");

      // Extract saved params
      final usage = _lastRequestParams!['usage'];
      final season = _lastRequestParams!['season'];
      final color = _lastRequestParams!['color'];
      final anchorItemIds = _lastRequestParams!['anchorItemIds'];
      final slots = _lastRequestParams!['slots'];
      final temperature = _lastRequestParams!['temperature'];

      final usageFilter = usage != null ? [usage] : [];
      final seasonFilter = season != null ? [season] : [];
      final colorFilter = color != null ? [color] : [];

      List<int> anchors = [];
      if (anchorItemIds != null) {
        anchors = (anchorItemIds as List<String>)
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
          'anchor_ids': anchors,
          'required_slots': slots,
          'current_temperature': temperature,
          'result_offset': _currentResultOffset, // ✅ SEND OFFSET TO SERVER
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
      isLoading = false; 
      notifyListeners();
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