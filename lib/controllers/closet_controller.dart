// lib/controllers/closet_controller.dart (Corrected)

import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class ClosetController {
  // Mock list of all items (kept private)
  final List<ClothingItem> _mockItems = [
    // Use the logo path as a mock local/asset image path
    ClothingItem(id: '1', imageUrl: 'assets/logo.png', category: 'T-Shirt', color: 'White', season: 'Summer', wearCount: 15, brand: 'Aura Fit'),
    ClothingItem(id: '2', imageUrl: 'assets/logo.png', category: 'Jeans', color: 'Blue', season: 'All-Season', wearCount: 8, brand: 'Levi\'s'),
    ClothingItem(id: '3', imageUrl: 'assets/logo.png', category: 'Jacket', color: 'Black', season: 'Winter', wearCount: 3, brand: 'The North Face'),
    ClothingItem(id: '4', imageUrl: 'assets/logo.png', category: 'Dress', color: 'Red', season: 'Summer', wearCount: 20, brand: 'Zara'),
  ];
  
  // FIX APPLIED: Public getter for other controllers to access the raw item list
  List<ClothingItem> get allItems => _mockItems; 
  
  // State for the Item Details Page
  final ValueNotifier<bool> isEditing = ValueNotifier(false);

  // ValueNotifier to hold the currently filtered and displayed list of items (used by ClosetPage)
  final ValueNotifier<List<ClothingItem>> _itemsNotifier;
  ValueNotifier<List<ClothingItem>> get itemsNotifier => _itemsNotifier;

  ClosetController() : _itemsNotifier = ValueNotifier(List.from(_mockItems));

  // ... (rest of filterItems, markAsWorn, saveItemEdits methods)

  /// Simulates marking the item as worn.
  Future<void> markAsWorn(ClothingItem item) async {
    item.wearCount += 1;
    item.lastWornDate = DateTime.now();
    _itemsNotifier.notifyListeners(); 
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Simulates saving edits to an item.
  Future<void> saveItemEdits(ClothingItem item) async {
    isEditing.value = false;
    _itemsNotifier.notifyListeners(); 
    await Future.delayed(const Duration(milliseconds: 700));
  }

  /// Simulates deleting an item.
  Future<void> deleteItem(String itemId) async {
    _mockItems.removeWhere((item) => item.id == itemId);
    _itemsNotifier.value = List.from(_mockItems); 
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void filterItems(String query, String filter) {
    List<ClothingItem> results = List.from(_mockItems);

    if (filter != 'All Items') {
      results = results.where((item) => item.category == filter).toList();
    }

    if (query.isNotEmpty) {
      results = results
          .where((item) =>
              item.category.toLowerCase().contains(query.toLowerCase()) ||
              item.brand!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _itemsNotifier.value = results;
  }
  
  void dispose() {
    isEditing.dispose();
    _itemsNotifier.dispose();
  }
}