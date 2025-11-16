// lib/controllers/closet_controller.dart

import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class ClosetController {
  // Mock data stored privately for manipulation
  final List<ClothingItem> _mockItems = [
    ClothingItem(id: '1', imageUrl: 'assets/logo.png', category: 'T-Shirt', color: 'White', season: 'Summer', wearCount: 15, brand: 'Aura Fit'),
    ClothingItem(id: '2', imageUrl: 'assets/logo.png', category: 'Jeans', color: 'Blue', season: 'All-Season', wearCount: 8, brand: 'Levi\'s'),
    ClothingItem(id: '3', imageUrl: 'assets/logo.png', category: 'Jacket', color: 'Black', season: 'Winter', wearCount: 3, brand: 'The North Face'),
    ClothingItem(id: '4', imageUrl: 'assets/logo.png', category: 'Dress', color: 'Red', season: 'Summer', wearCount: 20, brand: 'Zara'),
  ];
  
  // ValueNotifier to hold the currently filtered and displayed list of items
  final ValueNotifier<List<ClothingItem>> _itemsNotifier;
  ValueNotifier<List<ClothingItem>> get itemsNotifier => _itemsNotifier;

  final ValueNotifier<bool> isEditing = ValueNotifier(false);

  ClosetController() : _itemsNotifier = ValueNotifier([]) {
    // Initialize the notifier with the full mock data
    _itemsNotifier.value = List.from(_mockItems);
  }

  /// Filters and searches the closet based on user input.
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
    _itemsNotifier.value = results; // Update notifier to refresh UI
  }

  /// Simulates marking the item as worn.
  Future<void> markAsWorn(ClothingItem item) async {
    item.wearCount += 1;
    item.lastWornDate = DateTime.now();
    _itemsNotifier.notifyListeners(); // Notify all listeners of the change
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
    // Reassigning the list forces the ValueNotifier to trigger a full update
    _itemsNotifier.value = List.from(_mockItems); 
    await Future.delayed(const Duration(milliseconds: 700));
  }
  
  void dispose() {
    isEditing.dispose();
    _itemsNotifier.dispose(); // CRITICAL: Must dispose the notifier
  }
}