import 'clothing_item.dart';

class Outfit {
  final List<ClothingItem> items;
  final int harmonyScore;
  final String suggestionLogic;
  final List<Outfit> alternatives;

  Outfit({
    required this.items,
    required this.harmonyScore,
    required this.suggestionLogic,
    this.alternatives = const [],
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      items: (json['items'] as List).map((i) => ClothingItem.fromJson(i)).toList(),
      harmonyScore: (json['harmonyScore'] as num).toInt(),
      suggestionLogic: json['suggestionLogic'] ?? "AI Recommendation",
      alternatives: json['alternatives'] != null
          ? (json['alternatives'] as List).map((a) => Outfit.fromJson(a)).toList()
          : [],
    );
  }
}