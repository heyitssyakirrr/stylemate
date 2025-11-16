// lib/controllers/closet_controller.dart

import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class ClosetController {
  
  // Mock list, made static to ensure correct initialization across the app
  static final List<ClothingItem> _MOCK_ITEMS = [
    ClothingItem(id: '1', imageUrl: 'assets/logo.png', category: 'T-Shirt', color: 'White', season: 'Summer', wearCount: 15, brand: 'Aura Fit'),
    ClothingItem(id: '2', imageUrl: 'assets/logo.png', category: 'Jeans', color: 'Blue', season: 'All-Season', wearCount: 8, brand: 'Levi\'s'),
    ClothingItem(id: '3', imageUrl: 'assets/logo.png', category: 'Jacket', color: 'Black', season: 'Winter', wearCount: 3, brand: 'The North Face'),
    ClothingItem(id: '4', imageUrl: 'assets/logo.png', category: 'Dress', color: 'Red', season: 'Summer', wearCount: 20, brand: 'Zara'),
  ];
  
  List<ClothingItem> get allItems => _MOCK_ITEMS; 
  
  final ValueNotifier<bool> isEditing = ValueNotifier(false);

  final ValueNotifier<List<ClothingItem>> _itemsNotifier;
  ValueNotifier<List<ClothingItem>> get itemsNotifier => _itemsNotifier;

  ClosetController() : _itemsNotifier = ValueNotifier(List.from(_MOCK_ITEMS));

  // --- Core Methods ---

  Future<void> markAsWorn(ClothingItem item) async {
    item.wearCount += 1;
    item.lastWornDate = DateTime.now();
    
    // FIX APPLIED: Reassigns the value using a new List copy to force the ValueNotifier to trigger a redraw.
    _itemsNotifier.value = _itemsNotifier.value.toList(); 
    
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> saveItemEdits(ClothingItem item) async {
    isEditing.value = false;
    
    // FIX APPLIED: Reassigns the value using a new List copy to force the ValueNotifier to trigger a redraw.
    _itemsNotifier.value = _itemsNotifier.value.toList(); 
    
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> deleteItem(String itemId) async {
    _MOCK_ITEMS.removeWhere((item) => item.id == itemId); 
    
    // After deletion (a destructive change to the source list), we regenerate the list
    _itemsNotifier.value = List.from(_MOCK_ITEMS); 
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void filterItems(String query, String filter) {
    List<ClothingItem> results = List.from(_MOCK_ITEMS);

    if (filter != 'All Items') {
      results = results.where((item) => item.category == filter).toList();
    }

    if (query.isNotEmpty) {
      results = results
          .where((item) =>
              item.category.toLowerCase().contains(query.toLowerCase()) ||
              (item.brand?.toLowerCase() ?? '').contains(query.toLowerCase()))
          .toList();
    }
    _itemsNotifier.value = results;
  }
  
  void dispose() {
    isEditing.dispose();
    _itemsNotifier.dispose();
  }
}