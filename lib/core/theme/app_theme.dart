// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const bg        = Color(0xFFF8F7F4);
  static const bg2       = Color(0xFFF0EFE9);
  static const bg3       = Color(0xFFE8E6DE);
  static const surface   = Color(0xFFFFFFFF);
  static const ink       = Color(0xFF0D0D0D);
  static const ink2      = Color(0xFF3A3A3A);
  static const ink3      = Color(0xFF7A7A7A);
  static const ink4      = Color(0xFFB0B0B0);
  static const line      = Color(0xFFD8D6CE);
  static const line2     = Color(0xFFEBEBEB);
  static const green     = Color(0xFF00E676);
  static const greenDim  = Color(0x1F00E676);
  static const red       = Color(0xFFFF3B3B);
  static const redDim    = Color(0x19FF3B3B);
  static const amber     = Color(0xFFFF9500);
  static const amberDim  = Color(0x19FF9500);
  static const blue      = Color(0xFF0057FF);
  static const blueDim   = Color(0x190057FF);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = GoogleFonts.instrumentSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        primary:   AppColors.ink,
        secondary: AppColors.green,
        surface:   AppColors.surface,
        error:     AppColors.red,
        onPrimary: AppColors.surface,
        onSecondary: AppColors.ink,
        onSurface: AppColors.ink,
      ),
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.bebasNeue(fontSize: 56, letterSpacing: 1.5, color: AppColors.ink),
        displayMedium: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 1.2, color: AppColors.ink),
        displaySmall: GoogleFonts.bebasNeue(fontSize: 32, letterSpacing: 1.0, color: AppColors.ink),
        headlineLarge: GoogleFonts.instrumentSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.instrumentSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.4),
        headlineSmall: GoogleFonts.instrumentSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.3),
        titleLarge: GoogleFonts.instrumentSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
        titleMedium: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
        titleSmall: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink3),
        bodyLarge: GoogleFonts.instrumentSans(fontSize: 15, color: AppColors.ink2),
        bodyMedium: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink2),
        bodySmall: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink3),
        labelLarge: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
        labelSmall: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.ink3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.instrumentSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
        shape: const Border(bottom: BorderSide(color: AppColors.line, width: 1.5)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.ink4,
        selectedLabelStyle: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.instrumentSans(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.ink, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
        labelStyle: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink3),
        hintStyle: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bg3,
        labelStyle: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.line),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 0),
    );
  }
}
