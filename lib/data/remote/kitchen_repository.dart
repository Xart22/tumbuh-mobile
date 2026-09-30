import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../features/kds/data/models/kds_ticket.dart';
import '../../core/network/api_client.dart';

/// KDS backend access (tumbuh-be `/v1/kitchen/*`). Polling for now; the
/// `kitchen:update` socket event can replace the poll later.
class KitchenRepository {
  final ApiClient apiClient;

  KitchenRepository({required this.apiClient});

  Future<List<KdsTicket>> fetchTickets() async {
    final res = await apiClient.getWithRetry('/v1/kitchen/queue');
    final items = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    return ticketsFromQueue(items);
  }

  Future<void> bumpItem(String orderItemId) =>
      apiClient.dio.patch('/v1/kitchen/items/$orderItemId/bump');

  Future<void> serveOrder(String orderId) =>
      apiClient.dio.patch('/v1/kitchen/orders/$orderId/serve');

  Future<void> recallOrder(String orderId) =>
      apiClient.dio.patch('/v1/kitchen/orders/$orderId/recall');

  @visibleForTesting
  static KdsStation stationFrom(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('barista') || s.contains('coffee') || s.contains('bar')) {
      return KdsStation.barista;
    }
    if (s.contains('pastry') || s.contains('bakery')) {
      return KdsStation.pastry;
    }
    return KdsStation.kitchen;
  }

  static String orderTypeDisplay(String? raw) {
    switch (raw) {
      case 'take_away':
        return 'Take Away';
      case 'delivery':
        return 'Delivery';
      default:
        return 'Dine-in';
    }
  }

  static KdsTicketStatus _statusFrom(List<String> statuses) {
    if (statuses.isNotEmpty && statuses.every((s) => s == 'ready')) {
      return KdsTicketStatus.ready;
    }
    if (statuses.contains('cooking')) return KdsTicketStatus.cooking;
    if (statuses.isNotEmpty && statuses.every((s) => s == 'served')) {
      return KdsTicketStatus.served;
    }
    return KdsTicketStatus.queued;
  }

  /// Groups flat kitchen queue items (one row per order item) into tickets.
  @visibleForTesting
  static List<KdsTicket> ticketsFromQueue(List<Map<String, dynamic>> items) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final orderId = item['orderId'] as String? ?? '';
      grouped.putIfAbsent(orderId, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final rows = entry.value;
      final first = rows.first;

      final ticketItems = rows.map((row) {
        final status = row['status'] as String? ?? 'pending';
        final modifiers = ((row['modifiers'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map((m) => m['modifierName'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .join(', ');
        return KdsTicketItem(
          id: row['orderItemId'] as String,
          name: row['productName'] as String? ?? 'Item',
          quantity: (row['qty'] as num?)?.toInt() ?? 1,
          station: stationFrom(row['station'] as String?),
          modifierText: modifiers.isEmpty ? null : modifiers,
          notes: row['notes'] as String?,
          isCompleted: status == 'ready' || status == 'served',
        );
      }).toList();

      final rawEntered = first['orderCreatedAt'] ?? first['sentToKitchenAt'];
      final enteredAt =
          DateTime.tryParse(rawEntered as String? ?? '') ?? DateTime.now();

      return KdsTicket(
        id: entry.key,
        ticketNumber: first['orderNumber'] as String? ?? '#-',
        orderType: orderTypeDisplay(first['orderType'] as String?),
        tableOrCustomer: first['tableName'] as String? ?? '-',
        serverName: '-',
        enteredAt: enteredAt,
        items: ticketItems,
        status: _statusFrom(
          rows.map((r) => r['status'] as String? ?? 'pending').toList(),
        ),
      );
    }).toList();
  }
}
