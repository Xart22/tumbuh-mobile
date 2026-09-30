import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/models/order_record.dart';

void main() {
  group('OrderRecord.fromJson', () {
    test('maps order fields and item lines', () {
      final order = OrderRecord.fromJson({
        'id': 'o1',
        'orderNumber': 'TB-1',
        'orderType': 'take_away',
        'status': 'completed',
        'paymentStatus': 'paid',
        'total': 55000,
        'tableNumber': null,
        'customerName': 'Dian',
        'createdAt': '2026-10-01T08:00:00.000Z',
        'items': [
          {'id': 'i1', 'productName': 'Kopi', 'qty': 2, 'unitPrice': 25000, 'status': 'served'},
        ],
      });

      expect(order.id, 'o1');
      expect(order.orderTypeLabel, 'Take Away');
      expect(order.total, 55000);
      expect(order.customerName, 'Dian');
      expect(order.items, hasLength(1));
      expect(order.items.first.qty, 2);
      expect(order.items.first.unitPrice, 25000);
    });
  });
}
