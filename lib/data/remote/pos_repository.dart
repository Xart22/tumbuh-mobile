import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/printer/thermal_printer_service.dart';
import '../local/db/app_database.dart';
import '../local/outbox/outbox_dao.dart';
import '../models/cart_item.dart';
import '../models/payment_model.dart';
import '../models/pos_product.dart';
import '../models/printer_config.dart';
import '../models/product_modifier.dart';
import '../../shared/math/order_math.dart';

class ParkedBill {
  final String id;
  final String ticketNumber;
  final String tableNumber;
  final String orderType;
  final String customerName;
  final List<CartItem> items;
  final DateTime parkedAt;

  ParkedBill({
    required this.id,
    required this.ticketNumber,
    required this.tableNumber,
    required this.orderType,
    required this.customerName,
    required this.items,
    required this.parkedAt,
  });
}

class PosRepository {
  final ApiClient apiClient;
  final AppDatabase database;
  final OutboxDao outboxDao;
  final ThermalPrinterService printerService;

  final List<ParkedBill> _parkedBills = [];

  PosRepository({
    required this.apiClient,
    required this.database,
    required this.outboxDao,
    required this.printerService,
  });

  /// Standard Coffee Shop Seed Categories matching Stitch Design
  static const List<PosCategory> defaultCategories = [
    PosCategory(id: 'all', name: 'Semua', icon: '✨', sortOrder: 0),
    PosCategory(id: 'cat_espresso', name: 'Kopi Espresso', icon: '☕', sortOrder: 1),
    PosCategory(id: 'cat_noncoffee', name: 'Non-Coffee', icon: '🍵', sortOrder: 2),
    PosCategory(id: 'cat_food', name: 'Makanan Berat', icon: '🍛', sortOrder: 3),
    PosCategory(id: 'cat_pastry', name: 'Artisan Pastry', icon: '🥐', sortOrder: 4),
  ];

  /// Standard Product Modifiers for Kopi Susu Aren (Stitch Screen 807ee01e063c4635ac5e508aa6a7094f)
  static final List<ModifierGroup> coffeeModifierGroups = [
    const ModifierGroup(
      id: 'cup_size',
      name: '1. PILIHAN UKURAN CUP',
      subtitle: 'WAJIB (PILIH 1)',
      selectionType: ModifierSelectionType.singleRequired,
      isRequired: true,
      minSelection: 1,
      maxSelection: 1,
      options: [
        ModifierOption(id: 'size_reg', name: 'Regular 12oz', priceDelta: 0, subtitle: 'Porsi standar takaran 350ml', isDefault: true),
        ModifierOption(id: 'size_lrg', name: 'Large 16oz', priceDelta: 5000, subtitle: 'Ukuran jumbo cup 480ml'),
      ],
    ),
    const ModifierGroup(
      id: 'sweetness',
      name: '2. TINGKAT GULA / SWEETNESS',
      subtitle: 'WAJIB (PILIH 1)',
      selectionType: ModifierSelectionType.singleRequired,
      isRequired: true,
      minSelection: 1,
      maxSelection: 1,
      options: [
        ModifierOption(id: 'sugar_100', name: 'Normal Sugar', priceDelta: 0, subtitle: '100% (30ml)'),
        ModifierOption(id: 'sugar_50', name: 'Less Sugar', priceDelta: 0, subtitle: '50% (15ml) - Favorit', isDefault: true),
        ModifierOption(id: 'sugar_25', name: 'Low Sugar', priceDelta: 0, subtitle: '25% (7.5ml)'),
        ModifierOption(id: 'sugar_0', name: 'No Sugar', priceDelta: 0, subtitle: '0% (Plain)'),
      ],
    ),
    const ModifierGroup(
      id: 'ice_level',
      name: '3. LEVEL ES BATU',
      subtitle: 'WAJIB (PILIH 1)',
      selectionType: ModifierSelectionType.singleRequired,
      isRequired: true,
      minSelection: 1,
      maxSelection: 1,
      options: [
        ModifierOption(id: 'ice_norm', name: 'Normal Ice', priceDelta: 0, subtitle: '100% Tube', isDefault: true),
        ModifierOption(id: 'ice_less', name: 'Less Ice', priceDelta: 0, subtitle: '50% Cup'),
        ModifierOption(id: 'ice_none', name: 'No Ice', priceDelta: 0, subtitle: 'Chilled cup'),
      ],
    ),
    const ModifierGroup(
      id: 'milk_sub',
      name: '4. SUBSTITUSI SUSU / MILK BASE',
      subtitle: 'WAJIB (PILIH 1)',
      selectionType: ModifierSelectionType.singleRequired,
      isRequired: true,
      minSelection: 1,
      maxSelection: 1,
      options: [
        ModifierOption(id: 'milk_fresh', name: 'Fresh Milk Dairy', priceDelta: 0, subtitle: 'Pasteurisasi', isDefault: true),
        ModifierOption(id: 'milk_oat', name: 'Oat Milk Barista', priceDelta: 6000, subtitle: 'Oatside Creamy Edition'),
        ModifierOption(id: 'milk_almond', name: 'Almond Milk', priceDelta: 6000, subtitle: 'Unsweetened'),
        ModifierOption(id: 'milk_soy', name: 'Soy Milk', priceDelta: 4000, subtitle: 'Organic Soy'),
      ],
    ),
    const ModifierGroup(
      id: 'extra_toppings',
      name: '5. EXTRA TOPPING & SHOT',
      subtitle: 'OPSIONAL (BISA PILIH BANYAK)',
      selectionType: ModifierSelectionType.multiOptional,
      isRequired: false,
      minSelection: 0,
      maxSelection: 4,
      options: [
        ModifierOption(id: 'top_shot', name: 'Extra Shot Espresso', priceDelta: 5000, subtitle: '+30ml Arabica Gayo'),
        ModifierOption(id: 'top_jelly', name: 'Grass Jelly Cincau', priceDelta: 4000, subtitle: 'Herbal kenyal'),
        ModifierOption(id: 'top_boba', name: 'Brown Sugar Boba', priceDelta: 5000, subtitle: 'Chewy tapioka'),
        ModifierOption(id: 'top_caramel', name: 'Caramel Drizzle', priceDelta: 3000, subtitle: 'Saus karamel legit'),
      ],
    ),
  ];

  /// Standard Product Catalog matching Stitch Screen 2d1abb020f314b258eae5cbb582c1616
  static final List<PosProduct> defaultProducts = [
    PosProduct(
      id: 'prod_aren',
      name: 'Kopi Susu Gula Aren',
      description: 'Double espresso, aren organik, fresh milk',
      sku: 'KOP-AREN-01',
      barcode: '8991001001',
      price: 22000,
      categoryId: 'cat_espresso',
      categoryName: 'Kopi Espresso',
      stockQuantity: 42,
      isAvailable: true,
      isBestSeller: true,
      modifierGroups: coffeeModifierGroups,
    ),
    const PosProduct(
      id: 'prod_americano',
      name: 'Americano Iced',
      description: 'Single origin Arabica Gayo, double shot',
      sku: 'KOP-AME-02',
      barcode: '8991001002',
      price: 18000,
      categoryId: 'cat_espresso',
      categoryName: 'Kopi Espresso',
      stockQuantity: 85,
      isAvailable: true,
    ),
    const PosProduct(
      id: 'prod_spanish',
      name: 'Spanish Latte Caramel',
      description: 'Condensed milk & infused caramel syrup',
      sku: 'KOP-SPA-03',
      barcode: '8991001003',
      price: 26000,
      categoryId: 'cat_espresso',
      categoryName: 'Kopi Espresso',
      stockQuantity: 29,
      isAvailable: true,
    ),
    const PosProduct(
      id: 'prod_v60',
      name: 'V60 Flores Bajawa',
      description: 'Notes: Dark chocolate, orange peel, clean',
      sku: 'KOP-MAN-04',
      barcode: '8991001004',
      price: 30000,
      categoryId: 'cat_espresso',
      categoryName: 'Kopi Espresso',
      stockQuantity: 6,
      isAvailable: true,
    ),
    const PosProduct(
      id: 'prod_croissant',
      name: 'Croissant Almond',
      description: 'French butter pastry, roasted almond crust',
      sku: 'PAS-ALM-01',
      barcode: '8991002001',
      price: 28000,
      categoryId: 'cat_pastry',
      categoryName: 'Artisan Pastry',
      stockQuantity: 14,
      isAvailable: true,
    ),
    const PosProduct(
      id: 'prod_matcha',
      name: 'Matcha Latte Uji',
      description: 'Pure Kyoto matcha, creamy oat/fresh milk',
      sku: 'NON-MAT-01',
      barcode: '8991003001',
      price: 26000,
      categoryId: 'cat_noncoffee',
      categoryName: 'Non-Coffee',
      stockQuantity: 38,
      isAvailable: true,
    ),
    const PosProduct(
      id: 'prod_beefbowl',
      name: 'Rice Bowl Beef Blackpepper',
      description: 'Daging sapi tumis lada hitam, telur ceplok',
      sku: 'MAK-BEF-01',
      barcode: '8991004001',
      price: 38000,
      categoryId: 'cat_food',
      categoryName: 'Makanan Berat',
      stockQuantity: 18,
      isAvailable: true,
    ),
    const PosProduct(
      id: 'prod_coldbrew',
      name: 'Cold Brew Sparkling Yuzu',
      description: '16-hr steeping, tonic water & natural yuzu',
      sku: 'KOP-COL-05',
      barcode: '8991001005',
      price: 28000,
      categoryId: 'cat_espresso',
      categoryName: 'Kopi Espresso',
      stockQuantity: 22,
      isAvailable: true,
    ),
  ];

  /// Get Categories (cached or fallback to seed)
  Future<List<PosCategory>> getCategories() async {
    return defaultCategories;
  }

  /// Get Products with category & search filter
  Future<List<PosProduct>> getProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    var result = List<PosProduct>.from(defaultProducts);

    if (categoryId != null && categoryId != 'all') {
      result = result.where((p) => p.categoryId == categoryId).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.barcode != null && p.barcode!.contains(q)) ||
            (p.description != null && p.description!.toLowerCase().contains(q));
      }).toList();
    }

    return result;
  }

  /// Lookup product by Barcode / SKU
  Future<PosProduct?> lookupByCode(String code) async {
    final clean = code.trim().toLowerCase();
    for (final p in defaultProducts) {
      if (p.sku.toLowerCase() == clean || (p.barcode != null && p.barcode!.toLowerCase() == clean)) {
        return p;
      }
    }
    return null;
  }

  /// Park Bill (Hold Bill - F2)
  Future<ParkedBill> parkBill({
    required String tableNumber,
    required String orderType,
    required String customerName,
    required List<CartItem> items,
  }) async {
    final id = const Uuid().v4();
    final ticketNum = 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final bill = ParkedBill(
      id: id,
      ticketNumber: ticketNum,
      tableNumber: tableNumber,
      orderType: orderType,
      customerName: customerName,
      items: items,
      parkedAt: DateTime.now(),
    );
    _parkedBills.add(bill);
    return bill;
  }

  List<ParkedBill> getParkedBills() => List.unmodifiable(_parkedBills);

  void removeParkedBill(String id) {
    _parkedBills.removeWhere((b) => b.id == id);
  }

  /// Submit Order & Process Payment with Server Authority & Offline Outbox Replay
  Future<Map<String, dynamic>> submitOrderAndPayment({
    required String tableNumber,
    required String orderType,
    required String customerName,
    required String cashierName,
    required List<CartItem> items,
    required OrderTotals totals,
    required OrderPaymentDetails payment,
    PrinterDeviceConfig? printerConfig,
  }) async {
    final orderId = 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final idempotencyKey = const Uuid().v4();

    final payload = {
      'orderId': orderId,
      'tableNumber': tableNumber,
      'orderType': orderType,
      'customerName': customerName,
      'cashierName': cashierName,
      'items': items.map((i) => i.toJson()).toList(),
      'totals': {
        'subtotal': totals.subtotal,
        'itemDiscountTotal': totals.itemDiscountTotal,
        'voucherDiscount': totals.voucherDiscount,
        'serviceCharge': totals.serviceCharge,
        'tax': totals.tax,
        'rounding': totals.rounding,
        'grandTotal': totals.grandTotal,
      },
      'payment': payment.toJson(),
      'submittedAt': DateTime.now().toIso8601String(),
    };

    bool isOnlineSuccess = false;
    try {
      final response = await apiClient.dio.post(
        '/pos/orders',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isOnlineSuccess = true;
      }
    } catch (_) {
      // Offline or network error: write to Outbox events queue for idempotent background sync!
      await outboxDao.enqueue(
        endpoint: '/pos/orders',
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
    }


    // Auto-Print Receipt if enabled
    if (payment.printPhysicalReceipt && printerConfig != null) {
      try {
        printerService.generateEscPosReceiptBytes(
          orderId: orderId,
          tableNumber: tableNumber,
          cashierName: cashierName,
          customerName: customerName,
          orderType: orderType,
          items: items,
          totals: totals,
          payment: payment,
          config: printerConfig,
        );
      } catch (_) {
        // Log printer error without failing transaction
      }
    }

    return {
      'orderId': orderId,
      'isOnline': isOnlineSuccess,
      'idempotencyKey': idempotencyKey,
      'grandTotal': totals.grandTotal,
    };
  }
}
