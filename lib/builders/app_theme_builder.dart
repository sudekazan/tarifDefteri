import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppThemeBuilder {
  static ThemeData buildLightTheme(AppTheme currentTheme) {
    final swatch = appThemeColors[currentTheme]!;
    return ThemeData(
      primarySwatch: swatch,
      primaryColor: swatch, // ElevatedButton gibi bileşenler için
      scaffoldBackgroundColor: Colors.grey[50], // Beyaza yakın, gradient için nötr
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: swatch,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: swatch,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
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
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
