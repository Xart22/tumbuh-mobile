import 'package:flutter/material.dart';

class CashDenomination {
  final int nominal;
  final String label;
  final String description;
  final Color badgeColor;
  final Color textColor;
  int count;

  CashDenomination({
    required this.nominal,
    required this.label,
    required this.description,
    required this.badgeColor,
    required this.textColor,
    this.count = 0,
  });

  int get subtotal => nominal * count;

  CashDenomination copyWith({int? count}) {
    return CashDenomination(
      nominal: nominal,
      label: label,
      description: description,
      badgeColor: badgeColor,
      textColor: textColor,
      count: count ?? this.count,
    );
  }

  static List<CashDenomination> defaultDenominations() {
    return [
      CashDenomination(
        nominal: 100000,
        label: '100k',
        description: 'Uang Kertas Merah',
        badgeColor: const Color(0xFF450A0A),
        textColor: const Color(0xFFF87171),
        count: 0,
      ),
      CashDenomination(
        nominal: 50000,
        label: '50k',
        description: 'Uang Kertas Biru',
        badgeColor: const Color(0xFF172554),
        textColor: const Color(0xFF60A5FA),
        count: 0,
      ),
      CashDenomination(
        nominal: 20000,
        label: '20k',
        description: 'Uang Kertas Hijau',
        badgeColor: const Color(0xFF064E3B),
        textColor: const Color(0xFF34D399),
        count: 0,
      ),
      CashDenomination(
        nominal: 10000,
        label: '10k',
        description: 'Uang Kertas Ungu',
        badgeColor: const Color(0xFF3B0764),
        textColor: const Color(0xFFC084FC),
        count: 0,
      ),
      CashDenomination(
        nominal: 5000,
        label: '5k',
        description: 'Uang Kertas Coklat',
        badgeColor: const Color(0xFF422006),
        textColor: const Color(0xFFFBBF24),
        count: 0,
      ),
      CashDenomination(
        nominal: 2000,
        label: '2k+',
        description: 'Pecahan Kecil / Koin',
        badgeColor: const Color(0xFF1F2937),
        textColor: const Color(0xFF9CA3AF),
        count: 0,
      ),
    ];
  }
}
