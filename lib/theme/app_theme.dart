import 'package:flutter/material.dart';

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
  /// Uses bundled platform fonts so web never blocks on Google Fonts CDN.
  static ThemeData light() {
    const display = TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: ['Times New Roman', 'serif'],
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
    );
    const body = TextStyle(
      fontFamily: 'Helvetica Neue',
      fontFamilyFallback: ['Arial', 'sans-serif'],
      color: AppColors.ink,
    );

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
      fontFamily: 'Helvetica Neue',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: display.copyWith(fontSize: 57),
        displayMedium: display.copyWith(fontSize: 45),
        displaySmall: display.copyWith(fontSize: 36),
        headlineLarge: display.copyWith(fontSize: 32),
        headlineMedium: display.copyWith(fontSize: 28),
        headlineSmall: display.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: display.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: body.copyWith(fontSize: 16),
        bodyMedium: body.copyWith(fontSize: 14),
        bodySmall: body.copyWith(fontSize: 12, color: AppColors.mist),
        labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: display.copyWith(fontSize: 20),
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
