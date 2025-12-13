// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  // ⚠️ ACTION REQUIRED: REPLACE WITH YOUR KEY ⚠️
  static const String apiKey = '84cf3cbda60fcd39c4f89081e15d3867';
  
  static const String iconBaseUrl = 'https://openweathermap.org/img/wn/';

  // Default fallback (London) if no coordinates are passed
  static const double defaultLat = 51.5074;
  static const double defaultLon = 0.1278;

  Future<Weather> fetchCurrentWeather({
    double? lat,
    double? lon,
  }) async {
    // Use passed coordinates, or fallback to default
    final latitude = lat ?? defaultLat;
    final longitude = lon ?? defaultLon;

    final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Weather.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching weather: $e');
    }
  }
  
  String getWeatherIconUrl(String iconCode) {
    return '$iconBaseUrl$iconCode@2x.png';
  }
}