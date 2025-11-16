// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  // ⚠️ ACTION REQUIRED: REPLACE WITH YOUR KEY ⚠️
  static const String apiKey = '84cf3cbda60fcd39c4f89081e15d3867';
  
  // Base URL for the weather icon image
  static const String iconBaseUrl = 'https://openweathermap.org/img/wn/';

  // Default location (e.g., London coordinates)
  // You might want to get the user's current location in a later step
  static const double defaultLat = 51.5074;
  static const double defaultLon = 0.1278;

  Future<Weather> fetchCurrentWeather({
    double lat = defaultLat,
    double lon = defaultLon,
  }) async {
    final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Weather.fromJson(data);
      } else {
        // Handle API errors (e.g., invalid key, rate limit)
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors
      throw Exception('Network error while fetching weather: $e');
    }
  }
  
  // Helper to construct the icon URL
  String getWeatherIconUrl(String iconCode) {
    return '$iconBaseUrl$iconCode@2x.png';
  }
}