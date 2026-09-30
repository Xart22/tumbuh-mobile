import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Standardized typography protocol per DESIGN.md:
/// 1. Plus Jakarta Sans: structural text, headings, buttons, forms.
/// 2. JetBrains Mono: currency (Rupiah), HPP, margins, timers, grammage, SKU (tnum).
class LpTypography {
  LpTypography._();

  // --- Display ---
  static TextStyle displayLg = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    letterSpacing: -0.02 * 36,
    color: LpColors.onSurface,
  );

  static TextStyle displayLgMobile = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.02 * 28,
    color: LpColors.onSurface,
  );

  // --- Headlines ---
  static TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.015 * 24,
    color: LpColors.onSurface,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.01 * 20,
    color: LpColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: -0.005 * 16,
    color: LpColors.onSurface,
  );

  // --- Body ---
  static TextStyle bodyLg = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: LpColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: LpColors.onSurface,
  );

  static TextStyle bodySm = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
    color: LpColors.onSurfaceVariant,
  );

  // --- Labels ---
  static TextStyle labelLg = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.01 * 14,
    color: LpColors.onSurface,
  );

  static TextStyle labelMd = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.01 * 12,
    color: LpColors.onSurface,
  );

  static TextStyle labelSm = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.04 * 11,
    color: LpColors.onSurfaceVariant,
  );

  // --- Tabular Figures & Currency (JetBrains Mono) ---
  static TextStyle dataCurrencyLg = GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
    letterSpacing: -0.03 * 24,
    color: LpColors.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle dataCurrency = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    letterSpacing: -0.02 * 16,
    color: LpColors.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle dataCurrencySm = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
    letterSpacing: -0.01 * 13,
    color: LpColors.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle dataMonoSm = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
    color: LpColors.onSurfaceVariant,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // --- Convenience Aliases ---
  static TextStyle get titleLarge => headlineMd;
  static TextStyle get titleMedium => headlineSm;
  static TextStyle get titleSmall => labelLg;
  static TextStyle get titleSm => labelLg;
  static TextStyle get titleMd => headlineMd;
  static TextStyle get headlineSmall => headlineSm;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm;
  static TextStyle get mono => dataMonoSm;
}

