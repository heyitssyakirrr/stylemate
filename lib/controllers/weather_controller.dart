// lib/controllers/weather_controller.dart

import 'package:flutter/foundation.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherController {
  final WeatherService _service = WeatherService();

  final ValueNotifier<Weather?> weather = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  WeatherController() {
    fetchWeather(); // Fetch data immediately on creation
  }

  Future<void> fetchWeather() async {
    isLoading.value = true;
    errorMessage.value = null;
    
    try {
      // You can add logic here to get user's location via geolocation plugin
      final result = await _service.fetchCurrentWeather();
      weather.value = result;
    } catch (e) {
      errorMessage.value = e.toString().contains("401") 
          ? "API Key is invalid. Check weather_service.dart." 
          : "Could not fetch weather: Please check your network.";
      weather.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    weather.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}