// lib/models/weather.dart

class Weather {
  final double temperature;
  final String condition;
  final String description;
  final String iconCode;
  final String cityName; // ✅ Added to store location name (e.g. "Kuala Lumpur")

  Weather({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.cityName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
      cityName: json['name'] as String, // ✅ Map the city name from API
    );
  }
}