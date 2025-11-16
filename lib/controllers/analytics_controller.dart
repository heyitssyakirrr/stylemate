// lib/controllers/analytics_controller.dart

import 'package:flutter/material.dart';
import '../models/analytics_data.dart';
import '../utils/constants.dart';

class AnalyticsController {
  
  // --- MOCK DATA ---
  final List<ChartDataPoint> _wearFrequencyData = [
    ChartDataPoint('Top', 25, color: AppConstants.primaryAccent),
    ChartDataPoint('Bottom', 18, color: AppConstants.primaryAccent.withOpacity(0.7)),
    ChartDataPoint('Outerwear', 5, color: AppConstants.primaryAccent.withOpacity(0.5)),
    ChartDataPoint('Footwear', 12, color: AppConstants.primaryAccent.withOpacity(0.3)),
    ChartDataPoint('Accessory', 10, color: AppConstants.primaryAccent.withOpacity(0.1)),
  ];

  final List<ChartDataPoint> _mostWornItems = [
    ChartDataPoint('White Tee', 15, color: Colors.blueGrey.shade400),
    ChartDataPoint('Blue Jeans', 10, color: Colors.blueGrey.shade300),
    ChartDataPoint('Black Sneakers', 7, color: Colors.blueGrey.shade200),
  ];
  
  // --- CALCULATIONS/METRICS ---
  
  final List<SustainabilityMetric> metrics = [
    SustainabilityMetric(
      title: 'Wardrobe Reuse Rate',
      value: '80%',
      insight: 'You reused 80% of your items this month, far exceeding the 50% sustainable goal.',
      icon: Icons.recycling_rounded,
      color: Colors.green.shade600,
    ),
    SustainabilityMetric(
      title: 'Underused Items',
      value: '2 items',
      insight: 'You have 2 items worn less than twice. Consider styling them this week!',
      icon: Icons.warning_amber_rounded,
      color: Colors.orange.shade600,
    ),
  ];

  // --- Public Getters ---
  
  List<ChartDataPoint> get wearFrequencyData => _wearFrequencyData;
  List<ChartDataPoint> get mostWornItems => _mostWornItems;
  
  // Placeholder for any async fetching needed later
  Future<void> refreshAnalytics() async {
    // In a real app, this would fetch updated data from the DB
    await Future.delayed(const Duration(milliseconds: 500));
  }
}