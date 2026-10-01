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
      fetchFromNetwork: false,
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
    expect(find.text('Kasir: Kasir'), findsOneWidget);
    expect(find.text('Buka Laci Kas'), findsOneWidget);
    expect(find.text('Ganti Shift'), findsOneWidget);

    // 2. Catalog categories and products
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Kopi Espresso'), findsOneWidget);
    expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
    expect(find.text('Americano Iced'), findsWidgets);

    // 3. Cart drawer starts empty (no fabricated demo order)
    expect(find.text('Meja -'), findsOneWidget);
    expect(find.text('Dine-in'), findsOneWidget);
    expect(find.text('Tambah Pelanggan'), findsOneWidget);
    expect(find.text('Parkir Bill (F2)'), findsOneWidget);
    expect(find.text('Subtotal (0 item)'), findsOneWidget);

    // 4. Quick payment buttons and checkout button
    expect(find.text('💵 Tunai'), findsOneWidget);
    expect(find.text('📱 QRIS'), findsOneWidget);
    expect(find.text('💳 Debit'), findsOneWidget);
    expect(find.text('Lanjut Bayar (Rp 0)'), findsOneWidget);
  });
}
