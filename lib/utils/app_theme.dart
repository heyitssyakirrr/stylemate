import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppConstants.background,
    primaryColor: AppConstants.primaryAccent,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppConstants.background,
      iconTheme: IconThemeData(color: Colors.black87),
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
