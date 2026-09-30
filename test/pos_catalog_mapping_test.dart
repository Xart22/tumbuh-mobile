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
