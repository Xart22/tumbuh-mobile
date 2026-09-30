import 'package:flutter/material.dart';

/// Single Source of Truth for Tumbuh POS color design tokens.
/// Extracted from DESIGN.md (Stitch Project 13208093823094807284).
class LpColors {
  LpColors._();

  // --- Primary (Deep Emerald Growth) ---
  static const Color primary = Color(0xFF006948);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF00855D);
  static const Color onPrimaryContainer = Color(0xFFF5FFF7);
  static const Color inversePrimary = Color(0xFF68DBA9);
  static const Color primaryFixed = Color(0xFF85F8C4);
  static const Color primaryFixedDim = Color(0xFF68DBA9);
  static const Color onPrimaryFixed = Color(0xFF002114);
  static const Color onPrimaryFixedVariant = Color(0xFF005137);

  // --- Secondary (Warm Amber Artisan) ---
  static const Color secondary = Color(0xFF855300);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFEA619);
  static const Color onSecondaryContainer = Color(0xFF684000);
  static const Color secondaryFixed = Color(0xFFFFDDB8);
  static const Color secondaryFixedDim = Color(0xFFFFB95F);
  static const Color onSecondaryFixed = Color(0xFF2A1700);
  static const Color onSecondaryFixedVariant = Color(0xFF653E00);

  // --- Tertiary & Neutrals (Midnight Slate & Surfaces) ---
  static const Color tertiary = Color(0xFF545C72);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF6C748B);
  static const Color onTertiaryContainer = Color(0xFFFEFCFF);
  static const Color tertiaryFixed = Color(0xFFDAE2FD);
  static const Color tertiaryFixedDim = Color(0xFFBEC6E0);
  static const Color onTertiaryFixed = Color(0xFF131B2E);
  static const Color onTertiaryFixedVariant = Color(0xFF3F465C);

  // --- Canvas & Surfaces (Light) ---
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF3D4A42);
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);

  // --- Borders & Outlines ---
  static const Color outline = Color(0xFF6D7A72);
  static const Color outlineVariant = Color(0xFFBCCAC0);
  static const Color surfaceTint = Color(0xFF006C4A);

  // --- Error / Critical / Void ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // --- Operational Signal Tokens ---
  static const Color success = Color(0xFF006948);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFF855300);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color critical = Color(0xFFBA1A1A);
  static const Color criticalLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFEFF6FF);

  // --- POS Kasir & KDS Dark Shell Tokens (tactile mode per DESIGN.md & Stitch) ---
  static const Color darkShellSurface = Color(0xFF0F172A);
  static const Color darkShellPanel = Color(0xFF1E293B);
  static const Color darkShellPanelElevated = Color(0xFF26334D);
  static const Color darkShellLine = Color(0xFF334155);
  static const Color darkShellInk = Color(0xFFF8FAFC);
  static const Color darkShellMuted = Color(0xFF94A3B8);
  static const Color darkShellPrimary = Color(0xFF10B981);

  // Modern Tablet POS Theme Palette Tokens (Stitch SSOT)
  static const Color surfaceDark = Color(0xFF0E1116);
  static const Color surfacePanel = Color(0xFF171B22);
  static const Color surfaceCard = Color(0xFF1C222E);
  static const Color surfaceCardHover = Color(0xFF222834);
  static const Color surfaceCardActive = Color(0xFF182B24);
  static const Color surfaceModal = Color(0xFF171B22);
  static const Color borderDark = Color(0xFF2A303A);
  static const Color primaryGreen = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFFEA619);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color darkScrim = Color(0xD107090D);

  // --- KDS Industrial Tokens (Stitch Screen c28323464daa4bb49bb6823822fa2dca) ---
  static const Color kdsBg = Color(0xFF0B0F15);
  static const Color kdsHeader = Color(0xFF11161F);
  static const Color kdsSubBar = Color(0xFF0D1219);
  static const Color kdsCard = Color(0xFF161C24);
  static const Color kdsCardInner = Color(0xFF121720);
  static const Color kdsCardItem = Color(0xFF18202C);
  static const Color kdsCardItemActive = Color(0xFF1B2330);
  static const Color kdsCardBorder = Color(0xFF2D3748);
  static const Color kdsBorderSubtle = Color(0xFF232C3B);
  static const Color kdsOverdue = Color(0xFFBA1A1A);
  static const Color kdsOverdueBorder = Color(0xFFDC2626);
  static const Color kdsAmber = Color(0xFF855300);
  static const Color kdsAmberBorder = Color(0xFFF59E0B);
  static const Color kdsFresh = Color(0xFF004F35);
  static const Color kdsFreshBorder = Color(0xFF10B981);
  static const Color kdsNew = Color(0xFF213145);
  static const Color kdsNewBorder = Color(0xFF2563EB);
}

