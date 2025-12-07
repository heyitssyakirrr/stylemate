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

  // Missing method fixed here
  void filterItems(String query, String filterCategory) {
    _filteredItems = _allItems.where((item) {
      // 1. Check Search Query (matches article type or base color)
      final matchesQuery = query.isEmpty ||
          item.articleType.toLowerCase().contains(query.toLowerCase()) ||
          item.baseColour.toLowerCase().contains(query.toLowerCase());

      // 2. Check Category Filter
      // We map the UI filter chips to the database fields (articleType or subCategory)
      bool matchesFilter = true;
      if (filterCategory != 'All Items') {
        if (filterCategory == 'Footwear' || filterCategory == 'Accessories') {
          // Check subCategory for broader groups
          matchesFilter = item.subCategory == filterCategory; 
        } else {
          // Check articleType for specific items (T-Shirt, Jeans, etc.)
          matchesFilter = item.articleType == filterCategory;
        }
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