import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tumbuh_mobile/core/network/api_client.dart';
import 'package:tumbuh_mobile/core/printer/thermal_printer_service.dart';
import 'package:tumbuh_mobile/core/security/secure_storage_service.dart';
import 'package:tumbuh_mobile/data/local/db/app_database.dart';
import 'package:tumbuh_mobile/data/local/outbox/outbox_dao.dart';
import 'package:tumbuh_mobile/data/remote/pos_repository.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_bloc.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_event.dart';
import 'package:tumbuh_mobile/features/pos/presentation/screens/pos_tablet_screen.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/payment_modal.dart';
import 'package:tumbuh_mobile/shared/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('PosTabletScreen renders tablet landscape layout with catalog and cart drawer', (WidgetTester tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final outboxDao = OutboxDao(inMemoryDb);
    final apiClient = ApiClient(storage: SecureStorageService());
    final printerService = ThermalPrinterService();
    final posRepository = PosRepository(
      apiClient: apiClient,
      database: inMemoryDb,
      outboxDao: outboxDao,
      printerService: printerService,
    );
    final posBloc = PosBloc(posRepository: posRepository)..add(const PosLoadMenu());

    // 1280x800 Tablet Landscape Viewport
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: posBloc,
        child: MaterialApp(
          theme: AppTheme.darkPosTheme,
          home: const PosTabletScreen(enableQrisTimer: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header elements
    expect(find.text('Tumbuh'), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Kopi Kita - Cabang Tebet'), findsOneWidget);
    expect(find.text('Kasir: Barista Rama (Shift Pagi)'), findsOneWidget);
    expect(find.text('Buka Laci Kas'), findsOneWidget);
    expect(find.text('Ganti Shift'), findsOneWidget);

    // 2. Catalog categories and products
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Kopi Espresso'), findsOneWidget);
    expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
    expect(find.text('Americano Iced'), findsWidgets);

    // 3. Cart ticket drawer (Meja 04, Dine-in, items)
    expect(find.text('Meja 04'), findsOneWidget);
    expect(find.text('Dine-in'), findsOneWidget);
    expect(find.text('Member: Dian P. ⭐'), findsOneWidget);
    expect(find.text('Parkir Bill (F2)'), findsOneWidget);

    // 4. Exact Stitch financial totals (78k - 10k + 6.8k = 74.8k)
    expect(find.text('Subtotal (3 item)'), findsOneWidget);
    expect(find.text('Rp 78.000'), findsOneWidget);
    expect(find.text('Diskon Voucher Member'), findsOneWidget);
    expect(find.text('-Rp 10.000'), findsOneWidget);
    expect(find.text('Pajak Restoran (PB1 10%)'), findsOneWidget);
    expect(find.text('Rp 6.800'), findsOneWidget);
    expect(find.text('Rp 74.800'), findsWidgets);

    // 5. Quick Payment buttons and checkout button
    expect(find.text('💵 Tunai'), findsOneWidget);
    expect(find.text('📱 QRIS'), findsOneWidget);
    expect(find.text('💳 Debit'), findsOneWidget);
    expect(find.text('Lanjut Bayar (Rp 74.800)'), findsOneWidget);

    // 6. Test opening payment modal
    await tester.tap(find.text('Lanjut Bayar (Rp 74.800)'));
    await tester.pumpAndSettle();

    // Verify Payment Modal opened matching Stitch Screen 2b3e8ada336846cd9a08e31d0014dbcf
    expect(find.text('Pembayaran Pesanan'), findsOneWidget);
    expect(find.text('Split Bayar / Pisah Tagihan (2 Metode)'), findsOneWidget);
    expect(find.text('QRIS Dinamis Otomatis'), findsOneWidget);
    expect(find.text('Tunai / Cash Kasir'), findsOneWidget);
    expect(find.text('Konfirmasi Pelunasan & Selesaikan Order (Enter)'), findsOneWidget);

    // Dismiss dialog
    Navigator.of(tester.element(find.byType(PaymentModal))).pop();
    await tester.pumpAndSettle();
  });
}
