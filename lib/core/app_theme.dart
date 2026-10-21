import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color coral = Color(0xFFFF536A);
  static const Color blue = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B);

  static const Color bgLight = Color(0xFFF8F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textSubLight = Color(0xFF64748B);

  static const Color bgDark = Color(0xFF0B0E17);
  static const Color surfaceDark = Color(0xFF151A28);
  static const Color borderDark = Color(0xFF222938);
  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textSubDark = Color(0xFF94A3B8);

  static const Color primaryGreen = primary;
  static const Color accentBlue = blue;
  static const Color cardBackground = surfaceLight;
  static const Color cardBackgroundDark = surfaceDark;
  static const Color backgroundLight = bgLight;
  static const Color backgroundDark = bgDark;
}

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.coral,
      surface: AppColors.surfaceLight,
      error: Color(0xFFEF4444),
    ),
    cardColor: AppColors.surfaceLight,
    dividerColor: AppColors.borderLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppColors.textMainLight,
      ),
      iconTheme: IconThemeData(color: AppColors.textMainLight),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      labelStyle: const TextStyle(color: AppColors.textSubLight, fontSize: 14),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.coral,
      surface: AppColors.surfaceDark,
      error: Color(0xFFEF4444),
    ),
    cardColor: AppColors.surfaceDark,
    dividerColor: AppColors.borderDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppColors.textMainDark,
      ),
      iconTheme: IconThemeData(color: AppColors.textMainDark),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderDark, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderDark, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      labelStyle: const TextStyle(color: AppColors.textSubDark, fontSize: 14),
    ),
  );
}