import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/network/api_client.dart';
import '../../features/owner/data/models/inventory_stock_model.dart';
import '../../features/owner/data/models/owner_dashboard_model.dart';

/// Aggregated dashboard payload for the owner home screen.
class OwnerDashboardSnapshot {
  final OwnerKpiData kpi;
  final List<HourlySalesPoint> hourlySales;
  final List<TopProductItem> topProducts;
  final List<PaymentMethodShare> paymentShares;
  final List<StockAlertItem> stockAlerts;

  const OwnerDashboardSnapshot({
    required this.kpi,
    required this.hourlySales,
    required this.topProducts,
    required this.paymentShares,
    required this.stockAlerts,
  });
}

/// Owner backoffice reads (tumbuh-be `/v1/reports/*`, `/v1/orders`).
class OwnerRepository {
  final ApiClient apiClient;

  OwnerRepository({required this.apiClient});

  Future<OwnerDashboardSnapshot> fetchDashboard({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final ymd = _ymd(today);

    final results = await Future.wait<dynamic>([
      apiClient.getWithRetry('/v1/reports/daily-summary', queryParameters: {'date': ymd}),
      apiClient.getWithRetry('/v1/reports/daily-summary', queryParameters: {'date': _ymd(yesterday)}),
      apiClient.getWithRetry('/v1/reports/top-products',
          queryParameters: {'dateFrom': ymd, 'dateTo': ymd, 'top': 5}),
      apiClient.getWithRetry('/v1/reports/payment-methods',
          queryParameters: {'dateFrom': ymd, 'dateTo': ymd}),
      apiClient.getWithRetry('/v1/reports/hourly-sales', queryParameters: {'date': ymd}),
      apiClient.getWithRetry('/v1/reports/profit',
          queryParameters: {'dateFrom': ymd, 'dateTo': ymd}),
      apiClient.getWithRetry('/v1/orders', queryParameters: {'status': 'held'}),
      apiClient.getWithRetry('/v1/inventory/low-stock'),
    ]);

    final daily = _asMap(results[0].data);
    final prevDaily = _asMap(results[1].data);
    final topProducts = (results[2].data as List<dynamic>).cast<Map<String, dynamic>>();
    final paymentMethods = _asMap(results[3].data);
    final hourly = _asMap(results[4].data);
    final profit = _asMap(results[5].data);
    final heldOrders = (results[6].data as List<dynamic>).cast<Map<String, dynamic>>();
    final lowStock = _asMap(results[7].data);

    return OwnerDashboardSnapshot(
      kpi: buildKpi(
        daily: daily,
        previousDaily: prevDaily,
        profit: profit,
        heldOrders: heldOrders,
      ),
      hourlySales: buildHourly(hourly),
      topProducts: topProducts.map(buildTopProduct).toList(),
      paymentShares: buildPaymentShares(paymentMethods),
      stockAlerts: buildStockAlerts(lowStock),
    );
  }

  @visibleForTesting
  static List<StockAlertItem> buildStockAlerts(Map<String, dynamic> lowStock) {
    final items = ((lowStock['items'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map((row) {
      final stockQty = (row['stockQty'] as num?)?.toDouble() ?? 0;
      return StockAlertItem(
        id: row['id'] as String,
        name: row['name'] as String? ?? 'Bahan',
        category: 'Bahan',
        currentStock: stockQty,
        unit: row['unit'] as String? ?? '',
        minStock: (row['minStockQty'] as num?)?.toDouble() ?? 0,
        supplierName: '-',
        isCritical: stockQty <= 0,
        suggestedReorderQuantity:
            (row['shortageQty'] as num?)?.toDouble() ?? 0,
        estimatedPricePerUnit: (row['costPerUnit'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : const {};

  static int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

  @visibleForTesting
  static OwnerKpiData buildKpi({
    required Map<String, dynamic> daily,
    required Map<String, dynamic> previousDaily,
    required Map<String, dynamic> profit,
    required List<Map<String, dynamic>> heldOrders,
  }) {
    final netSales = _int(daily['netSales']);
    final prevNet = _int(previousDaily['netSales']);
    final growth = prevNet > 0 ? ((netSales - prevNet) / prevNet) * 100 : 0.0;

    final heldValue = heldOrders.fold<int>(0, (sum, o) => sum + _int(o['total']));

    return OwnerKpiData(
      todayRevenue: netSales,
      targetRevenue: _int(daily['dailyRevenueTarget']),
      growthVsYesterdayPct: growth,
      grossProfit: _int(profit['grossProfit']),
      grossMarginPct: (profit['grossMarginPct'] as num?)?.toDouble() ?? 0,
      transactionCount: _int(daily['orderCount']),
      avgTicket: _int(daily['averageOrderValue']),
      openBillsCount: heldOrders.length,
      openBillsValue: heldValue,
      cashierDeposit: 0,
      cashVariance: 0,
    );
  }

  @visibleForTesting
  static List<HourlySalesPoint> buildHourly(Map<String, dynamic> hourly) {
    final buckets = ((hourly['buckets'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    final peakHour = _int(hourly['peakHour']);
    final maxAmount = buckets.fold<int>(
      0,
      (max, b) => _int(b['grossSales']) > max ? _int(b['grossSales']) : max,
    );

    return buckets.map((b) {
      final hour = _int(b['hour']);
      final amount = _int(b['grossSales']);
      return HourlySalesPoint(
        hour: hour,
        label: '${hour.toString().padLeft(2, '0')}:00',
        amount: amount,
        heightFactor: maxAmount > 0 ? amount / maxAmount : 0.0,
        isPeak: hour == peakHour && amount > 0,
      );
    }).toList();
  }

  @visibleForTesting
  static TopProductItem buildTopProduct(Map<String, dynamic> row) => TopProductItem(
        id: row['productId'] as String,
        name: row['productName'] as String? ?? 'Produk',
        category: row['categoryName'] as String? ?? '-',
        soldCount: _int(row['soldQty']),
        totalRevenue: _int(row['revenue']),
        marginPct: 0,
      );

  @visibleForTesting
  static List<PaymentMethodShare> buildPaymentShares(
    Map<String, dynamic> paymentMethods,
  ) {
    final methods = ((paymentMethods['methods'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    return methods
        .map((m) => PaymentMethodShare(
              method: paymentMethodLabel(m['method'] as String?),
              totalAmount: _int(m['amount']),
              percentage: (m['percentage'] as num?)?.toDouble() ?? 0,
              transactionCount: _int(m['transactionCount']),
            ))
        .toList();
  }

  @visibleForTesting
  static String paymentMethodLabel(String? code) {
    switch (code) {
      case 'cash':
        return 'Tunai';
      case 'qris':
      case 'qris_dynamic':
        return 'QRIS';
      case 'debit':
        return 'Debit';
      case 'credit':
        return 'Kredit';
      case 'deposit':
        return 'Deposit';
      default:
        if (code != null && code.startsWith('ewallet_')) return 'E-Wallet';
        return code ?? 'Lainnya';
    }
  }
}
