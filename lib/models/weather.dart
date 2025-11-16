// lib/models/weather.dart

class Weather {
  final double temperature;
  final String condition;
  final String description;
  final String iconCode; // Used to fetch the correct image icon

  Weather({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.iconCode,
  });

  // Factory method to parse the JSON response
  factory Weather.fromJson(Map<String, dynamic> json) {
    // OpenWeatherMap JSON structure: main.temp, weather[0].main, weather[0].description, weather[0].icon
    return Weather(
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
    );
  }
}