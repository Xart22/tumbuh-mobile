import 'package:equatable/equatable.dart';

class OwnerKpiData extends Equatable {
  final int todayRevenue;
  final int targetRevenue;
  final double growthVsYesterdayPct;
  final int grossProfit;
  final double grossMarginPct;
  final int cogs;
  final int taxCollected;
  final int transactionCount;
  final int avgTicket;
  final int openBillsCount;
  final int openBillsValue;
  final int cashierDeposit;
  final int cashVariance;

  const OwnerKpiData({
    required this.todayRevenue,
    required this.targetRevenue,
    required this.growthVsYesterdayPct,
    required this.grossProfit,
    required this.grossMarginPct,
    this.cogs = 0,
    this.taxCollected = 0,
    required this.transactionCount,
    required this.avgTicket,
    required this.openBillsCount,
    required this.openBillsValue,
    required this.cashierDeposit,
    required this.cashVariance,
  });

  double get targetProgressPct =>
      targetRevenue > 0 ? (todayRevenue / targetRevenue).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        todayRevenue,
        targetRevenue,
        growthVsYesterdayPct,
        grossProfit,
        grossMarginPct,
        cogs,
        taxCollected,
        transactionCount,
        avgTicket,
        openBillsCount,
        openBillsValue,
        cashierDeposit,
        cashVariance,
      ];
}

class HourlySalesPoint extends Equatable {
  final int hour;
  final String label;
  final int amount;
  final double heightFactor;
  final bool isPeak;

  const HourlySalesPoint({
    required this.hour,
    required this.label,
    required this.amount,
    required this.heightFactor,
    this.isPeak = false,
  });

  @override
  List<Object?> get props => [hour, label, amount, heightFactor, isPeak];
}

class TopProductItem extends Equatable {
  final String id;
  final String name;
  final String category;
  final int soldCount;
  final int totalRevenue;
  final double marginPct;

  const TopProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.soldCount,
    required this.totalRevenue,
    required this.marginPct,
  });

  @override
  List<Object?> get props => [id, name, category, soldCount, totalRevenue, marginPct];
}

class PaymentMethodShare extends Equatable {
  final String method;
  final int totalAmount;
  final double percentage;
  final int transactionCount;

  const PaymentMethodShare({
    required this.method,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [method, totalAmount, percentage, transactionCount];
}
