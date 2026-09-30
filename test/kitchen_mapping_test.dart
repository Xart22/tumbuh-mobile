import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/remote/kitchen_repository.dart';
import 'package:tumbuh_mobile/features/kds/data/models/kds_ticket.dart';

void main() {
  group('KitchenRepository.ticketsFromQueue', () {
    test('groups flat items into tickets by order', () {
      final tickets = KitchenRepository.ticketsFromQueue([
        {
          'orderItemId': 'i1',
          'orderId': 'o1',
          'orderNumber': '#TB-1',
          'tableName': 'Meja 03',
          'orderType': 'dine_in',
          'orderCreatedAt': '2026-10-01T08:00:00.000Z',
          'productName': 'Kopi Susu',
          'qty': 2,
          'status': 'pending',
          'station': 'barista',
        },
        {
          'orderItemId': 'i2',
          'orderId': 'o1',
          'orderNumber': '#TB-1',
          'tableName': 'Meja 03',
          'orderType': 'dine_in',
          'orderCreatedAt': '2026-10-01T08:00:00.000Z',
          'productName': 'Croissant',
          'qty': 1,
          'status': 'ready',
          'station': 'pastry',
          'modifiers': [
            {'modifierName': 'Oat Milk', 'priceAddition': 6000},
          ],
        },
      ]);

      expect(tickets, hasLength(1));
      final ticket = tickets.first;
      expect(ticket.id, 'o1');
      expect(ticket.ticketNumber, '#TB-1');
      expect(ticket.orderType, 'Dine-in');
      expect(ticket.tableOrCustomer, 'Meja 03');
      expect(ticket.items, hasLength(2));
      expect(ticket.items[0].station, KdsStation.barista);
      expect(ticket.items[1].station, KdsStation.pastry);
      expect(ticket.items[1].isCompleted, isTrue);
      expect(ticket.items[1].modifierText, 'Oat Milk');
      expect(ticket.status, KdsTicketStatus.queued);
    });

    test('station and order type mapping', () {
      expect(KitchenRepository.stationFrom('barista'), KdsStation.barista);
      expect(KitchenRepository.stationFrom('pastry'), KdsStation.pastry);
      expect(KitchenRepository.stationFrom(null), KdsStation.kitchen);
      expect(KitchenRepository.orderTypeDisplay('take_away'), 'Take Away');
      expect(KitchenRepository.orderTypeDisplay('delivery'), 'Delivery');
      expect(KitchenRepository.orderTypeDisplay('dine_in'), 'Dine-in');
    });
  });
}
