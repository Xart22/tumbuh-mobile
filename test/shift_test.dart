import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/models/cash_denomination.dart';
import 'package:tumbuh_mobile/data/models/shift_model.dart';

void main() {
  group('Shift & Cash Denomination Tests', () {
    test('Calculates cash denominations subtotal and total accurately', () {
      final denoms = CashDenomination.defaultDenominations();

      // Set counts matching Stitch design sample:
      // 100k x 15 = 1.500.000
      // 50k x 24 = 1.200.000
      // 20k x 18 = 360.000
      // 10k x 15 = 150.000
      // 5k x 6 = 30.000
      // 2k x 5 = 10.000
      denoms[0].count = 15;
      denoms[1].count = 24;
      denoms[2].count = 18;
      denoms[3].count = 15;
      denoms[4].count = 6;
      denoms[5].count = 5;

      expect(denoms[0].subtotal, 1500000);
      expect(denoms[1].subtotal, 1200000);
      expect(denoms[2].subtotal, 360000);
      expect(denoms[3].subtotal, 150000);
      expect(denoms[4].subtotal, 30000);
      expect(denoms[5].subtotal, 10000);

      final grandTotal = denoms.fold<int>(0, (sum, d) => sum + d.subtotal);
      final totalSheets = denoms.fold<int>(0, (sum, d) => sum + d.count);

      expect(grandTotal, 3250000);
      expect(totalSheets, 83);
    });

    test('Computes variance balance perfect (Rp 0)', () {
      final shift = ShiftModel(
        id: 'shift_1',
        shiftNumber: 1094,
        shiftName: 'Shift 1 Pagi',
        cashierId: 'cashier_01',
        cashierName: 'Barista Rama',
        outletId: 'outlet_01',
        outletName: 'Kopi Kita – Cabang Tebet',
        deviceId: 'dev_01',
        deviceName: 'Samsung Tab A9+',
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        initialFloat: 500000,
        cashSales: 2750000,
        cashSalesCount: 148,
        nonCashSales: 4250000,
        nonCashSalesCount: 85,
        actualCashCount: 3250000,
      );

      // Expected = 500.000 + 2.750.000 = 3.250.000
      // Actual = 3.250.000
      // Variance = 0 (Balance Perfect)
      expect(shift.expectedCashInDrawer, 3250000);
      expect(shift.variance, 0);
    });

    test('Computes variance shortage (minus) and surplus correctly', () {
      final baseShift = ShiftModel(
        id: 'shift_2',
        shiftNumber: 1095,
        shiftName: 'Shift 2 Sore',
        cashierId: 'cashier_02',
        cashierName: 'Kasir Dika',
        outletId: 'outlet_01',
        outletName: 'Kopi Kita – Cabang Tebet',
        deviceId: 'dev_01',
        deviceName: 'Samsung Tab A9+',
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        initialFloat: 500000,
        cashSales: 2000000,
      );

      // Expected = 2.500.000
      // Case 1: Shortage by 50.000
      final shortShift = baseShift.copyWith(actualCashCount: 2450000);
      expect(shortShift.variance, -50000);

      // Case 2: Surplus by 20.000
      final surplusShift = baseShift.copyWith(actualCashCount: 2520000);
      expect(surplusShift.variance, 20000);
    });

    test('Maps backend mapShift payload', () {
      final shift = ShiftModel.fromBackend({
        'id': 'sh_1',
        'outletId': 'out_1',
        'employeeId': 'emp_1',
        'employeeName': 'Rama',
        'shiftName': 'Shift Pagi',
        'openedAt': '2026-10-01T07:30:00.000Z',
        'closedAt': null,
        'openingCash': 500000,
        'closingCash': null,
        'expectedCash': null,
        'status': 'open',
      });
      expect(shift.id, 'sh_1');
      expect(shift.cashierId, 'emp_1');
      expect(shift.cashierName, 'Rama');
      expect(shift.initialFloat, 500000);
      expect(shift.endTime, isNull);
      expect(shift.isOpen, isTrue);
    });
  });
}
