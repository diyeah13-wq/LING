import 'package:flutter/material.dart';

/// LINGO design tokens — colors, spacing, radii, and typography.
///
/// Centralized so the whole app feels consistent and theming is easy to adjust.
class LingoColors {
  // Brand
  static const Color primary = Color(0xFF4F6EF7); // Friendly indigo
  static const Color secondary = Color(0xFF10B981); // Success green
  static const Color accent = Color(0xFFF59E0B); // Warm amber accent
  static const Color error = Color(0xFFEF4444); // Friendly red

  // Neutrals (light)
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Neutrals (dark)
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D27);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkDivider = Color(0xFF2A2E3A);

  // Misc
  static const Color mascot = Color(0xFF34D399); // Mascot green
}

class LingoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class LingoRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class LingoAppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LingoColors.primary,
        brightness: Brightness.light,
        surface: LingoColors.surface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: LingoColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: LingoColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: LingoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LingoRadius.lg)),
          side: BorderSide(color: LingoColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LingoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LingoRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LingoColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: LingoColors.surface,
        side: BorderSide(color: LingoColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LingoRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LingoColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingoRadius.md),
          borderSide: const BorderSide(color: LingoColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingoRadius.md),
          borderSide: const BorderSide(color: LingoColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingoRadius.md),
          borderSide: const BorderSide(color: LingoColors.primary, width: 2),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: LingoColors.textPrimary,
          height: 1.2,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: LingoColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: LingoColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: LingoColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LingoColors.primary,
        brightness: Brightness.dark,
        surface: LingoColors.darkSurface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: LingoColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: LingoColors.darkTextPrimary,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: LingoColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LingoRadius.lg)),
          side: BorderSide(color: LingoColors.darkDivider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LingoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LingoRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LingoColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: LingoColors.darkSurface,
        side: BorderSide(color: LingoColors.darkDivider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LingoRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LingoColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingoRadius.md),
          borderSide: const BorderSide(color: LingoColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingoRadius.md),
          borderSide: const BorderSide(color: LingoColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingoRadius.md),
          borderSide: const BorderSide(color: LingoColors.primary, width: 2),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: LingoColors.darkTextPrimary,
          height: 1.2,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: LingoColors.darkTextPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: LingoColors.darkTextPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: LingoColors.darkTextSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}