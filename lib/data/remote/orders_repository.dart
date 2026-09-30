import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../models/order_record.dart';

/// Order history + order-level mutations (tumbuh-be `/v1/orders`).
class OrdersRepository {
  final ApiClient apiClient;

  OrdersRepository({required this.apiClient});

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

  Future<void> voidOrder(String id, String reason) => apiClient.dio.post(
        '/v1/orders/$id/void',
        data: {'reason': reason},
        options: _idempotent(),
      );

  Future<void> voidOrderItem(String orderId, String itemId, String reason) =>
      apiClient.dio.post(
        '/v1/orders/$orderId/items/$itemId/void',
        data: {'reason': reason},
        options: _idempotent(),
      );

  Future<void> cancelOrder(String id) => apiClient.dio.post(
        '/v1/orders/$id/cancel',
        options: _idempotent(),
      );

  static Options _idempotent() =>
      Options(headers: {'Idempotency-Key': const Uuid().v4()});
}
