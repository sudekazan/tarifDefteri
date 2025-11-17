import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppThemeBuilder {
  static ThemeData buildLightTheme(AppTheme currentTheme) {
    return ThemeData(
      primarySwatch: appThemeColors[currentTheme]!,
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: appThemeColors[currentTheme],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appThemeColors[currentTheme],
      ),
    );
  }

  static ThemeData buildDarkTheme(AppTheme currentTheme) {
    final swatch = appThemeColors[currentTheme]!;
    final darkPrimary = swatch.shade700;
    return ThemeData.dark().copyWith(
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: const Color(0xFF2C2C2C),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
