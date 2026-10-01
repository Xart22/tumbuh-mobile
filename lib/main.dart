import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/device/device_service.dart';
import 'core/network/api_client.dart';
import 'core/printer/thermal_printer_service.dart';
import 'core/security/secure_storage_service.dart';
import 'core/session/session_reset.dart';
import 'data/local/db/app_database.dart';
import 'data/local/outbox/outbox_dao.dart';
import 'data/local/sync/sync_engine.dart';
import 'data/remote/auth_repository.dart';
import 'data/remote/kitchen_repository.dart';
import 'data/remote/orders_repository.dart';
import 'data/remote/owner_repository.dart';
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

  // 3. Router (shared so a global 401 can bounce back to login)
  final router = AppRouter.createRouter();

  // 4. Network client with auto-idempotency & 401 handling
  final apiClient = ApiClient(
    storage: secureStorage,
    onUnauthorized: () {
      SessionReset.instance.fire();
      router.go(AppRouter.loginKasir);
    },
  );

  // 5. Background Sync Engine for offline-first transactional replay
  final syncEngine = SyncEngine(
    outboxDao: outboxDao,
    apiClient: apiClient,
  );
  syncEngine.init();

  // 6. Hardware Printer Service
  final printerService = ThermalPrinterService();

  // 7. Repositories
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
    storage: secureStorage,
  );

  final app = TumbuhApp(
    router: router,
    deviceService: deviceService,
    secureStorage: secureStorage,
    appDb: appDb,
    outboxDao: outboxDao,
    apiClient: apiClient,
    syncEngine: syncEngine,
    authRepository: authRepository,
    shiftRepository: shiftRepository,
    posRepository: posRepository,
    printerService: printerService,
  );

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isEmpty) {
    runApp(app);
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment = const String.fromEnvironment(
          'ENVIRONMENT',
          defaultValue: 'production',
        );
      },
      appRunner: () => runApp(app),
    );
  }
}

class TumbuhApp extends StatelessWidget {
  final GoRouter? router;
  final DeviceService? deviceService;
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
    this.router,
    this.deviceService,
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
    final appRouter = router ?? AppRouter.createRouter();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<KitchenRepository>(
          create: (_) => KitchenRepository(apiClient: apiClient),
        ),
        RepositoryProvider<OwnerRepository>(
          create: (_) => OwnerRepository(apiClient: apiClient),
        ),
        RepositoryProvider<OrdersRepository>(
          create: (_) => OrdersRepository(
            apiClient: apiClient,
            outboxDao: outboxDao,
          ),
        ),
        if (deviceService != null)
          RepositoryProvider<DeviceService>(create: (_) => deviceService!),
      ],
      child: MultiBlocProvider(
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

      child: _SessionResetListener(
      child: MaterialApp.router(
        title: 'Tumbuh POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkPosTheme,
        themeMode: ThemeMode.dark, // Default to dark tactile mode for POS/KDS
        routerConfig: appRouter,
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
      ),
      ),
    );
  }
}

/// Listens for a global session reset (API 401) and clears per-session state.
class _SessionResetListener extends StatefulWidget {
  final Widget child;
  const _SessionResetListener({required this.child});

  @override
  State<_SessionResetListener> createState() => _SessionResetListenerState();
}

class _SessionResetListenerState extends State<_SessionResetListener> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SessionReset.instance.stream.listen((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthLogoutRequested());
      context.read<PosBloc>().add(const PosSessionReset());
      context.read<ShiftBloc>().add(ShiftSessionReset());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
