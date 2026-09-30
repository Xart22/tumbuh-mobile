import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/features/owner/bloc/owner_bloc.dart';
import 'package:tumbuh_mobile/features/owner/bloc/owner_event.dart';
import 'package:tumbuh_mobile/features/owner/data/models/approval_model.dart';
import 'package:tumbuh_mobile/features/owner/presentation/screens/owner_dashboard_screen.dart';
import 'package:tumbuh_mobile/features/owner/presentation/widgets/owner_pin_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OwnerBloc Unit Tests', () {
    late OwnerBloc bloc;

    setUp(() {
      bloc = OwnerBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state loads KPI data, approvals, and defaults to Tab 0', () async {
      await pumpEventQueue();
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.selectedOutlet, 'Kopi Kita – Cabang Tebet');
      expect(bloc.state.kpiData.todayRevenue, 14850000);
      expect(bloc.state.pendingApprovalsCount, 3);
      expect(bloc.state.criticalStockCount, 2);
    });

    test('OwnerSelectTab changes tab index correctly', () async {
      await pumpEventQueue();
      bloc.add(const OwnerSelectTab(2));
      await pumpEventQueue();
      expect(bloc.state.currentTabIndex, 2);
    });

    test('OwnerSelectOutlet switches active gerai', () async {
      await pumpEventQueue();
      bloc.add(const OwnerSelectOutlet('Kopi Kita – Cabang Senopati'));
      await pumpEventQueue();
      expect(bloc.state.selectedOutlet, 'Kopi Kita – Cabang Senopati');
    });

    test('OwnerApproveRequest approves request and updates status', () async {
      await pumpEventQueue();
      expect(bloc.state.pendingApprovalsCount, 3);

      bloc.add(const OwnerApproveRequest(
        requestId: 'app-01',
        pin: '123456',
      ));
      await pumpEventQueue();

      expect(bloc.state.pendingApprovalsCount, 2);
      expect(bloc.state.approvedCount, 1);
      final approvedReq = bloc.state.approvals.firstWhere((a) => a.id == 'app-01');
      expect(approvedReq.status, ApprovalStatus.approved);
      expect(bloc.state.lastDecisionMessage, contains('berhasil disetujui'));
    });

    test('OwnerRejectRequest rejects request with reason', () async {
      await pumpEventQueue();
      bloc.add(const OwnerRejectRequest(
        requestId: 'app-02',
        reason: 'Diskon terlalu besar, maksimal 10%',
      ));
      await pumpEventQueue();

      expect(bloc.state.pendingApprovalsCount, 2);
      expect(bloc.state.rejectedCount, 1);
      final rejectedReq = bloc.state.approvals.firstWhere((a) => a.id == 'app-02');
      expect(rejectedReq.status, ApprovalStatus.rejected);
      expect(rejectedReq.decisionNotes, 'Diskon terlalu besar, maksimal 10%');
      expect(bloc.state.lastDecisionMessage, contains('telah ditolak'));
    });

    test('OwnerFilterApprovalStatus filters list correctly', () async {
      await pumpEventQueue();
      bloc.add(const OwnerFilterApprovalStatus(ApprovalStatus.approved));
      await pumpEventQueue();
      expect(bloc.state.approvalFilter, ApprovalStatus.approved);
      expect(bloc.state.filteredApprovals.length, 0); // Initially none approved
    });

    test('OwnerQuickReorderItem generates PO feedback', () async {
      await pumpEventQueue();
      bloc.add(const OwnerQuickReorderItem(
        itemId: 'stk-01',
        quantity: 6.0,
      ));
      await pumpEventQueue();
      expect(bloc.state.lastDecisionMessage, contains('PO Cepat Sirup Karamel Monin'));
    });
  });

  group('OwnerDashboardScreen Widget Tests', () {
    testWidgets('Renders Mobile Owner Dashboard with TopBar, KPIs, and Navigation',
        (tester) async {
      tester.view.physicalSize = const Size(780, 1768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TopBar
      expect(find.text('Tumbuh Backoffice'), findsOneWidget);
      expect(find.text('Kopi Kita – Cabang Tebet'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);

      // Verify Primary Omzet KPI
      expect(find.text('TOTAL OMZET HARI INI'), findsOneWidget);
      expect(find.text('Rp 14.850.000'), findsOneWidget);
      expect(find.text('+18.4%'), findsOneWidget);

      // Verify 2x2 Grid Secondary KPIs
      expect(find.text('Laba Kotor (Margin)'), findsOneWidget);
      expect(find.text('Rp 9.820.000'), findsOneWidget);
      expect(find.text('Total Transaksi'), findsOneWidget);
      expect(find.text('148 Struk'), findsOneWidget);

      // Verify Bottom Navigation Bar 5 tabs
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Stok Bahan'), findsOneWidget);
      expect(find.text('Persetujuan'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
    });

    testWidgets('Switching between tabs displays corresponding views', (tester) async {
      tester.view.physicalSize = const Size(780, 1768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Tab 1: Laporan
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();
      expect(find.text('PENJUALAN BERSIH (NET SALES)'), findsOneWidget);
      expect(find.text('Breakdown Metode Pembayaran'), findsOneWidget);
      expect(find.text('Total Uang Masuk Bersih'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Top 5 Produk Terlaris'), findsOneWidget);

      // Tap Tab 2: Stok Bahan
      await tester.tap(find.text('Stok Bahan'));
      await tester.pumpAndSettle();
      expect(find.text('STATUS BAHAN BAKU'), findsOneWidget);
      expect(find.textContaining('Membutuhkan Restock!'), findsOneWidget);

      // Tap Tab 3: Persetujuan
      await tester.tap(find.text('Persetujuan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Otorisasi Level Owner Diperlukan'), findsOneWidget);
      expect(find.text('Menunggu Otorisasi'), findsOneWidget);

      // Tap Tab 4: Pengaturan
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.text('Agus Darmawan'), findsOneWidget);
      expect(find.text('Peralihan Antar Layar POS'), findsOneWidget);
    });

    testWidgets('OwnerPinBottomSheet opens and inputs digits', (tester) async {
      String? enteredPin;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  enteredPin = await OwnerPinBottomSheet.show(ctx);
                },
                child: const Text('Buka PIN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Otorisasi Cepat Owner'), findsOneWidget);

      // Tap digits 1, 2, 3, 4, 5, 6
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(enteredPin, '123456');
    });
  });
}
