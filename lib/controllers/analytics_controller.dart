// lib/controllers/analytics_controller.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_data.dart';
import '../models/clothing_item.dart'; // Needed to parse data
import '../utils/constants.dart';

class AnalyticsController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool isLoading = true;
  
  // Real Data Holders
  List<ChartDataPoint> _wearFrequencyData = [];
  List<ChartDataPoint> _mostWornItems = [];
  List<SustainabilityMetric> _metrics = [];

  // Getters
  List<ChartDataPoint> get wearFrequencyData => _wearFrequencyData;
  List<ChartDataPoint> get mostWornItems => _mostWornItems;
  List<SustainabilityMetric> get metrics => _metrics;

  AnalyticsController() {
    refreshAnalytics();
  }

  Future<void> refreshAnalytics() async {
    isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Fetch All Items for User
      final response = await _supabase
          .from('clothing_items')
          .select()
          .eq('user_id', userId);

      final List<ClothingItem> items = (response as List)
          .map((data) => ClothingItem.fromJson(data))
          .toList();

      if (items.isEmpty) {
        _setEmptyState();
      } else {
        _calculateMetrics(items);
      }

    } catch (e) {
      debugPrint("Error calculating analytics: $e");
      _setEmptyState(); // Fallback to empty/safe state on error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _calculateMetrics(List<ClothingItem> items) {
    // --- A. Calculate Reuse Rate ---
    final totalItems = items.length;
    final usedItems = items.where((i) => i.wearCount > 0).length;
    final reuseRate = totalItems > 0 ? (usedItems / totalItems * 100).round() : 0;

    // --- B. Underused Items ---
    final underusedCount = items.where((i) => i.wearCount < 2).length;

    _metrics = [
      SustainabilityMetric(
        title: 'Wardrobe Reuse Rate',
        value: '$reuseRate%',
        insight: reuseRate > 50 
            ? 'Great job! You represent sustainable fashion.' 
            : 'Try to wear more of what you own.',
        icon: Icons.recycling_rounded,
        color: reuseRate > 50 ? Colors.green.shade600 : Colors.orange.shade600,
      ),
      SustainabilityMetric(
        title: 'Underused Items',
        value: '$underusedCount items',
        insight: 'Items worn less than twice. Consider styling them soon!',
        icon: Icons.warning_amber_rounded,
        color: underusedCount > 5 ? Colors.red.shade400 : Colors.blue.shade600,
      ),
    ];

    // --- C. Wear Frequency by Category (UPDATED) ---
    // 1. Initialize map with ALL 8 categories set to 0.0
    Map<String, double> categoryMap = {
      'Topwear': 0.0,
      'Bottomwear': 0.0,
      'Dress': 0.0,
      'Jumpsuit': 0.0,
      'Set': 0.0,
      'Outerwear': 0.0,
      'Footwear': 0.0,
      'Accessory': 0.0,
    };

    // 2. Populate with actual data
    for (var item in items) {
      // Handle case sensitivity or missing categories gracefully
      if (categoryMap.containsKey(item.subCategory)) {
        categoryMap[item.subCategory] = categoryMap[item.subCategory]! + item.wearCount;
      } else {
        // If an item has a weird category not in our list, add it anyway
        categoryMap.update(
          item.subCategory, 
          (value) => value + item.wearCount, 
          ifAbsent: () => item.wearCount.toDouble()
        );
      }
    }

    _wearFrequencyData = categoryMap.entries.map((e) {
      return ChartDataPoint(
        e.key, 
        e.value, 
        // Different opacity based on category index/length to make them distinct
        color: AppConstants.primaryAccent.withOpacity(0.4 + (e.key.length % 6) / 10),
      );
    }).toList();
    
    // Optional: Sort so categories with usage appear first, but keep 0s at the end
    _wearFrequencyData.sort((a, b) => b.value.compareTo(a.value));


    // --- D. Most Worn Items ---
    items.sort((a, b) => b.wearCount.compareTo(a.wearCount));
    
    // Take top 10 instead of 5 to allow scrolling to show more
    _mostWornItems = items.take(10).map((item) {
      return ChartDataPoint(
        "${item.baseColour} ${item.articleType}", 
        item.wearCount.toDouble(), 
        color: AppConstants.primaryAccent,
      );
    }).toList();
  }

  void _setEmptyState() {
    _metrics = [
      SustainabilityMetric(title: 'Data Needed', value: '-', insight: 'Upload items to see data.', icon: Icons.help_outline, color: Colors.grey),
      SustainabilityMetric(title: 'Data Needed', value: '-', insight: '-', icon: Icons.help_outline, color: Colors.grey),
    ];
    _wearFrequencyData = [];
    _mostWornItems = [];
  }
}