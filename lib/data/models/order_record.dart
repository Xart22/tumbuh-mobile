import 'package:equatable/equatable.dart';

class OrderItemLine extends Equatable {
  final String id;
  final String productName;
  final int qty;
  final int unitPrice;
  final String? notes;
  final String status;

  const OrderItemLine({
    required this.id,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    this.notes,
    required this.status,
  });

  factory OrderItemLine.fromJson(Map<String, dynamic> json) => OrderItemLine(
        id: json['id'] as String,
        productName: json['productName'] as String? ?? 'Item',
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String?,
        status: json['status'] as String? ?? 'pending',
      );

  @override
  List<Object?> get props => [id, productName, qty, unitPrice, notes, status];
}

class OrderRecord extends Equatable {
  final String id;
  final String orderNumber;
  final String orderType;
  final String status;
  final String paymentStatus;
  final int total;
  final String? tableNumber;
  final String? customerName;
  final DateTime createdAt;
  final List<OrderItemLine> items;

  const OrderRecord({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    required this.total,
    this.tableNumber,
    this.customerName,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String? ?? '-',
        orderType: json['orderType'] as String? ?? 'dine_in',
        status: json['status'] as String? ?? 'confirmed',
        paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
        total: (json['total'] as num?)?.toInt() ?? 0,
        tableNumber: json['tableNumber'] as String?,
        customerName: json['customerName'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get orderTypeLabel {
    switch (orderType) {
      case 'take_away':
        return 'Take Away';
      case 'delivery':
        return 'Delivery';
      default:
        return 'Dine-in';
    }
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        orderType,
        status,
        paymentStatus,
        total,
        tableNumber,
        customerName,
        createdAt,
        items,
      ];
}
