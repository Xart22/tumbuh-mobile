import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/device/device_service.dart';
import 'core/network/api_client.dart';
import 'core/printer/thermal_printer_service.dart';
import 'core/security/secure_storage_service.dart';
import 'data/local/db/app_database.dart';
import 'data/local/outbox/outbox_dao.dart';
import 'data/local/sync/sync_engine.dart';
import 'data/remote/auth_repository.dart';
import 'data/remote/pos_repository.dart';
import 'data/remote/shift_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/pos/bloc/pos_bloc.dart';
import 'features/pos/bloc/pos_event.dart';
import 'features/shift/bloc/shift_bloc.dart';
import 'routing/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Core security & hardware identification
  final secureStorage = SecureStorageService();
  final deviceService = DeviceService(storage: secureStorage);
  await deviceService.getOrCreateDeviceId();

  // 2. Local Database & Outbox Queue
  final appDb = AppDatabase();
  final outboxDao = OutboxDao(appDb);

  // 3. Network client with auto-idempotency & 401 handling
  final apiClient = ApiClient(
    storage: secureStorage,
    onUnauthorized: () {
      // Handle global 401 logout
    },
  );

  // 4. Background Sync Engine for offline-first transactional replay
  final syncEngine = SyncEngine(
    outboxDao: outboxDao,
    apiClient: apiClient,
  );
  syncEngine.init();

  // 5. Hardware Printer Service
  final printerService = ThermalPrinterService();

  // 6. Repositories
  final authRepository = AuthRepository(
    apiClient: apiClient,
    storage: secureStorage,
    deviceService: deviceService,
  );

  final shiftRepository = ShiftRepository(
    apiClient: apiClient,
    storage: secureStorage,
    deviceService: deviceService,
    outboxDao: outboxDao,
  );

  final posRepository = PosRepository(
    apiClient: apiClient,
    database: appDb,
    outboxDao: outboxDao,
    printerService: printerService,
  );

  runApp(
    TumbuhApp(
      secureStorage: secureStorage,
      appDb: appDb,
      outboxDao: outboxDao,
      apiClient: apiClient,
      syncEngine: syncEngine,
      authRepository: authRepository,
      shiftRepository: shiftRepository,
      posRepository: posRepository,
      printerService: printerService,
    ),
  );
}

class TumbuhApp extends StatelessWidget {
  final SecureStorageService secureStorage;
  final AppDatabase appDb;
  final OutboxDao outboxDao;
  final ApiClient apiClient;
  final SyncEngine syncEngine;
  final AuthRepository authRepository;
  final ShiftRepository shiftRepository;
  final PosRepository posRepository;
  final ThermalPrinterService printerService;

  const TumbuhApp({
    super.key,
    required this.secureStorage,
    required this.appDb,
    required this.outboxDao,
    required this.apiClient,
    required this.syncEngine,
    required this.authRepository,
    required this.shiftRepository,
    required this.posRepository,
    required this.printerService,
  });

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            storage: secureStorage,
          )..add(AuthCheckStatus()),
        ),
        BlocProvider<ShiftBloc>(
          create: (context) => ShiftBloc(
            shiftRepository: shiftRepository,
          ),
        ),
        BlocProvider<PosBloc>(
          create: (context) => PosBloc(
            posRepository: posRepository,
          )..add(const PosLoadMenu()),
        ),
      ],

      child: MaterialApp.router(
        title: 'Tumbuh POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkPosTheme,
        themeMode: ThemeMode.dark, // Default to dark tactile mode for POS/KDS
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
