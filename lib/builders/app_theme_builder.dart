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
    return ThemeData.dark().copyWith(
      primaryColor: appThemeColors[currentTheme],
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: const Color(0xFF2C2C2C),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: appThemeColors[currentTheme],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appThemeColors[currentTheme],
        foregroundColor: Colors.white,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
