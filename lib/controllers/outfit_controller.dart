import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';

class OutfitController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ClothingItem> _recommendations = [];
  bool _isLoading = false;

  List<ClothingItem> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  Future<void> generateOutfit({
    required String usage,
    required String season,
    required String color,
    String? anchorItemId, // Optional anchor item ID
  }) async {
    try {
      _setLoading(true);

      // Call the Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'outfit-recommender',
        body: {
          'constraints': {
            'usage': [usage],
            'season': [season],
            'baseColour': [color],
          },
          'anchor_id': anchorItemId,
        },
      );

      // Parse response (Assuming function returns list of item IDs or full objects)
      final data = response.data;
      if (data != null && data['recommendations'] != null) {
         // Fetch full item details for the recommended IDs if function only returns IDs
         // Or parse directly if function returns full objects
         // ... Implementation depends on your Edge Function response structure
         print("Recommendations received: ${data['recommendations']}");
      }
      
    } catch (e) {
      print('Recommendation error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}