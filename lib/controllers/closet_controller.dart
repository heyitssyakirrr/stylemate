import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';

class ClosetController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  // _allItems stores the complete database fetch
  List<ClothingItem> _allItems = [];
  
  // _filteredItems is what the UI actually displays
  List<ClothingItem> _filteredItems = [];
  
  bool _isLoading = false;

  // Getter for the UI to consume
  List<ClothingItem> get items => _filteredItems;
  bool get isLoading => _isLoading;

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('clothing_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _allItems = (response as List)
          .map((item) => ClothingItem.fromJson(item))
          .toList();
      
      // Initially, filtered list is the same as all items
      _filteredItems = List.from(_allItems);
      
    } catch (e) {
      debugPrint('Error fetching items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATED: Filtering logic now uses SubCategory
  void filterItems(String query, String filterCategory) {
    _filteredItems = _allItems.where((item) {
      // 1. Check Search Query (matches subCategory, article type or base color)
      final matchesQuery = query.isEmpty ||
          item.subCategory.toLowerCase().contains(query.toLowerCase()) ||
          item.articleType.toLowerCase().contains(query.toLowerCase()) ||
          item.baseColour.toLowerCase().contains(query.toLowerCase());

      // 2. Check Category Filter (Based on SubCategory now)
      bool matchesFilter = true;
      if (filterCategory != 'All Items') {
        // Compare with subCategory (case-insensitive for safety)
        matchesFilter = item.subCategory.toLowerCase() == filterCategory.toLowerCase();
      }

      return matchesQuery && matchesFilter;
    }).toList();

    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    try {
      await _supabase.from('clothing_items').delete().eq('id', id);
      _allItems.removeWhere((item) => item.id == id);
      _filteredItems.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
  }
}