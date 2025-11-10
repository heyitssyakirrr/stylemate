// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  static const double kRadius = 20.0;
  static const double kPadding = 16.0;
  static const Color background = Color(0xFFF8F5F2); // soft beige
  static const Color primaryAccent = Color(0xFF7D5A50); // warm muted accent

  // New: Define a consistent BoxShadow for cards
  static const BoxShadow cardShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 16,
    offset: Offset(0, 6),
  );
}