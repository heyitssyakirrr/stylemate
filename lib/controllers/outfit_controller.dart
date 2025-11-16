// lib/controllers/outfit_controller.dart (Corrected)

import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../controllers/closet_controller.dart'; 

class OutfitController {
  // State for the generated outfit
  final ValueNotifier<Outfit?> currentOutfit = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Controllers to access necessary data/logic
  final ClosetController _closetController = ClosetController();

  // --- MOCK DATA ---
  final Map<String, List<String>> options = {
    'Usage': ['Casual', 'Formal', 'Sporty', 'Evening'],
    'Occasion': ['Work', 'Date Night', 'Outdoor', 'Everyday'],
    'ColorPreference': ['Neutrals', 'Brights', 'Darks', 'Warm Tones'],
    'StylePreference': ['Minimalist', 'Bohemian', 'Classic'],
  };
  
  // MOCK function to simulate outfit generation
  Future<void> generateOutfit({required Map<String, dynamic> criteria}) async {
    isLoading.value = true;
    
    // Simulate AI/DB matching delay
    await Future.delayed(const Duration(milliseconds: 1500)); 
    
    // FIX APPLIED: Use the new public getter 'allItems'
    final allItems = _closetController.allItems;
    
    List<ClothingItem> recommendedItems = [];
    if (allItems.length >= 3) {
      // Mock logic: pick 3 items (Top, Bottom, Outer)
      recommendedItems.add(allItems.firstWhere((i) => i.category == 'T-Shirt', orElse: () => allItems[0]));
      recommendedItems.add(allItems.firstWhere((i) => i.category == 'Jeans', orElse: () => allItems[1]));
      recommendedItems.add(allItems.firstWhere((i) => i.category == 'Jacket', orElse: () => allItems[2]));
    } else {
        // Fallback for minimal closet data
        recommendedItems.addAll(allItems);
    }
    
    // Determine the outfit title and logic based on criteria
    String selectedStyle = criteria['StylePreference'] ?? 'Classic';
    String selectedColor = criteria['ColorPreference'] ?? 'Neutrals';
    String selectedOccasion = criteria['Occasion'] ?? 'Work';

    currentOutfit.value = Outfit(
      title: 'The $selectedStyle Look',
      description: 'Perfect for your $selectedOccasion meeting. Simple lines and comfortable fit.',
      items: recommendedItems,
      occasion: selectedOccasion,
      suggestionLogic: 'Items matched based on low wear count and the selected $selectedColor color scheme.',
    );

    isLoading.value = false;
  }
  
  // Marks all items in the generated outfit as worn
  Future<void> markOutfitAsWorn(Outfit outfit) async {
    for (var item in outfit.items) {
      _closetController.markAsWorn(item); // Uses mock logic from ClosetController
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void dispose() {
    currentOutfit.dispose();
    isLoading.dispose();
  }
}