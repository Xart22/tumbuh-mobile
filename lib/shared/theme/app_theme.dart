import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  /// Light Theme for Backoffice, Owner, CRM, Settings
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: LpColors.primary,
      onPrimary: LpColors.onPrimary,
      primaryContainer: LpColors.primaryContainer,
      onPrimaryContainer: LpColors.onPrimaryContainer,
      secondary: LpColors.secondary,
      onSecondary: LpColors.onSecondary,
      secondaryContainer: LpColors.secondaryContainer,
      onSecondaryContainer: LpColors.onSecondaryContainer,
      tertiary: LpColors.tertiary,
      onTertiary: LpColors.onTertiary,
      tertiaryContainer: LpColors.tertiaryContainer,
      onTertiaryContainer: LpColors.onTertiaryContainer,
      error: LpColors.error,
      onError: LpColors.onError,
      errorContainer: LpColors.errorContainer,
      onErrorContainer: LpColors.onErrorContainer,
      surface: LpColors.surface,
      onSurface: LpColors.onSurface,
      onSurfaceVariant: LpColors.onSurfaceVariant,
      outline: LpColors.outline,
      outlineVariant: LpColors.outlineVariant,
      inverseSurface: LpColors.inverseSurface,
      onInverseSurface: LpColors.inverseOnSurface,
      inversePrimary: LpColors.inversePrimary,
      surfaceTint: LpColors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LpColors.background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: LpTypography.displayLg,
        headlineLarge: LpTypography.headlineLg,
        headlineMedium: LpTypography.headlineMd,
        headlineSmall: LpTypography.headlineSm,
        bodyLarge: LpTypography.bodyLg,
        bodyMedium: LpTypography.bodyMd,
        bodySmall: LpTypography.bodySm,
        labelLarge: LpTypography.labelLg,
        labelMedium: LpTypography.labelMd,
        labelSmall: LpTypography.labelSm,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LpColors.surfaceContainerLowest,
        foregroundColor: LpColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: LpTypography.headlineSm,
      ),
      cardTheme: CardThemeData(
        color: LpColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LpColors.surfaceContainer, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LpColors.primary,
          foregroundColor: LpColors.onPrimary,
          minimumSize: const Size(88, 44), // min 44px touch target
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: LpTypography.labelLg.copyWith(color: LpColors.onPrimary),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LpColors.onSurface,
          backgroundColor: LpColors.surfaceContainerLowest,
          side: const BorderSide(color: LpColors.outlineVariant, width: 1),
          minimumSize: const Size(88, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: LpTypography.labelLg,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LpColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(minHeight: 44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LpColors.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LpColors.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LpColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LpColors.error, width: 1),
        ),
        labelStyle: LpTypography.bodyMd.copyWith(color: LpColors.onSurfaceVariant),
        hintStyle: LpTypography.bodyMd.copyWith(color: LpColors.tertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: LpColors.surfaceContainer,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark Shell Theme for Tablet Cashier (POS) & Kitchen Display System (KDS)
  static ThemeData get darkPosTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: LpColors.darkShellPrimary,
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF065F46),
      onPrimaryContainer: Color(0xFFD1FAE5),
      secondary: Color(0xFFF59E0B),
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF78350F),
      onSecondaryContainer: Color(0xFFFEF3C7),
      tertiary: LpColors.darkShellMuted,
      onTertiary: Colors.white,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      surface: LpColors.darkShellSurface,
      onSurface: LpColors.darkShellInk,
      onSurfaceVariant: LpColors.darkShellMuted,
      outline: LpColors.darkShellLine,
      outlineVariant: Color(0xFF475569),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LpColors.darkShellSurface,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: LpColors.darkShellPanel,
        foregroundColor: LpColors.darkShellInk,
        elevation: 0,
        titleTextStyle: LpTypography.headlineSm.copyWith(color: LpColors.darkShellInk),
      ),
      cardTheme: CardThemeData(
        color: LpColors.darkShellPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LpColors.darkShellLine, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LpColors.darkShellPrimary,
          foregroundColor: Colors.black,
          minimumSize: const Size(88, 48), // fat-finger friendly for tablet touch
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: LpTypography.labelLg.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LpColors.darkShellInk,
          backgroundColor: LpColors.darkShellPanel,
          side: const BorderSide(color: LpColors.darkShellLine, width: 1),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: LpTypography.labelLg.copyWith(color: LpColors.darkShellInk),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LpColors.darkShellLine,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
