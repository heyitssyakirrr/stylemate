// lib/models/clothing_item.dart

import 'package:flutter/foundation.dart';

class ClothingItem {
  final String? id;
  final String? userId; // For database linkage
  String imageUrl; // <--- MODIFIED: Removed 'final'
  
  // AI-Tagged fields
  String category;      // e.g., 'T-Shirt', 'Jeans'
  String color;         // e.g., 'Blue', 'Red'
  String pattern;       // e.g., 'Solid', 'Striped', 'Floral'
  String season;        // e.g., 'Summer', 'Winter'
  String usage;         // e.g., 'Casual', 'Formal'
  
  // User/App controlled fields
  int wearCount;
  DateTime? lastWornDate;
  String? brand;
  String? customNote;

  ClothingItem({
    this.id,
    this.userId,
    required this.imageUrl,
    this.category = 'Untagged',
    this.color = 'Untagged',
    this.pattern = 'Untagged',
    this.season = 'Untagged',
    this.usage = 'Untagged',
    this.wearCount = 0,
    this.lastWornDate,
    this.brand,
    this.customNote,
  });
  
  // Helper to get all primary tags as a map for UI display
  Map<String, String> get primaryTags => {
    "Category": category,
    "Color": color,
    "Pattern": pattern,
    "Season": season,
    "Usage": usage,
  };

  // Factory method to create an instance from a database map (e.g., from Firestore)
  factory ClothingItem.fromMap(Map<String, dynamic> data) {
    return ClothingItem(
      id: data['id'],
      userId: data['user_id'],
      imageUrl: data['image_url'],
      category: data['category'] ?? 'Untagged',
      color: data['color'] ?? 'Untagged',
      pattern: data['pattern'] ?? 'Untagged',
      season: data['season'] ?? 'Untagged',
      usage: data['usage'] ?? 'Untagged',
      wearCount: data['wear_count'] ?? 0,
      lastWornDate: data['last_worn_date'] != null
          ? DateTime.parse(data['last_worn_date'])
          : null,
      brand: data['brand'],
      customNote: data['custom_note'],
    );
  }

  // Method to convert the instance to a map (for saving to the database)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'category': category,
      'color': color,
      'pattern': pattern,
      'season': season,
      'usage': usage,
      'wear_count': wearCount,
      'last_worn_date': lastWornDate?.toIso8601String(),
      'brand': brand,
      'custom_note': customNote,
    };
  }
}