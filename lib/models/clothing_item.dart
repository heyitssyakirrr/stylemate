class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  
  // Tags
  final String subCategory;
  final String articleType;
  final String baseColour;
  final String usage;
  final String gender;
  final String season;

  // Analytics
  final int wearCount;
  final DateTime? lastWornDate;

  // AI Feature (Hidden from UI usually)
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

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      subCategory: json['sub_category'] ?? '',
      articleType: json['article_type'] ?? '',
      baseColour: json['base_colour'] ?? '',
      usage: json['usage'] ?? '',
      gender: json['gender'] ?? '',
      season: json['season'] ?? '',
      wearCount: json['wear_count'] ?? 0,
      lastWornDate: json['last_worn_date'] != null 
          ? DateTime.parse(json['last_worn_date']) : null,
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
      'season': season,
      'wear_count': wearCount,
      'last_worn_date': lastWornDate?.toIso8601String(),
      'embedding': embedding,
    };
  }
}