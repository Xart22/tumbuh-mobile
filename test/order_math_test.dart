import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/shared/math/order_math.dart';

void main() {
  group('OrderMath Tests', () {
    test('Calculates gross subtotal correctly without discounts or taxes', () {
      final items = [
        const OrderMathItem(
          id: '1',
          name: 'Kopi Susu Gula Aren',
          unitPrice: 20000,
          quantity: 2,
          modifierPrices: [3000], // Extra shot
        ),
        const OrderMathItem(
          id: '2',
          name: 'Croissant Butter',
          unitPrice: 25000,
          quantity: 1,
        ),
      ];

      final totals = OrderMath.computeOrderTotals(
        OrderCalculationParams(items: items),
      );

      // (20000 + 3000) * 2 = 46000
      // 25000 * 1 = 25000
      // Total = 71000
      expect(totals.grossSubtotal, 71000);
      expect(totals.totalDiscount, 0);
      expect(totals.netSubtotal, 71000);
      expect(totals.finalTotal, 71000);
    });

    test('Calculates service charge, PB1 10%, and rounding 100 correctly', () {
      final items = [
        const OrderMathItem(
          id: '1',
          name: 'Nasi Goreng Spesial',
          unitPrice: 45000,
          quantity: 2, // 90.000
        ),
      ];

      final totals = OrderMath.computeOrderTotals(
        OrderCalculationParams(
          items: items,
          serviceChargeRate: 0.05, // 5% -> 4.500
          taxRate: 0.10, // 10% PB1 on (90.000 + 4.500) = 94.500 -> 9.450
          taxIncludesService: true,
          roundingBase: 100, // 90.000 + 4.500 + 9.450 = 103.950 -> rounded to 104.000 (+50)
        ),
      );

      expect(totals.grossSubtotal, 90000);
      expect(totals.serviceCharge, 4500);
      expect(totals.tax, 9450);
      expect(totals.rounding, 50);
      expect(totals.finalTotal, 104000);
    });

    test('Applies order percentage discount before tax and service', () {
      final items = [
        const OrderMathItem(
          id: '1',
          name: 'Pizza Margherita',
          unitPrice: 100000,
          quantity: 1,
        ),
      ];

      final totals = OrderMath.computeOrderTotals(
        OrderCalculationParams(
          items: items,
          orderDiscountPercent: 20.0, // 20% off 100.000 -> 20.000
          taxRate: 0.10, // 10% of 80.000 -> 8.000
        ),
      );

      expect(totals.grossSubtotal, 100000);
      expect(totals.orderDiscount, 20000);
      expect(totals.netSubtotal, 80000);
      expect(totals.tax, 8000);
      expect(totals.finalTotal, 88000);
    });
  });
}
