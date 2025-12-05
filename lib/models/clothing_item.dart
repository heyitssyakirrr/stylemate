import 'dart:convert';

class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String subCategory;
  final String articleType;
  final String baseColour;
  final String usage;
  final String gender;
  final DateTime createdAt;
  // New field for embedding vector
  final List<double> embedding;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.subCategory,
    required this.articleType,
    required this.baseColour,
    required this.usage,
    required this.gender,
    required this.createdAt,
    required this.embedding,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'].toString(), // Handle int or string ID
      userId: json['user_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      subCategory: json['sub_category'] ?? '',
      articleType: json['article_type'] ?? '',
      baseColour: json['base_colour'] ?? '',
      usage: json['usage'] ?? '',
      gender: json['gender'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      // Handle embedding conversion safely
      embedding: json['embedding'] != null 
          ? (json['embedding'] as List).map((e) => (e as num).toDouble()).toList() 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'sub_category': subCategory,
      'article_type': articleType,
      'base_colour': baseColour,
      'usage': usage,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      // Store embedding as is (Supabase handles JSON/vector arrays)
      'embedding': embedding,
    };
  }
}