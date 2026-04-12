import 'package:flutter/material.dart';
 
class AppTheme {
  // Brand colors — fresh market greens
  static const Color primary = Color(0xFF2D6A4F);       // deep forest green
  static const Color primaryLight = Color(0xFF52B788);  // fresh leaf green
  static const Color accent = Color(0xFFF4A261);        // warm orange (price tags)
  static const Color background = Color(0xFFF8F9F4);    // off-white, like paper bags
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B1B1B);
  static const Color textMid = Color(0xFF555555);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFD62828);
  static const Color success = Color(0xFF40916C);
  static const Color divider = Color(0xFFE8EDE6);
 
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Nunito', // add to pubspec if desired, or falls back to default
 
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
 
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
 
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F4EF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMid, fontSize: 14),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
        errorStyle: const TextStyle(color: error, fontSize: 12),
      ),
 
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
 
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
 
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}