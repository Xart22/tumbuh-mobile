import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/models/outlet_pricing.dart';
import 'package:tumbuh_mobile/shared/math/order_math.dart';

void main() {
  group('OutletPricing.fromOutletJson', () {
    test('reads tax/service/rounding from BE settings blob', () {
      final p = OutletPricing.fromOutletJson({
        'settings': {
          'tax': {'enabled': true, 'rate': 11, 'name': 'PPN'},
          'serviceCharge': {'enabled': true, 'rate': 5},
          'roundingBase': 100,
        },
      });
      expect(p.taxEnabled, isTrue);
      expect(p.taxRate, 11);
      expect(p.taxName, 'PPN');
      expect(p.serviceChargeEnabled, isTrue);
      expect(p.serviceChargeRate, 5);
      expect(p.roundingBase, 100);
    });

    test('falls back to backend defaults when settings missing', () {
      final p = OutletPricing.fromOutletJson({});
      expect(p.taxRate, OutletPricing.defaultBackend.taxRate);
      expect(p.roundingBase, 100);
      expect(p.serviceChargeEnabled, isFalse);
    });
  });

  group('OrderMath.calculateDraft matches backend semantics', () {
    test('tax and service apply independently on after-discount subtotal', () {
      final totals = OrderMath.calculateDraft(
        items: const [OrderItemDraft(id: '1', price: 90000, quantity: 1)],
        taxPercent: 10,
        serviceChargePercent: 5,
        roundingBase: 100,
      );
      // 90000 -> service 4500, tax 9000, total 103500 (already round to 100)
      expect(totals.serviceCharge, 4500);
      expect(totals.tax, 9000);
      expect(totals.grandTotal, 103500);
    });
  });
}
