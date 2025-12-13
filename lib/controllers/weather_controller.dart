// lib/controllers/weather_controller.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Import Geolocator
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherController {
  final WeatherService _service = WeatherService();

  final ValueNotifier<Weather?> weather = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  WeatherController() {
    fetchWeather(); 
  }

  Future<void> fetchWeather() async {
    isLoading.value = true;
    errorMessage.value = null;
    
    try {
      // ✅ STEP 1: Check Location Services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // ✅ STEP 2: Check & Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // ✅ STEP 3: Get Current Position (Low accuracy is faster and sufficient for weather)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low 
      );

      // ✅ STEP 4: Fetch Weather using live coordinates
      final result = await _service.fetchCurrentWeather(
        lat: position.latitude,
        lon: position.longitude,
      );
      
      weather.value = result;

    } catch (e) {
      debugPrint("Weather Error: $e");
      errorMessage.value = e.toString().contains("401") 
          ? "API Key is invalid. Check weather_service.dart." 
          : "Could not fetch local weather. Ensure GPS is on.";
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