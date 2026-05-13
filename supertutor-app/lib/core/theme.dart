import 'package:flutter/material.dart';

/// Duolingo-inspired palette (light).
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

/// Dark-mode palette — same brand colors, dark surfaces.
class AppColorsDark {
  static const bg = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surface2 = Color(0xFF2A2A2A);
  static const border = Color(0xFF333333);
  static const borderDark = Color(0xFF444444);

  static const ink = Color(0xFFE6E6E6);
  static const inkLight = Color(0xFFAAAAAA);
  static const inkLighter = Color(0xFF777777);
}

ThemeData buildTheme() => _buildTheme(dark: false);
ThemeData buildDarkTheme() => _buildTheme(dark: true);

ThemeData _buildTheme({required bool dark}) {
  final bg = dark ? AppColorsDark.bg : AppColors.bg;
  final surface = dark ? AppColorsDark.surface : AppColors.surface;
  final border = dark ? AppColorsDark.border : AppColors.border;
  final ink = dark ? AppColorsDark.ink : AppColors.ink;
  final inkLight = dark ? AppColorsDark.inkLight : AppColors.inkLight;
  final inkLighter = dark ? AppColorsDark.inkLighter : AppColors.inkLighter;

  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    error: AppColors.heart,
    onError: Colors.white,
    surface: bg,
    onSurface: ink,
    surfaceContainerLowest: bg,
    surfaceContainerLow: surface,
    surfaceContainerHighest: surface,
    outline: border,
    outlineVariant: dark ? AppColorsDark.borderDark : AppColors.borderDark,
  );

  final textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: ink, height: 1.1),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ink),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: inkLight),
    labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: bg,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: inkLighter, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: TextStyle(color: bg, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
