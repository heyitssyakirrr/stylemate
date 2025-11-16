// lib/models/analytics_data.dart

// Represents a data point for a chart (e.g., item wear frequency)
import 'package:flutter/widgets.dart';

class ChartDataPoint {
  final String label;
  final double value;
  final Color color;

  ChartDataPoint(this.label, this.value, {required this.color});
}

// Represents sustainability metrics
class SustainabilityMetric {
  final String title;
  final String value;
  final String insight;
  final IconData icon;
  final Color color;

  SustainabilityMetric({
    required this.title,
    required this.value,
    required this.insight,
    required this.icon,
    required this.color,
  });
}