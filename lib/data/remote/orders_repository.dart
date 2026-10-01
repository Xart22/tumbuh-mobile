import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../local/outbox/outbox_dao.dart';
import '../models/order_record.dart';

/// Order history + order-level mutations (tumbuh-be `/v1/orders`).
class OrdersRepository {
  final ApiClient apiClient;
  final OutboxDao? outboxDao;

  OrdersRepository({required this.apiClient, this.outboxDao});

  static bool _isOffline(Object error) {
    if (error is NetworkOfflineException) return true;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.error is NetworkOfflineException;
    }
    return false;
  }

  /// Runs a mutation; on a network failure it is queued for replay, otherwise
  /// the error surfaces.
  Future<void> _mutate(
    String endpoint,
    String method,
    Map<String, dynamic>? body,
  ) async {
    try {
      await apiClient.dio.request(
        endpoint,
        data: body,
        options: Options(method: method, headers: _idempotentHeaders()),
      );
    } catch (e) {
      if (!_isOffline(e) || outboxDao == null) rethrow;
      await outboxDao!.enqueue(
        endpoint: endpoint,
        method: method,
        payload: body ?? const {},
      );
    }
  }

  Future<List<OrderRecord>> fetchOrders({String? status}) async {
    final res = await apiClient.getWithRetry(
      '/v1/orders',
      queryParameters: {'status': ?status},
    );
    final rows = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map(OrderRecord.fromJson).toList();
  }

  Future<OrderRecord> fetchOrder(String id) async {
    final res = await apiClient.getWithRetry('/v1/orders/$id');
    return OrderRecord.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> voidOrder(String id, String reason) =>
      _mutate('/v1/orders/$id/void', 'POST', {'reason': reason});

  Future<void> voidOrderItem(String orderId, String itemId, String reason) =>
      _mutate('/v1/orders/$orderId/items/$itemId/void', 'POST', {
        'reason': reason,
      });

  Future<void> cancelOrder(String id) =>
      _mutate('/v1/orders/$id/cancel', 'POST', null);

  /// Merge a source order into a target. Backend: `POST /v1/orders/:id/merge`.
  Future<void> mergeOrder(String sourceOrderId, String targetOrderId) =>
      _mutate('/v1/orders/$sourceOrderId/merge', 'POST', {
        'targetOrderId': targetOrderId,
      });

  /// Split selected quantities into a new order. Backend:
  /// `POST /v1/orders/:id/split` with `{lines:[{orderItemId, qty}]}`.
  Future<void> splitOrder(
    String orderId,
    List<({String itemId, int qty})> lines,
  ) =>
      _mutate('/v1/orders/$orderId/split', 'POST', {
        'lines': lines
            .map((l) => {'orderItemId': l.itemId, 'qty': l.qty})
            .toList(),
      });

  /// Settle a credit (piutang) order. Backend: `POST /v1/orders/:id/credit-settle`.
  Future<void> settleCredit(String id) =>
      _mutate('/v1/orders/$id/credit-settle', 'POST', null);

  static Map<String, dynamic> _idempotentHeaders() =>
      {'Idempotency-Key': const Uuid().v4()};
}
