class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  
  // New Classification Fields
  final String subCategory;
  final String articleType;
  final String baseColour;
  final String usage;
  final String gender;
  final String season;

  // Analytics
  final int wearCount;
  final DateTime? lastWornDate;

  // AI Embedding
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
    required this.season,
    this.wearCount = 0,
    this.lastWornDate,
    required this.embedding,
  });

  // UI Helper: Map old 'category' calls to 'articleType' to keep UI working
  String get category => articleType;

  // UI Helper: Map 'color' calls to 'baseColour'
  String get color => baseColour;

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    List<double> parsedEmbedding = [];
    if (json['embedding'] != null) {
      if (json['embedding'] is List) {
        parsedEmbedding = (json['embedding'] as List).map((e) => (e as num).toDouble()).toList();
      } else if (json['embedding'] is String) {
         // Handle string format from Postgres vector if needed
         // Simplified for standard JSON response
         parsedEmbedding = []; 
      }
    }

    return ClothingItem(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      subCategory: json['sub_category'] ?? 'Unknown',
      articleType: json['article_type'] ?? 'Unknown',
      baseColour: json['base_colour'] ?? 'Unknown',
      usage: json['usage'] ?? 'Unknown',
      gender: json['gender'] ?? 'Unknown',
      season: json['season'] ?? 'Unknown',
      wearCount: json['wear_count'] ?? 0,
      lastWornDate: json['last_worn_date'] != null 
          ? DateTime.parse(json['last_worn_date']) 
          : null,
      embedding: parsedEmbedding,
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
      'season': season,
      'wear_count': wearCount,
      'last_worn_date': lastWornDate?.toIso8601String(),
      'embedding': embedding,
    };
  }

  // Helper for UI cloning
  Map<String, dynamic> toMap() => toJson();
  factory ClothingItem.fromMap(Map<String, dynamic> map) => ClothingItem.fromJson(map);
}