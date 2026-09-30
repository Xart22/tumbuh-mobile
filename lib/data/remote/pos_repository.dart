import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/printer/thermal_printer_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../local/db/app_database.dart';
import '../local/outbox/outbox_dao.dart';
import '../models/cart_item.dart';
import '../models/customer_summary.dart';
import '../models/outlet_pricing.dart';
import '../models/payment_model.dart';
import '../models/pos_product.dart';
import '../models/printer_config.dart';
import '../models/product_modifier.dart';
import '../models/voucher_validation.dart';
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
  final SecureStorageService? storage;

  /// When false, catalog reads skip the backend and use cache/seed only.
  /// Tests set this false so a developer's local backend can't alter results.
  final bool fetchFromNetwork;

  final List<ParkedBill> _parkedBills = [];

  PosRepository({
    required this.apiClient,
    required this.database,
    required this.outboxDao,
    required this.printerService,
    this.storage,
    this.fetchFromNetwork = true,
  });

  /// Cached outlet pricing (tax/service/rounding), or null when unavailable.
  Future<OutletPricing?> getOutletPricing() async {
    final json = await storage?.getOutletPricing();
    if (json == null || json.isEmpty) return null;
    try {
      return OutletPricing.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

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

  @visibleForTesting
  static PosCategory mapCategory(Map<String, dynamic> json) => PosCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: '☕',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  @visibleForTesting
  static PosProduct mapProduct(
    Map<String, dynamic> json, {
    String categoryName = 'Lainnya',
  }) {
    return PosProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: (json['sku'] as String?) ?? '',
      barcode: json['barcode'] as String?,
      price: (json['basePrice'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] as String?) ?? '',
      categoryName: categoryName,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['photoUrl'] as String?,
    );
  }

  /// Normalizes a table label so "Meja 04", "04" and "meja-4" all match.
  @visibleForTesting
  static String normalizeTableName(String value) {
    var s = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (s.startsWith('meja')) s = s.substring(4);
    s = s.replaceFirst(RegExp(r'^0+'), '');
    return s.isEmpty ? '0' : s;
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : Map<String, dynamic>.from(value as Map);

  static String _mapOrderType(String orderType) {
    final s = orderType.toLowerCase();
    if (s.contains('delivery')) return 'delivery';
    if (s.contains('take') || s.contains('away') || s.contains('bungkus')) {
      return 'take_away';
    }
    return 'dine_in';
  }

  static String _mapPaymentMethod(PosPaymentMethod method) {
    switch (method) {
      case PosPaymentMethod.cash:
        return 'cash';
      case PosPaymentMethod.qris:
        return 'qris_dynamic';
      case PosPaymentMethod.debit:
        return 'debit';
      case PosPaymentMethod.transfer:
        // Backend has no bank-transfer method yet; treat as immediate non-cash.
        return 'debit';
    }
  }

  /// Backend CreatePaymentDto body, without `orderId` (added at send time).
  static Map<String, dynamic> _paymentBody(OrderPaymentDetails payment) {
    if (payment.isSplitPayment && payment.splits.isNotEmpty) {
      return {
        'payments': payment.splits
            .map((s) => {
                  'method': _mapPaymentMethod(s.method),
                  'amount': s.amount,
                })
            .toList(),
      };
    }
    return {
      'method': _mapPaymentMethod(payment.primaryMethod),
      'amount': payment.grandTotal,
    };
  }

  Future<void> _createPayment(String orderId, OrderPaymentDetails payment) async {
    await apiClient.dio.post(
      '/v1/payments',
      data: {'orderId': orderId, ..._paymentBody(payment)},
      options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
    );
  }

  static bool _isOfflineError(Object error) {
    if (error is NetworkOfflineException) return true;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.error is NetworkOfflineException;
    }
    return false;
  }

  List<PosCategory> _categoriesFromEnvelope(dynamic data) {
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>;
    return items
        .map((e) => mapCategory(e as Map<String, dynamic>))
        .toList();
  }

  List<PosProduct> _productsFromEnvelope(
    dynamic data,
    Map<String, String> categoryNames,
  ) {
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>;
    return items.map((e) {
      final json = e as Map<String, dynamic>;
      return mapProduct(
        json,
        categoryName: categoryNames[json['categoryId']] ?? 'Lainnya',
      );
    }).toList();
  }

  /// Get Categories: backend cache -> Drift cache -> bundled seed.
  Future<List<PosCategory>> getCategories() async {
    if (fetchFromNetwork) {
      try {
        final res = await apiClient.getWithRetry(
          '/v1/categories',
          queryParameters: {'limit': 100},
        );
        final categories = _categoriesFromEnvelope(res.data);
        await _cacheCategories(categories);
        return categories;
      } catch (_) {
        // fall through to cache/seed below
      }
    }

    final cached = await _readCachedCategories();
    return cached.isNotEmpty ? cached : defaultCategories;
  }

  /// Get Products with category & search filter
  Future<List<PosProduct>> getProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    var result = await _loadAllProducts();

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

  Future<List<PosProduct>> _loadAllProducts() async {
    if (fetchFromNetwork) {
      try {
        final categories = await getCategories();
        final names = {for (final c in categories) c.id: c.name};
        final res = await apiClient.getWithRetry(
          '/v1/products',
          queryParameters: {'limit': 100},
        );
        final products = _productsFromEnvelope(res.data, names);
        await _cacheProducts(products);
        return products;
      } catch (_) {
        // fall through to cache/seed below
      }
    }

    final cached = await _readCachedProducts();
    return cached.isNotEmpty ? cached : defaultProducts;
  }

  /// Searches CRM customers. Backend: `GET /v1/customers?search=`.
  Future<List<CustomerSummary>> searchCustomers(String query) async {
    try {
      final res = await apiClient.getWithRetry(
        '/v1/customers',
        queryParameters: {
          'limit': 20,
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final items = (res.data as Map<String, dynamic>)['items'] as List<dynamic>;
      return items
          .map((e) => CustomerSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Validates a voucher code. Backend: `POST /v1/vouchers/validate`.
  /// Throws an [ApiException] (with the backend message) when invalid.
  Future<VoucherValidation> validateVoucher({
    required String code,
    required int orderTotal,
  }) async {
    final res = await apiClient.dio.post(
      '/v1/vouchers/validate',
      data: {'code': code, 'orderTotal': orderTotal},
    );
    return VoucherValidation.fromJson(_asMap(res.data));
  }

  /// Lookup product by Barcode / SKU: backend exact match -> local catalog.
  Future<PosProduct?> lookupByCode(String code) async {
    if (fetchFromNetwork) {
      try {
        final res = await apiClient.dio.get(
          '/v1/products/lookup',
          queryParameters: {'code': code},
        );
        final json = res.data as Map<String, dynamic>;
        final category = json['category'] as String?;
        return mapProduct(
          json,
          categoryName: category ?? 'Lainnya',
        );
      } catch (_) {
        // offline / not found: fall back to local catalog
      }
    }

    final clean = code.trim().toLowerCase();
    final local = await _loadAllProducts();
    for (final p in local) {
      if (p.sku.toLowerCase() == clean ||
          (p.barcode != null && p.barcode!.toLowerCase() == clean)) {
        return p;
      }
    }
    return null;
  }

  Future<void> _cacheCategories(List<PosCategory> categories) async {
    await database.batch((batch) {
      batch.deleteAll(database.cachedCategories);
      batch.insertAll(
        database.cachedCategories,
        categories
            .map((c) => CachedCategoriesCompanion.insert(
                  id: c.id,
                  name: c.name,
                  sortOrder: Value(c.sortOrder),
                  icon: Value(c.icon),
                  updatedAt: DateTime.now(),
                ))
            .toList(),
      );
    });
  }

  Future<List<PosCategory>> _readCachedCategories() async {
    final rows = await database.select(database.cachedCategories).get();
    return rows
        .map((r) => PosCategory(
              id: r.id,
              name: r.name,
              icon: r.icon ?? '☕',
              sortOrder: r.sortOrder,
            ))
        .toList();
  }

  Future<void> _cacheProducts(List<PosProduct> products) async {
    await database.batch((batch) {
      batch.deleteAll(database.cachedProducts);
      batch.insertAll(
        database.cachedProducts,
        products
            .map((p) => CachedProductsCompanion.insert(
                  id: p.id,
                  categoryId: p.categoryId,
                  name: p.name,
                  sku: Value(p.sku),
                  barcode: Value(p.barcode),
                  price: p.price,
                  costPrice: Value(p.costPrice),
                  imageUrl: Value(p.imageUrl),
                  stockQuantity: Value(p.stockQuantity),
                  isAvailable: Value(p.isAvailable),
                  updatedAt: DateTime.now(),
                ))
            .toList(),
      );
    });
  }

  Future<List<PosProduct>> _readCachedProducts() async {
    final rows = await database.select(database.cachedProducts).get();
    final names = {
      for (final c in await _readCachedCategories()) c.id: c.name,
    };
    return rows
        .map((r) => PosProduct(
              id: r.id,
              name: r.name,
              description: null,
              sku: r.sku ?? '',
              barcode: r.barcode,
              price: r.price,
              costPrice: r.costPrice,
              categoryId: r.categoryId,
              categoryName: names[r.categoryId] ?? 'Lainnya',
              stockQuantity: r.stockQuantity,
              isAvailable: r.isAvailable,
              imageUrl: r.imageUrl,
            ))
        .toList();
  }

  Future<Map<String, String>> _loadTablesByName() async {
    if (fetchFromNetwork) {
      try {
        final res = await apiClient.getWithRetry(
          '/v1/tables',
          queryParameters: {'limit': 100},
        );
        final items = (res.data as Map<String, dynamic>)['items'] as List<dynamic>;
        final tables = items
            .map((e) => (
                  id: (e as Map<String, dynamic>)['id'] as String,
                  name: e['name'] as String,
                  areaId: e['areaId'] as String?,
                  status: e['status'] as String?,
                ))
            .toList();
        await _cacheTables(tables);
        return {
          for (final t in tables) normalizeTableName(t.name): t.id,
        };
      } catch (_) {
        // fall through to cache
      }
    }

    final rows = await database.select(database.cachedTables).get();
    return {for (final r in rows) normalizeTableName(r.name): r.id};
  }

  /// Resolves a POS table label (e.g. "04") to the backend table UUID.
  Future<String?> resolveTableId(String tableNumber) async {
    final byName = await _loadTablesByName();
    return byName[normalizeTableName(tableNumber)];
  }

  Future<void> _cacheTables(
    List<({String id, String name, String? areaId, String? status})> tables,
  ) async {
    await database.batch((batch) {
      batch.deleteAll(database.cachedTables);
      batch.insertAll(
        database.cachedTables,
        tables
            .map((t) => CachedTablesCompanion.insert(
                  id: t.id,
                  name: t.name,
                  areaId: Value(t.areaId),
                  status: Value(t.status),
                  updatedAt: DateTime.now(),
                ))
            .toList(),
      );
    });
  }

  List<Map<String, dynamic>> _orderItemsPayload(List<CartItem> items) => items
      .map((i) => {
            'productId': i.product.id,
            'qty': i.quantity,
            'unitPrice': i.unitPrice,
            if (i.notes != null && i.notes!.isNotEmpty) 'notes': i.notes,
          })
      .toList();

  Future<String?> _resolveDineInTableId(String tableNumber, String orderType) {
    if (_mapOrderType(orderType) != 'dine_in') return Future.value(null);
    return resolveTableId(tableNumber);
  }

  /// Park Bill (Hold Bill - F2). Creates a held order server-side; falls back
  /// to the in-memory list when offline.
  Future<ParkedBill> parkBill({
    required String tableNumber,
    required String orderType,
    required String customerName,
    required List<CartItem> items,
  }) async {
    final fallback = ParkedBill(
      id: const Uuid().v4(),
      ticketNumber: 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      tableNumber: tableNumber,
      orderType: orderType,
      customerName: customerName,
      items: items,
      parkedAt: DateTime.now(),
    );

    if (!fetchFromNetwork) {
      _parkedBills.add(fallback);
      return fallback;
    }

    try {
      final tableId = await _resolveDineInTableId(tableNumber, orderType);
      final response = await apiClient.dio.post(
        '/v1/orders',
        data: {
          'orderType': _mapOrderType(orderType),
          'items': _orderItemsPayload(items),
          'tableId': ?tableId,
          'park': true,
        },
        options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
      );
      final created = _asMap(response.data);
      final bill = ParkedBill(
        id: created['id'] as String? ?? fallback.id,
        ticketNumber: created['orderNumber'] as String? ?? fallback.ticketNumber,
        tableNumber: tableNumber,
        orderType: orderType,
        customerName: customerName,
        items: items,
        parkedAt: DateTime.tryParse(created['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
      _parkedBills.add(bill);
      return bill;
    } catch (_) {
      _parkedBills.add(fallback);
      return fallback;
    }
  }

  /// Fetches held orders from the backend and refreshes the local cache.
  Future<List<ParkedBill>> fetchParkedBills() async {
    if (!fetchFromNetwork) return List.unmodifiable(_parkedBills);
    try {
      final res = await apiClient.getWithRetry(
        '/v1/orders',
        queryParameters: {'status': 'held'},
      );
      final rows = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
      final products = await _loadAllProducts();
      final byId = {for (final p in products) p.id: p};

      final bills = rows.map((row) => parkedBillFromOrder(row, byId)).toList();
      _parkedBills
        ..clear()
        ..addAll(bills);
      return bills;
    } catch (_) {
      return List.unmodifiable(_parkedBills);
    }
  }

  @visibleForTesting
  static ParkedBill parkedBillFromOrder(
    Map<String, dynamic> row,
    Map<String, PosProduct> productsById,
  ) {
    final items = ((row['items'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => cartItemFromOrderItem(item, productsById))
        .toList();

    return ParkedBill(
      id: row['id'] as String,
      ticketNumber: row['orderNumber'] as String? ?? '-',
      tableNumber: row['tableNumber'] as String? ?? '-',
      orderType: _orderTypeToDisplay(row['orderType'] as String? ?? 'dine_in'),
      customerName: row['customerName'] as String? ?? 'Tamu',
      items: items,
      parkedAt:
          DateTime.tryParse(row['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @visibleForTesting
  static CartItem cartItemFromOrderItem(
    Map<String, dynamic> item,
    Map<String, PosProduct> productsById,
  ) {
    final productId = item['productId'] as String;
    final unitPrice = (item['unitPrice'] as num?)?.toInt() ?? 0;

    final modifiers = ((item['modifiers'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((m) => ModifierOption(
              id: m['modifierId'] as String? ?? '',
              name: m['modifierName'] as String? ?? 'Modifier',
              priceDelta: (m['priceAddition'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    final modifierSum =
        modifiers.fold<int>(0, (sum, m) => sum + m.priceDelta);

    final catalogProduct = productsById[productId];
    final product = catalogProduct ??
        PosProduct(
          id: productId,
          name: item['productName'] as String? ?? 'Produk',
          sku: '',
          price: unitPrice - modifierSum,
          categoryId: '',
          categoryName: 'Lainnya',
        );

    return CartItem(
      id: item['id'] as String,
      product: product,
      selectedModifiers: modifiers,
      quantity: (item['qty'] as num?)?.toInt() ?? 1,
      notes: item['notes'] as String?,
    );
  }

  static String _orderTypeToDisplay(String orderType) {
    switch (orderType) {
      case 'take_away':
        return 'Takeaway';
      case 'delivery':
        return 'Delivery';
      default:
        return 'Dine-in';
    }
  }

  List<ParkedBill> getParkedBills() => List.unmodifiable(_parkedBills);

  /// Resume a parked bill: unhold server-side (best-effort) and drop locally.
  Future<void> resumeParkedBill(String id) async {
    if (fetchFromNetwork) {
      try {
        await apiClient.dio.post(
          '/v1/orders/$id/unhold',
          options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
        );
      } catch (_) {
        // Offline: local-only parked bills still restore.
      }
    }
    _parkedBills.removeWhere((b) => b.id == id);
  }

  Future<void> cancelParkedBill(String id) async {
    if (fetchFromNetwork) {
      try {
        await apiClient.dio.post(
          '/v1/orders/$id/cancel',
          options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
        );
      } catch (_) {
        // ignore; still remove locally
      }
    }
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
    String? customerId,
    PrinterDeviceConfig? printerConfig,
  }) async {
    final orderId = 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final idempotencyKey = const Uuid().v4();

    // Backend CreateOrderDto: orderType enum + items (productId/qty/unitPrice).
    // Modifier selections are folded into unitPrice (see CartItem.unitPrice).
    final payload = {
      'orderType': _mapOrderType(orderType),
      'items': _orderItemsPayload(items),
      if (totals.totalDiscount > 0) 'discountAmount': totals.totalDiscount,
      if (totals.totalDiscount > 0) 'discountName': 'Diskon',
      'customerId': ?customerId,
    };

    final tableId = await _resolveDineInTableId(tableNumber, orderType);
    if (tableId != null) payload['tableId'] = tableId;

    bool isOnlineSuccess = false;
    String? serverOrderId;
    try {
      final response = await apiClient.dio.post(
        '/v1/orders',
        data: payload,
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isOnlineSuccess = true;
        // Order exists server-side now; record the payment against its id.
        final created = response.data;
        if (created is Map && created['id'] is String) {
          serverOrderId = created['id'] as String;
          await _createPayment(serverOrderId, payment);
        }
      }
    } catch (e) {
      // Only queue when the request never reached the server; a validation or
      // other 4xx must surface instead of being replayed forever.
      if (!_isOfflineError(e)) rethrow;
      await outboxDao.enqueue(
        endpoint: '/v1/orders',
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
        // Chain the payment once the order is replayed and its id is known.
        followUp: {
          'endpoint': '/v1/payments',
          'method': 'POST',
          'body': _paymentBody(payment),
        },
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
      'serverOrderId': serverOrderId,
      'isOnline': isOnlineSuccess,
      'idempotencyKey': idempotencyKey,
      'grandTotal': totals.grandTotal,
    };
  }
}
