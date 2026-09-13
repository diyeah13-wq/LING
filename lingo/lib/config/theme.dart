import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LINGO design tokens — colors, spacing, radii, and typography.
class LingoColors {
  // Brand
  static const Color primary = Color(0xFF4F6EF7); // Friendly vibrant indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF10B981); // Emerald success green
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color accent = Color(0xFFF59E0B); // Warm amber / XP gold
  static const Color error = Color(0xFFEF4444); // Red

  // Neutrals (light)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);

  // Neutrals (dark)
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF161E2E);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF26334D);

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
        surfaceContainerHighest: LingoColors.surfaceElevated,
        primary: LingoColors.primary,
        secondary: LingoColors.secondary,
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: LingoColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: LingoColors.textPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: LingoColors.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: LingoColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: LingoColors.textPrimary,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: LingoColors.textSecondary,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: LingoColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: LingoColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: LingoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(LingoRadius.lg)),
          side: const BorderSide(color: LingoColors.divider, width: 1.2),
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LingoColors.primary,
          side: const BorderSide(color: LingoColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LingoRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LingoColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        surfaceContainerHighest: LingoColors.darkSurfaceElevated,
        primary: LingoColors.primary,
        secondary: LingoColors.secondary,
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: LingoColors.darkTextPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: LingoColors.darkTextPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: LingoColors.darkTextPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: LingoColors.darkTextPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: LingoColors.darkTextPrimary,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: LingoColors.darkTextSecondary,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: LingoColors.darkBackground,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: LingoColors.darkTextPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: LingoColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(LingoRadius.lg)),
          side: const BorderSide(color: LingoColors.darkDivider, width: 1.2),
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LingoColors.primaryLight,
          side: const BorderSide(color: LingoColors.darkDivider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LingoRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LingoColors.primaryLight,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}