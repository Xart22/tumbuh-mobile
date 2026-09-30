import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/remote/owner_repository.dart';

void main() {
  group('OwnerRepository dashboard mapping', () {
    test('buildKpi combines daily summary, profit and held orders', () {
      final kpi = OwnerRepository.buildKpi(
        daily: {
          'netSales': 1200000,
          'grossSales': 1300000,
          'orderCount': 40,
          'averageOrderValue': 30000,
          'dailyRevenueTarget': 2000000,
        },
        previousDaily: {'netSales': 1000000},
        profit: {'grossProfit': 400000, 'grossMarginPct': 33.3},
        heldOrders: [
          {'total': 50000},
          {'total': 70000},
        ],
      );

      expect(kpi.todayRevenue, 1200000);
      expect(kpi.targetRevenue, 2000000);
      expect(kpi.growthVsYesterdayPct, closeTo(20.0, 0.001));
      expect(kpi.grossProfit, 400000);
      expect(kpi.transactionCount, 40);
      expect(kpi.avgTicket, 30000);
      expect(kpi.openBillsCount, 2);
      expect(kpi.openBillsValue, 120000);
    });

    test('buildHourly normalizes height and marks the peak hour', () {
      final points = OwnerRepository.buildHourly({
        'peakHour': 12,
        'buckets': [
          {'hour': 11, 'grossSales': 50000},
          {'hour': 12, 'grossSales': 100000},
        ],
      });

      expect(points, hasLength(2));
      expect(points[0].label, '11:00');
      expect(points[0].heightFactor, 0.5);
      expect(points[1].isPeak, isTrue);
      expect(points[1].heightFactor, 1.0);
    });

    test('buildPaymentShares maps labels and amounts', () {
      final shares = OwnerRepository.buildPaymentShares({
        'methods': [
          {'method': 'qris_dynamic', 'amount': 75000, 'percentage': 75, 'transactionCount': 3},
          {'method': 'cash', 'amount': 25000, 'percentage': 25, 'transactionCount': 1},
        ],
      });

      expect(shares.first.method, 'QRIS');
      expect(shares.first.totalAmount, 75000);
      expect(shares.last.method, 'Tunai');
      expect(OwnerRepository.paymentMethodLabel('ewallet_gopay'), 'E-Wallet');
    });
  });
}
