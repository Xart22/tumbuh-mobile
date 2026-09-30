import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/features/kds/bloc/kds_bloc.dart';
import 'package:tumbuh_mobile/features/kds/bloc/kds_event.dart';
import 'package:tumbuh_mobile/features/kds/data/models/kds_ticket.dart';
import 'package:tumbuh_mobile/features/kds/presentation/screens/kds_screen.dart';

void main() {
  group('KdsTicket Domain Tests', () {
    test('Calculates urgency properly based on elapsed time', () {
      final now = DateTime(2026, 10, 1, 14, 0, 0);

      // Overdue (> 15 min = 901 sec)
      final overdueTicket = KdsTicket(
        id: '1',
        ticketNumber: '#TB-104',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 03',
        serverName: 'Rama',
        enteredAt: now.subtract(const Duration(minutes: 16, seconds: 42)),
        items: const [],
      );
      expect(overdueTicket.calculateUrgency(now), KdsUrgency.overdue);
      expect(overdueTicket.formatElapsed(now), '16:42');

      // Warning (5-15 min)
      final warningTicket = KdsTicket(
        id: '2',
        ticketNumber: '#TB-105',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 08',
        serverName: 'Dika',
        enteredAt: now.subtract(const Duration(minutes: 11, seconds: 15)),
        items: const [],
      );
      expect(warningTicket.calculateUrgency(now), KdsUrgency.warning);
      expect(warningTicket.formatElapsed(now), '11:15');

      // Fresh (1-5 min)
      final freshTicket = KdsTicket(
        id: '3',
        ticketNumber: '#TB-106',
        orderType: 'Take Away',
        tableOrCustomer: 'GOJEK',
        serverName: 'Kasir',
        enteredAt: now.subtract(const Duration(minutes: 3, seconds: 20)),
        items: const [],
      );
      expect(freshTicket.calculateUrgency(now), KdsUrgency.fresh);
      expect(freshTicket.formatElapsed(now), '03:20');

      // New (< 1 min)
      final newTicket = KdsTicket(
        id: '4',
        ticketNumber: '#TB-107',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 01',
        serverName: 'Rama',
        enteredAt: now.subtract(const Duration(seconds: 45)),
        items: const [],
      );
      expect(newTicket.calculateUrgency(now), KdsUrgency.newOrder);
      expect(newTicket.formatElapsed(now), '00:45');
    });

    test('Station filter matching and item completion status', () {
      final ticket = KdsTicket(
        id: 't1',
        ticketNumber: '#TB-101',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 01',
        serverName: 'Rama',
        enteredAt: DateTime.now(),
        items: const [
          KdsTicketItem(
            id: 'i1',
            name: 'Kopi Susu',
            quantity: 1,
            station: KdsStation.barista,
            isCompleted: true,
          ),
          KdsTicketItem(
            id: 'i2',
            name: 'Croissant',
            quantity: 1,
            station: KdsStation.pastry,
            isCompleted: false,
          ),
        ],
      );

      expect(ticket.hasStation(KdsStation.all), isTrue);
      expect(ticket.hasStation(KdsStation.barista), isTrue);
      expect(ticket.hasStation(KdsStation.pastry), isTrue);
      expect(ticket.hasStation(KdsStation.kitchen), isFalse);
      expect(ticket.isAllItemsCompleted, isFalse);

      final allDoneTicket = ticket.copyWith(
        items: ticket.items.map((i) => i.copyWith(isCompleted: true)).toList(),
      );
      expect(allDoneTicket.isAllItemsCompleted, isTrue);
    });
  });

  group('KdsBloc State Tests', () {
    test('Loads initial mock tickets and handles station filtering', () async {
      final bloc = KdsBloc(autoStartTimer: false);
      bloc.add(const KdsLoadTickets());
      await pumpEventQueue();

      expect(bloc.state.tickets.length, 4);
      expect(bloc.state.recalledTickets.length, 2);
      expect(bloc.state.filteredTickets.length, 4);

      // Filter Barista only
      bloc.add(const KdsFilterStation(KdsStation.barista));
      await pumpEventQueue();
      expect(bloc.state.filteredTickets.length, 2);

      // Filter Kitchen only
      bloc.add(const KdsFilterStation(KdsStation.kitchen));
      await pumpEventQueue();
      expect(bloc.state.filteredTickets.length, 2);

      // Back to All
      bloc.add(const KdsFilterStation(KdsStation.all));
      await pumpEventQueue();
      expect(bloc.state.filteredTickets.length, 4);

      bloc.close();
    });

    test('Toggles item completion in ticket', () async {
      final bloc = KdsBloc(autoStartTimer: false);
      bloc.add(const KdsLoadTickets());
      await pumpEventQueue();

      // Initial item 2 of ticket-104 is not completed
      final ticket104 = bloc.state.tickets.firstWhere((t) => t.id == 'ticket-104');
      expect(ticket104.items[1].isCompleted, isFalse);

      // Toggle item done
      bloc.add(const KdsToggleItemDone(ticketId: 'ticket-104', itemId: 'item-104-2'));
      await pumpEventQueue();

      final updatedTicket = bloc.state.tickets.firstWhere((t) => t.id == 'ticket-104');
      expect(updatedTicket.items[1].isCompleted, isTrue);
      expect(updatedTicket.isAllItemsCompleted, isTrue);
      expect(updatedTicket.status, KdsTicketStatus.ready);

      bloc.close();
    });

    test('Bumping ticket advances status and serves completed ticket to recall list', () async {
      final bloc = KdsBloc(autoStartTimer: false);
      bloc.add(const KdsLoadTickets());
      await pumpEventQueue();

      // ticket-107 is queued -> bumping advances to cooking
      bloc.add(const KdsBumpTicket(ticketId: 'ticket-107'));
      await pumpEventQueue();
      final ticket107 = bloc.state.tickets.firstWhere((t) => t.id == 'ticket-107');
      expect(ticket107.status, KdsTicketStatus.cooking);

      // ticket-104 is ready -> bumping completes it and moves to recalled list
      final initialRecalledCount = bloc.state.recalledTickets.length;
      bloc.add(const KdsBumpTicket(ticketId: 'ticket-104'));
      await pumpEventQueue();

      expect(bloc.state.tickets.any((t) => t.id == 'ticket-104'), isFalse);
      expect(bloc.state.recalledTickets.length, initialRecalledCount + 1);
      expect(bloc.state.recalledTickets.first.id, 'ticket-104');
      expect(bloc.state.recalledTickets.first.status, KdsTicketStatus.served);

      // Recalling restores ticket back to active queue
      bloc.add(const KdsRecallTicket(ticketId: 'ticket-104'));
      await pumpEventQueue();
      expect(bloc.state.tickets.any((t) => t.id == 'ticket-104'), isTrue);
      expect(bloc.state.recalledTickets.length, initialRecalledCount);

      bloc.close();
    });

    test('Audio toggle updates isAudioEnabled', () async {
      final bloc = KdsBloc(autoStartTimer: false);
      expect(bloc.state.isAudioEnabled, isTrue);

      bloc.add(const KdsToggleAudio());
      await pumpEventQueue();
      expect(bloc.state.isAudioEnabled, isFalse);

      bloc.add(const KdsToggleAudio());
      await pumpEventQueue();
      expect(bloc.state.isAudioEnabled, isTrue);

      bloc.close();
    });
  });

  group('KdsScreen Widget Tests', () {
    testWidgets('Renders KDS Screen with header, metrics, and initial tickets', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: KdsScreen(autoStartTimer: false),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header elements
      expect(find.text('TUMBUH KDS'), findsOneWidget);
      expect(find.text('KDS Antrean Dapur & Bar'), findsOneWidget);
      expect(find.textContaining('Semua Station'), findsOneWidget);
      expect(find.textContaining('Barista / Coffee'), findsOneWidget);
      expect(find.textContaining('Dapur Utama / Kitchen'), findsOneWidget);
      expect(find.textContaining('Recall (2)'), findsOneWidget);

      // Check Metrics elements
      expect(find.text('Rata-rata Penyelesaian:'), findsOneWidget);
      expect(find.text('08:24 mnt'), findsOneWidget);
      expect(find.textContaining('Pesanan'), findsOneWidget);
      expect(find.textContaining('Melewati SLA'), findsOneWidget);

      // Check Tickets
      expect(find.text('#TB-104'), findsOneWidget);
      expect(find.text('MEJA 03'), findsOneWidget);
      expect(find.text('#TB-105'), findsOneWidget);
      expect(find.text('MEJA 08'), findsOneWidget);
      expect(find.text('#TB-106'), findsOneWidget);
      expect(find.text('GOJEK DRIVER: BUDI'), findsOneWidget);
      expect(find.text('#TB-107'), findsOneWidget);
      expect(find.text('MEJA 01'), findsOneWidget);

      // Check Special Instructions banner
      expect(find.text('Minta sambal dipisah wadah kecil!'), findsOneWidget);

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Toggling item checkbox and bumping ticket updates screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: KdsScreen(autoStartTimer: false),
        ),
      );
      await tester.pumpAndSettle();

      // Find the bump button on #TB-104 ("Selesaikan & Serve Tiket (Space)")
      final bumpButton = find.text('Selesaikan & Serve Tiket (Space)');
      expect(bumpButton, findsOneWidget);

      // Tap bump button to serve #TB-104
      await tester.tap(bumpButton);
      await tester.pumpAndSettle();

      // #TB-104 is now served and moved to Recall list
      expect(find.text('#TB-104'), findsNothing);
      expect(find.text('Recall (3)'), findsOneWidget);

      // Open Recall modal
      await tester.tap(find.text('Recall (3)'));
      await tester.pumpAndSettle();

      // Modal is visible with #TB-104
      expect(find.text('Recall Tiket Selesai (3)'), findsOneWidget);
      expect(find.text('#TB-104'), findsOneWidget);

      // Click Kembalikan on #TB-104
      final restoreButtons = find.text('Kembalikan');
      expect(restoreButtons, findsWidgets);
      await tester.tap(restoreButtons.first);
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // #TB-104 is back in the active queue
      expect(find.text('#TB-104'), findsOneWidget);

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
    });
  });
}
