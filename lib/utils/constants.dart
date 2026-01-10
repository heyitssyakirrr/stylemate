// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  static const double kRadius = 24.0; // Increased radius for a softer, modern look
  static const double kPadding = 20.0; // Slightly more breathing room
  
  // ✅ NEW THEME: Midnight Blue & Cool White
  static const Color background = Color(0xFFF4F7FA); // Cool, professional light grey-blue
  static const Color primaryAccent = Color(0xFF1E3A8A); // Deep Midnight Blue
  static const Color secondaryAccent = Color(0xFF3B82F6); // Lighter blue for gradients/icons
  
  // Text Colors
  static const Color textDark = Color(0xFF1E293B); // Slate 900
  static const Color textGrey = Color(0xFF64748B); // Slate 500

  // Modern Soft Shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A1E293B), // Navy-tinted shadow
    blurRadius: 20,
    offset: Offset(0, 8),
    spreadRadius: -4,
  );
  
  // Sharper shadow for active elements
  static const BoxShadow activeShadow = BoxShadow(
    color: Color(0x331E3A8A), 
    blurRadius: 24,
    offset: Offset(0, 12),
    spreadRadius: -2,
  );
}