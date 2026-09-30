class ShiftModel {
  final String id;
  final int shiftNumber;
  final String shiftName;
  final String cashierId;
  final String cashierName;
  final String outletId;
  final String outletName;
  final String deviceId;
  final String deviceName;
  final DateTime startTime;
  final DateTime? endTime;
  final int initialFloat;
  final int cashSales;
  final int cashSalesCount;
  final int nonCashSales;
  final int nonCashSalesCount;
  final int? actualCashCount;
  final String? varianceReason;
  final String? handoverNotes;
  final String? supervisorName;
  final String status; // 'open', 'closed'

  const ShiftModel({
    required this.id,
    required this.shiftNumber,
    required this.shiftName,
    required this.cashierId,
    required this.cashierName,
    required this.outletId,
    required this.outletName,
    required this.deviceId,
    required this.deviceName,
    required this.startTime,
    this.endTime,
    required this.initialFloat,
    this.cashSales = 0,
    this.cashSalesCount = 0,
    this.nonCashSales = 0,
    this.nonCashSalesCount = 0,
    this.actualCashCount,
    this.varianceReason,
    this.handoverNotes,
    this.supervisorName,
    this.status = 'open',
  });

  /// Total expected cash in the physical drawer = Float in + Cash sales
  int get expectedCashInDrawer => initialFloat + cashSales;

  /// Variance between actual physical cash and expected cash:
  /// variance = actualCash - expectedCashInDrawer
  /// 0 = balance perfect, < 0 = cash minus, > 0 = surplus
  int? get variance => actualCashCount != null ? (actualCashCount! - expectedCashInDrawer) : null;

  bool get isOpen => status == 'open';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      shiftNumber: json['shiftNumber'] as int? ?? 1,
      shiftName: json['shiftName'] as String? ?? 'Shift 1 Pagi',
      cashierId: json['cashierId'] as String,
      cashierName: json['cashierName'] as String,
      outletId: json['outletId'] as String,
      outletName: json['outletName'] as String? ?? 'Outlet Utama',
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String? ?? 'Tablet Kasir',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      initialFloat: (json['initialFloat'] as num?)?.toInt() ?? 0,
      cashSales: (json['cashSales'] as num?)?.toInt() ?? 0,
      cashSalesCount: (json['cashSalesCount'] as num?)?.toInt() ?? 0,
      nonCashSales: (json['nonCashSales'] as num?)?.toInt() ?? 0,
      nonCashSalesCount: (json['nonCashSalesCount'] as num?)?.toInt() ?? 0,
      actualCashCount: (json['actualCashCount'] as num?)?.toInt(),
      varianceReason: json['varianceReason'] as String?,
      handoverNotes: json['handoverNotes'] as String?,
      supervisorName: json['supervisorName'] as String?,
      status: json['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shiftNumber': shiftNumber,
        'shiftName': shiftName,
        'cashierId': cashierId,
        'cashierName': cashierName,
        'outletId': outletId,
        'outletName': outletName,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'initialFloat': initialFloat,
        'cashSales': cashSales,
        'cashSalesCount': cashSalesCount,
        'nonCashSales': nonCashSales,
        'nonCashSalesCount': nonCashSalesCount,
        'actualCashCount': actualCashCount,
        'varianceReason': varianceReason,
        'handoverNotes': handoverNotes,
        'supervisorName': supervisorName,
        'status': status,
      };

  ShiftModel copyWith({
    String? id,
    int? shiftNumber,
    String? shiftName,
    String? cashierId,
    String? cashierName,
    String? outletId,
    String? outletName,
    String? deviceId,
    String? deviceName,
    DateTime? startTime,
    DateTime? endTime,
    int? initialFloat,
    int? cashSales,
    int? cashSalesCount,
    int? nonCashSales,
    int? nonCashSalesCount,
    int? actualCashCount,
    String? varianceReason,
    String? handoverNotes,
    String? supervisorName,
    String? status,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      shiftNumber: shiftNumber ?? this.shiftNumber,
      shiftName: shiftName ?? this.shiftName,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialFloat: initialFloat ?? this.initialFloat,
      cashSales: cashSales ?? this.cashSales,
      cashSalesCount: cashSalesCount ?? this.cashSalesCount,
      nonCashSales: nonCashSales ?? this.nonCashSales,
      nonCashSalesCount: nonCashSalesCount ?? this.nonCashSalesCount,
      actualCashCount: actualCashCount ?? this.actualCashCount,
      varianceReason: varianceReason ?? this.varianceReason,
      handoverNotes: handoverNotes ?? this.handoverNotes,
      supervisorName: supervisorName ?? this.supervisorName,
      status: status ?? this.status,
    );
  }
}
