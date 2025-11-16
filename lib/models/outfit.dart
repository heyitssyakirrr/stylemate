// lib/models/outfit.dart

import 'clothing_item.dart';

// Represents a complete recommended outfit
class Outfit {
  final String title;
  final String description;
  final String occasion;
  final List<ClothingItem> items;
  final String suggestionLogic; // For the "Why this outfit?" UX

  Outfit({
    required this.title,
    required this.description,
    required this.items,
    required this.occasion,
    required this.suggestionLogic,
  });

  // Helper method to get all individual items
  List<ClothingItem> get allItems => items;
}