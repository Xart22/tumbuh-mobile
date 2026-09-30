import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _numberOnly = NumberFormat('#,##0', 'id_ID');


  /// Formats a number to IDR currency string (e.g., "Rp 25.000").
  /// Respects Honest UI principle: null returns "-" (no fabricated 0).
  static String formatIDR(num? amount, {bool showZeroAsDash = false}) {
    if (amount == null) return '-';
    if (showZeroAsDash && amount == 0) return '-';
    return 'Rp ${_numberOnly.format(amount)}';
  }


  /// Convenience alias for formatIDR
  static String format(num? amount) => formatIDR(amount);


  /// Formats only the number part (e.g., "25.000").
  static String formatAmount(num? amount) {
    if (amount == null) return '-';
    return _numberOnly.format(amount);
  }
}

/// A specialized widget to render currency adhering to DESIGN.md:
/// "Simbol mata uang Rp dirender dengan bobot reguler/medium warna slate (text-lp-tertiary),
/// diikuti angka nominal tebal warna navy (text-lp-on-surface) JetBrains Mono."
class CurrencyText extends StatelessWidget {
  final num? amount;
  final TextStyle? style;
  final TextStyle? symbolStyle;
  final Color? color;
  final bool isLarge;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.symbolStyle,
    this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (amount == null) {
      return Text(
        '-',
        style: style ?? (isLarge ? LpTypography.dataCurrencyLg : LpTypography.dataCurrency),
      );
    }

    final formattedNumber = CurrencyFormatter.formatAmount(amount);
    final baseStyle = style ?? (isLarge ? LpTypography.dataCurrencyLg : LpTypography.dataCurrency);
    final effectiveTextColor = color ?? baseStyle.color ?? LpColors.onSurface;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Rp ',
            style: (symbolStyle ?? baseStyle).copyWith(
              fontWeight: FontWeight.w400,
              color: LpColors.tertiary,
            ),
          ),
          TextSpan(
            text: formattedNumber,
            style: baseStyle.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
