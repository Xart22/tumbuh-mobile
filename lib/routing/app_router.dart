import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/kasir_login_screen.dart';
import '../features/auth/presentation/screens/owner_setup_screen.dart';
import '../features/kds/presentation/screens/kds_screen.dart';
import '../features/owner/presentation/screens/owner_dashboard_screen.dart';
import '../features/pos/presentation/screens/pos_tablet_screen.dart';
import '../features/orders/presentation/screens/orders_screen.dart';
import '../features/pos/presentation/screens/printer_management_screen.dart';
import '../features/shift/presentation/screens/shift_screen.dart';

class AppRouter {
  AppRouter._();

  static const String loginKasir = '/login-kasir';
  static const String setup = '/setup';
  static const String pos = '/pos';
  static const String kds = '/kds';
  static const String owner = '/owner';
  static const String shift = '/shift';
  static const String orders = '/orders';
  static const String printerSettings = '/printer-settings';
  static const String selfOrder = '/order/:tableId';

  static GoRouter createRouter({String initialLocation = loginKasir}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: loginKasir,
          builder: (context, state) => const KasirLoginScreen(),
        ),
        GoRoute(
          path: setup,
          builder: (context, state) => const OwnerSetupScreen(),
        ),
        GoRoute(
          path: orders,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: pos,
          builder: (context, state) => const PosTabletScreen(),
        ),
        GoRoute(
          path: kds,
          builder: (context, state) => const KdsScreen(),
        ),
        GoRoute(
          path: owner,
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: shift,
          builder: (context, state) => ShiftScreen(
            autoEnterPos: state.uri.queryParameters['autopos'] == '1',
          ),
        ),
        GoRoute(
          path: printerSettings,
          builder: (context, state) => const PrinterManagementScreen(),
        ),
        GoRoute(
          path: selfOrder,
          builder: (context, state) {
            final tableId = state.pathParameters['tableId'] ?? '';
            return Scaffold(
              body: Center(
                child: Text('Self-Order Web PWA Meja #$tableId'),
              ),
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Halaman tidak ditemukan: ${state.uri}'),
        ),
      ),
    );
  }
}

