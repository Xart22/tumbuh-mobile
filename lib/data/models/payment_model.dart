import 'package:equatable/equatable.dart';

enum PosPaymentMethod {
  cash,
  qris,
  debit,
  transfer;

  String get label {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'Tunai';
      case PosPaymentMethod.qris:
        return 'QRIS Dinamis';
      case PosPaymentMethod.debit:
        return 'Debit / EDC';
      case PosPaymentMethod.transfer:
        return 'Transfer Bank';
    }
  }

  String get iconEmoji {
    switch (this) {
      case PosPaymentMethod.cash:
        return '💵';
      case PosPaymentMethod.qris:
        return '📱';
      case PosPaymentMethod.debit:
        return '💳';
      case PosPaymentMethod.transfer:
        return '🏦';
    }
  }
}

class SplitPaymentEntry extends Equatable {
  final String id;
  final PosPaymentMethod method;
  final int amount; // Target allocated amount
  final int cashGiven; // Amount given by customer if cash
  final int change; // Change returned if cash
  final String? referenceNumber; // e.g. QRIS transaction ID or EDC Approval Code

  const SplitPaymentEntry({
    required this.id,
    required this.method,
    required this.amount,
    this.cashGiven = 0,
    this.change = 0,
    this.referenceNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method.name,
    'amount': amount,
    'cashGiven': cashGiven,
    'change': change,
    'referenceNumber': referenceNumber,
  };

  factory SplitPaymentEntry.fromJson(Map<String, dynamic> json) => SplitPaymentEntry(
    id: json['id'] as String,
    method: PosPaymentMethod.values.firstWhere(
      (m) => m.name == json['method'],
      orElse: () => PosPaymentMethod.cash,
    ),
    amount: (json['amount'] as num).toInt(),
    cashGiven: (json['cashGiven'] as num?)?.toInt() ?? 0,
    change: (json['change'] as num?)?.toInt() ?? 0,
    referenceNumber: json['referenceNumber'] as String?,
  );

  @override
  List<Object?> get props => [id, method, amount, cashGiven, change, referenceNumber];
}

class OrderPaymentDetails extends Equatable {
  final bool isSplitPayment;
  final PosPaymentMethod primaryMethod;
  final int grandTotal;
  final int totalPaid;
  final int change;
  final List<SplitPaymentEntry> splits;
  final bool printPhysicalReceipt;
  final bool sendWhatsAppReceipt;
  final String? customerPhone;
  final String? customerName;
  final DateTime paidAt;

  const OrderPaymentDetails({
    this.isSplitPayment = false,
    this.primaryMethod = PosPaymentMethod.cash,
    required this.grandTotal,
    required this.totalPaid,
    this.change = 0,
    this.splits = const [],
    this.printPhysicalReceipt = true,
    this.sendWhatsAppReceipt = false,
    this.customerPhone,
    this.customerName,
    required this.paidAt,
  });

  Map<String, dynamic> toJson() => {
    'isSplitPayment': isSplitPayment,
    'primaryMethod': primaryMethod.name,
    'grandTotal': grandTotal,
    'totalPaid': totalPaid,
    'change': change,
    'splits': splits.map((s) => s.toJson()).toList(),
    'printPhysicalReceipt': printPhysicalReceipt,
    'sendWhatsAppReceipt': sendWhatsAppReceipt,
    'customerPhone': customerPhone,
    'customerName': customerName,
    'paidAt': paidAt.toIso8601String(),
  };

  factory OrderPaymentDetails.fromJson(Map<String, dynamic> json) => OrderPaymentDetails(
    isSplitPayment: json['isSplitPayment'] as bool? ?? false,
    primaryMethod: PosPaymentMethod.values.firstWhere(
      (m) => m.name == json['primaryMethod'],
      orElse: () => PosPaymentMethod.cash,
    ),
    grandTotal: (json['grandTotal'] as num).toInt(),
    totalPaid: (json['totalPaid'] as num).toInt(),
    change: (json['change'] as num?)?.toInt() ?? 0,
    splits: (json['splits'] as List<dynamic>?)
            ?.map((s) => SplitPaymentEntry.fromJson(s as Map<String, dynamic>))
            .toList() ??
        const [],
    printPhysicalReceipt: json['printPhysicalReceipt'] as bool? ?? true,
    sendWhatsAppReceipt: json['sendWhatsAppReceipt'] as bool? ?? false,
    customerPhone: json['customerPhone'] as String?,
    customerName: json['customerName'] as String?,
    paidAt: DateTime.tryParse(json['paidAt'] as String? ?? '') ?? DateTime.now(),
  );

  @override
  List<Object?> get props => [
    isSplitPayment,
    primaryMethod,
    grandTotal,
    totalPaid,
    change,
    splits,
    printPhysicalReceipt,
    sendWhatsAppReceipt,
    customerPhone,
    customerName,
    paidAt,
  ];
}
