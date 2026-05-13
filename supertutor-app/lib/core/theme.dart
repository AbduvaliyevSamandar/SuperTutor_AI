import 'package:flutter/material.dart';

/// Duolingo-inspired palette.
class AppColors {
  static const primary = Color(0xFF58CC02);
  static const primaryDark = Color(0xFF58A700);
  static const secondary = Color(0xFF1CB0F6);
  static const secondaryDark = Color(0xFF1899D6);
  static const fire = Color(0xFFFF9600);
  static const fireDark = Color(0xFFE08600);
  static const heart = Color(0xFFFF4B4B);
  static const heartDark = Color(0xFFE03A3A);
  static const gold = Color(0xFFFFC800);
  static const goldDark = Color(0xFFE6B400);

  static const ink = Color(0xFF3C3C3C);
  static const inkLight = Color(0xFF777777);
  static const inkLighter = Color(0xFFAFAFAF);

  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F7F7);
  static const border = Color(0xFFE5E5E5);
  static const borderDark = Color(0xFFD0D0D0);
}

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    error: AppColors.heart,
    onError: Colors.white,
    surface: AppColors.bg,
    onSurface: AppColors.ink,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.surface,
    surfaceContainerHighest: AppColors.surface,
    outline: AppColors.border,
    outlineVariant: AppColors.borderDark,
  );

  const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inkLight),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: AppColors.bg,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.inkLighter, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
