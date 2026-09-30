import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/remote/pos_repository.dart';

void main() {
  group('PosRepository catalog mapping (backend -> domain)', () {
    test('mapCategory reads id/name/sortOrder', () {
      final c = PosRepository.mapCategory({
        'id': 'cat_1',
        'name': 'Kopi',
        'sortOrder': 3,
      });
      expect(c.id, 'cat_1');
      expect(c.name, 'Kopi');
      expect(c.sortOrder, 3);
    });

    test('parkedBillFromOrder maps a held order and rebuilds unit price', () {
      final bill = PosRepository.parkedBillFromOrder(
        {
          'id': 'o1',
          'orderNumber': 'TB-001',
          'orderType': 'dine_in',
          'tableNumber': 'Meja 04',
          'customerName': 'Dian',
          'createdAt': '2026-10-01T08:00:00.000Z',
          'items': [
            {
              'id': 'i1',
              'productId': 'p1',
              'qty': 2,
              'unitPrice': 28000,
              'notes': 'panas',
              'modifiers': [
                {
                  'modifierId': 'm1',
                  'modifierName': 'Oat Milk',
                  'priceAddition': 6000,
                },
              ],
            },
          ],
        },
        const {},
      );

      expect(bill.ticketNumber, 'TB-001');
      expect(bill.orderType, 'Dine-in');
      expect(bill.items, hasLength(1));
      expect(bill.items.first.quantity, 2);
      expect(bill.items.first.notes, 'panas');
      // 22000 base + 6000 modifier reconstructs the original 28000.
      expect(bill.items.first.product.price, 22000);
      expect(bill.items.first.unitPrice, 28000);
    });

    test('normalizeTableName matches common table labels', () {
      expect(PosRepository.normalizeTableName('Meja 04'), '4');
      expect(PosRepository.normalizeTableName('04'), '4');
      expect(PosRepository.normalizeTableName('meja-4'), '4');
      expect(PosRepository.normalizeTableName('Meja 10'), '10');
    });

    test('mapProduct maps basePrice/photoUrl and tolerates null sku', () {
      final p = PosRepository.mapProduct(
        {
          'id': 'p1',
          'name': 'Kopi Susu',
          'sku': null,
          'barcode': '899',
          'basePrice': 22000,
          'categoryId': 'cat_1',
          'isAvailable': false,
          'photoUrl': '/uploads/products/x.jpg',
        },
        categoryName: 'Kopi',
      );
      expect(p.price, 22000);
      expect(p.sku, '');
      expect(p.categoryName, 'Kopi');
      expect(p.isAvailable, isFalse);
      expect(p.imageUrl, '/uploads/products/x.jpg');
    });
  });
}
