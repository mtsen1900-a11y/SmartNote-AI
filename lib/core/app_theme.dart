import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Colors (Notion & Obsidian & Linear Style)
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFEEF2FF);

  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Light Theme Neutrals
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextMain = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightSidebar = Color(0xFFF1F5F9);

  // Dark Theme Neutrals
  static const Color darkBg = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF131926);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextMain = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkSidebar = Color(0xFF0E1420);

  // Backward compatibility alias
  static const Color background = lightBg;
  static const Color sidebar = lightSidebar;
  static const Color surface = lightSurface;
  static const Color softSurface = Color(0xFFEDF2F7);
  static const Color text = lightTextMain;
  static const Color muted = lightTextMuted;
  static const Color subtle = Color(0xFF94A3B8);
  static const Color border = lightBorder;
  static const Color accent = primary;
  static const Color accentSoft = primaryLight;
  static const Color purple = accentPurple;
  static const Color danger = accentRose;
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextMain,
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lightBorder, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightSurface,
          foregroundColor: AppColors.lightTextMain,
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: AppColors.lightBorder,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.lightTextMain, fontSize: 14, height: 1.5),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextMain,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextMain,
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: AppColors.darkBorder,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.darkTextMain, fontSize: 14, height: 1.5),
        ),
      );
}
