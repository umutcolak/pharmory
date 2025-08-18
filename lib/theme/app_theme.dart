import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF2E7D9A);
  static const Color secondaryColor = Color(0xFF6BA6CD);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE57373);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color surfaceColor = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;

  static ThemeData lightTheme(double fontSize) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      
      // Typography
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontSize * 2.0,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSize * 1.5,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSize * 1.1,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSize,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.w500,
          color: textOnPrimary,
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: fontSize * 1.3,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),

      // Card theme
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.all(8),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(
            fontSize: fontSize * 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: textSecondary,
        ),
      ),
    );
  }

  static ThemeData darkTheme(double fontSize) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontSize * 2.0,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSize * 1.5,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSize * 1.1,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSize,
        ),
        labelLarge: TextStyle(
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.w500,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(
            fontSize: fontSize * 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          fontSize: fontSize,
        ),
      ),
    );
  }
}
