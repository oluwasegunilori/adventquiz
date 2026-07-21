import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const ink = Color(0xFF2C2420);
  static const parchment = Color(0xFFF3E7D3);
  static const sand = Color(0xFFE8D5B5);
  static const forest = Color(0xFF2F5D50);
  static const forestDeep = Color(0xFF1F3F38);
  static const clay = Color(0xFFC45C26);
  static const claySoft = Color(0xFFE28A54);
  static const mist = Color(0xFF6E7F78);
  static const correct = Color(0xFF2E7D4F);
  static const wrong = Color(0xFFB33A3A);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        secondary: AppColors.clay,
        surface: AppColors.parchment,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.parchment,
    );

    final display = GoogleFonts.literataTextTheme(base.textTheme);
    final body = GoogleFonts.sourceSans3TextTheme(base.textTheme);

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: display.displaySmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(220, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestDeep,
          minimumSize: const Size(220, 56),
          side: const BorderSide(color: AppColors.forest, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.72),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.mist.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.mist.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forest, width: 2),
        ),
      ),
    );
  }
}
