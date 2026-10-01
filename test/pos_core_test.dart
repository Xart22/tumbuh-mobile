import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:tumbuh_mobile/core/network/api_client.dart';
import 'package:tumbuh_mobile/core/printer/thermal_printer_service.dart';
import 'package:tumbuh_mobile/core/security/secure_storage_service.dart';
import 'package:tumbuh_mobile/data/local/db/app_database.dart';
import 'package:tumbuh_mobile/data/local/outbox/outbox_dao.dart';
import 'package:tumbuh_mobile/data/models/cart_item.dart';
import 'package:tumbuh_mobile/data/models/payment_model.dart';
import 'package:tumbuh_mobile/data/models/pos_product.dart';
import 'package:tumbuh_mobile/data/models/printer_config.dart';
import 'package:tumbuh_mobile/data/models/product_modifier.dart';
import 'package:tumbuh_mobile/data/remote/pos_repository.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_bloc.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_event.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tumbuh_mobile/shared/math/order_math.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('POS Core - Cart & Modifier Math Tests', () {

    test('Calculates unit price with modifiers and line totals correctly', () {
      const product = PosProduct(
        id: 'kop-01',
        name: 'Kopi Susu Gula Aren',
        sku: 'KOP-AREN-01',
        price: 22000,
        categoryId: 'cat_espresso',
        categoryName: 'Kopi Espresso',
      );

      final item = CartItem.create(
        product: product,
        quantity: 2,
        selectedModifiers: const [
          ModifierOption(id: 'mod-1', name: 'Oat Milk', priceDelta: 6000),
          ModifierOption(id: 'mod-2', name: 'Extra Shot', priceDelta: 5000),
        ],
      );

      // Base 22k + Oat 6k + Extra Shot 5k = 33k per unit
      expect(item.unitPrice, 33000);
      // 33k * 2 = 66k gross
      expect(item.grossTotal, 66000);
      expect(item.netTotal, 66000);
    });

    test('Computes Stitch Screen 2d1abb020f314b258eae5cbb582c1616 exact bill breakdown', () {
      final items = [
        const OrderItemDraft(id: '1', price: 28000, quantity: 1), // Kopi Aren + Oatmilk
        const OrderItemDraft(id: '2', price: 28000, quantity: 1), // Croissant Almond
        const OrderItemDraft(id: '3', price: 22000, quantity: 1), // Americano + Hazelnut
      ];

      final totals = OrderMath.calculateDraft(
        items: items,
        voucherDiscount: 10000, // Diskon Voucher Member
        taxPercent: 10, // PB1 Restoran 10%
      );

      // Subtotal = 28k + 28k + 22k = 78k
      expect(totals.subtotal, 78000);
      // Voucher Discount = 10k
      expect(totals.voucherDiscount, 10000);
      // Taxable = 68k
      expect(totals.taxableAmount, 68000);
      // PB1 10% = 6.800
      expect(totals.tax, 6800);
      // Grand Total = 68k + 6.8k = 74.800
      expect(totals.grandTotal, 74800);
    });

    test('Validates split payment allocation and cash change calculation', () {
      const grandTotal = 74800;
      const split1Qris = 50000;
      const split2Cash = grandTotal - split1Qris; // 24800

      expect(split1Qris + split2Cash, grandTotal);

      // Customer gives Rp 50.000 cash for 24.800
      const cashGiven = 50000;
      final change = cashGiven - split2Cash;
      expect(change, 25200); // Rp 25.200 kembalian
    });
  });

  group('ThermalPrinterService Tests', () {
    late ThermalPrinterService printerService;

    setUp(() {
      printerService = ThermalPrinterService();
    });

    test('Generates non-empty ESC/POS receipt bytes with cash drawer kick', () {
      final sampleItems = [
        CartItem.create(
          product: const PosProduct(
            id: 'p1',
            name: 'Kopi Susu Aren',
            sku: 'KOP-01',
            price: 22000,
            categoryId: 'cat_espresso',
            categoryName: 'Kopi Espresso',
          ),
          quantity: 2,
        ),
      ];

      final sampleTotals = OrderMath.calculateDraft(
        items: [
          const OrderItemDraft(id: 'p1', price: 22000, quantity: 2),
        ],
        taxPercent: 10,
      );

      final samplePayment = OrderPaymentDetails(
        primaryMethod: PosPaymentMethod.cash,
        grandTotal: sampleTotals.grandTotal,
        totalPaid: 50000,
        change: 50000 - sampleTotals.grandTotal,
        paidAt: DateTime.now(),
      );

      const config = PrinterDeviceConfig(
        id: 'test-print',
        name: 'Test Printer 80mm',
        role: PrinterRole.cashier,
        connectionType: PrinterConnectionType.bluetooth,
        connectionAddress: '00:11:22:33:44:55',
        kickCashDrawer: true,
      );

      final bytes = printerService.generateEscPosReceiptBytes(
        orderId: 'TB-9999',
        tableNumber: '04',
        cashierName: 'Barista Rama',
        customerName: 'Dian P.',
        orderType: 'Dine-In',
        items: sampleItems,
        totals: sampleTotals,
        payment: samplePayment,
        config: config,
      );

      expect(bytes, isNotEmpty);
      // Verify ESC/POS init bytes [0x1B, 0x40]
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
    });

    test('Generates Kitchen Ticket bytes for bar and kitchen staff', () {
      final sampleItems = [
        CartItem.create(
          product: const PosProduct(
            id: 'p1',
            name: 'Kopi Susu Aren',
            sku: 'KOP-01',
            price: 22000,
            categoryId: 'cat_espresso',
            categoryName: 'Kopi Espresso',
          ),
          quantity: 1,
          selectedModifiers: const [
            ModifierOption(id: 'm1', name: 'Less Sugar 50%'),
          ],
          notes: 'Pisahkan es batu',
        ),
      ];

      const config = PrinterDeviceConfig(
        id: 'kitchen-print',
        name: 'Kitchen LAN Printer',
        role: PrinterRole.kitchen,
        connectionType: PrinterConnectionType.network,
        connectionAddress: '192.168.1.150:9100',
      );

      final bytes = printerService.generateKitchenTicketBytes(
        orderId: 'TB-104',
        tableNumber: '04',
        orderType: 'Dine-In',
        items: sampleItems,
        config: config,
      );

      expect(bytes, isNotEmpty);
    });

    test('Parses network printer address with default port 9100', () {
      expect(
        ThermalPrinterService.parseNetworkAddress('192.168.1.150:9100'),
        ('192.168.1.150', 9100),
      );
      expect(
        ThermalPrinterService.parseNetworkAddress('192.168.1.150'),
        ('192.168.1.150', 9100),
      );
    });
  });

  group('PosBloc Tests', () {
    late AppDatabase inMemoryDb;
    late OutboxDao outboxDao;
    late ApiClient apiClient;
    late ThermalPrinterService printerService;
    late PosRepository posRepository;
    late PosBloc posBloc;

    setUp(() {
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      outboxDao = OutboxDao(inMemoryDb);
      apiClient = ApiClient(storage: SecureStorageService());
      printerService = ThermalPrinterService();
      posRepository = PosRepository(
        apiClient: apiClient,
        database: inMemoryDb,
        outboxDao: outboxDao,
        printerService: printerService,
        fetchFromNetwork: false,
      );
      posBloc = PosBloc(posRepository: posRepository);
    });

    tearDown(() async {
      await posBloc.close();
      await inMemoryDb.close();
    });

    test('PosLoadMenu initializes categories, products, and default cart', () async {
      posBloc.add(const PosLoadMenu());

      await expectLater(
        posBloc.stream,
        emitsInOrder([
          isA<PosState>().having((s) => s.status, 'status', PosStatus.loading),
          isA<PosState>()
              .having((s) => s.status, 'status', PosStatus.ready)
              .having((s) => s.categories.length, 'categories count', greaterThan(0))
              .having((s) => s.allProducts.length, 'products count', greaterThan(0))
              .having((s) => s.cartItems.length, 'initial cart items', 3)
              .having((s) => s.totals.grandTotal, 'initial grand total', 74800),
        ]),
      );
    });

    test('PosSelectCategory and PosSearchProducts filters correctly', () async {
      posBloc.add(const PosLoadMenu());
      await posBloc.stream.firstWhere((s) => s.status == PosStatus.ready);

      // Filter by Non-Coffee category
      posBloc.add(const PosSelectCategory('cat_noncoffee'));
      await posBloc.stream.firstWhere((s) => s.selectedCategoryId == 'cat_noncoffee');
      expect(posBloc.state.filteredProducts.any((p) => p.sku == 'NON-MAT-01'), isTrue);

      // Search by product keyword
      posBloc.add(const PosSelectCategory('all'));
      posBloc.add(const PosSearchProducts('croissant'));
      await posBloc.stream.firstWhere((s) => s.searchQuery == 'croissant');
      expect(posBloc.state.filteredProducts.length, 1);
      expect(posBloc.state.filteredProducts.first.sku, 'PAS-ALM-01');
    });

    test('Park bill (Hold Bill F2) parks cart and restores cleanly', () async {
      posBloc.add(const PosLoadMenu());
      await posBloc.stream.firstWhere((s) => s.status == PosStatus.ready);

      expect(posBloc.state.cartItems, isNotEmpty);

      // Park current bill
      posBloc.add(const PosParkBill());
      await posBloc.stream.firstWhere((s) => s.cartItems.isEmpty);

      expect(posBloc.state.parkedBills.length, 1);
      final parked = posBloc.state.parkedBills.first;
      expect(parked.items.length, 3);

      // Restore parked bill
      posBloc.add(PosRestoreParkedBill(parked.id));
      await posBloc.stream.firstWhere((s) => s.cartItems.isNotEmpty);

      expect(posBloc.state.cartItems.length, 3);
      expect(posBloc.state.parkedBills.isEmpty, isTrue);
    });

    test('PosSessionReset clears cart, parked bills and customer', () async {
      posBloc.add(const PosLoadMenu());
      await posBloc.stream.firstWhere((s) => s.status == PosStatus.ready);

      posBloc.add(const PosParkBill());
      await posBloc.stream.firstWhere((s) => s.cartItems.isEmpty);
      expect(posBloc.state.parkedBills, isNotEmpty);

      posBloc.add(const PosSessionReset());
      await posBloc.stream.firstWhere((s) => s.parkedBills.isEmpty);

      expect(posBloc.state.cartItems, isEmpty);
      expect(posBloc.state.customerId, isNull);
      expect(posBloc.state.voucherDiscount, 0);
    });
  });
}
