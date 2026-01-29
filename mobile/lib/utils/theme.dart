import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData magicalTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6A1B9A), // Deep Purple
      onPrimary: Colors.white,
      secondary: Color(0xFFFFD700), // Gold
      onSecondary: Colors.black,
      surface: Color(0xFF121212), // Very Dark Grey
      onSurface: Color(0xFFE0E0E0),
      error: Color(0xFFCF6679),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E003E), // Darker Purple
      foregroundColor: Color(0xFFFFD700), // Gold Text
      centerTitle: true,
      elevation: 4,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFD700), // Gold
        letterSpacing: 1.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE0E0E0),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFFFD700),
            width: 1,
          ), // Gold border
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
    ),
  );
}
