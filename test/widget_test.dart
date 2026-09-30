import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:tumbuh_mobile/core/device/device_service.dart';
import 'package:tumbuh_mobile/core/security/secure_storage_service.dart';
import 'package:tumbuh_mobile/core/network/api_client.dart';
import 'package:tumbuh_mobile/data/local/db/app_database.dart';
import 'package:tumbuh_mobile/data/local/outbox/outbox_dao.dart';
import 'package:tumbuh_mobile/data/local/sync/sync_engine.dart';
import 'package:tumbuh_mobile/core/printer/thermal_printer_service.dart';
import 'package:tumbuh_mobile/data/remote/auth_repository.dart';
import 'package:tumbuh_mobile/data/remote/pos_repository.dart';
import 'package:tumbuh_mobile/data/remote/shift_repository.dart';
import 'package:tumbuh_mobile/main.dart';


void main() {
  testWidgets('TumbuhApp initializes and renders root screen', (WidgetTester tester) async {
    final storage = SecureStorageService();
    final deviceService = DeviceService(storage: storage);
    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final outboxDao = OutboxDao(inMemoryDb);
    final apiClient = ApiClient(storage: storage);
    final syncEngine = SyncEngine(outboxDao: outboxDao, apiClient: apiClient);

    final authRepository = AuthRepository(
      apiClient: apiClient,
      storage: storage,
      deviceService: deviceService,
    );

    final shiftRepository = ShiftRepository(
      apiClient: apiClient,
      storage: storage,
      deviceService: deviceService,
      outboxDao: outboxDao,
    );

    final printerService = ThermalPrinterService();
    final posRepository = PosRepository(
      apiClient: apiClient,
      database: inMemoryDb,
      outboxDao: outboxDao,
      printerService: printerService,
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      TumbuhApp(
        secureStorage: storage,
        appDb: inMemoryDb,
        outboxDao: outboxDao,
        apiClient: apiClient,
        syncEngine: syncEngine,
        authRepository: authRepository,
        shiftRepository: shiftRepository,
        posRepository: posRepository,
        printerService: printerService,
      ),
    );


    await tester.pump();

    // Verify initial screen (Kasir login screen) renders
    expect(find.text('Tumbuh'), findsOneWidget);
    expect(find.text('Masukkan 6 Digit PIN Kasir'), findsOneWidget);
    expect(find.text('Barista Rama'), findsWidgets);

    await inMemoryDb.close();
  });
}
