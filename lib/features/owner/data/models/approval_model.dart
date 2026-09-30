import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ApprovalType {
  voidOrder,
  specialDiscount,
  purchaseOrder,
  shiftVariance;

  String get label {
    switch (this) {
      case ApprovalType.voidOrder:
        return 'VOID TRANSAKSI';
      case ApprovalType.specialDiscount:
        return 'DISKON MELEBIHI LIMIT';
      case ApprovalType.purchaseOrder:
        return 'PURCHASE ORDER (PO)';
      case ApprovalType.shiftVariance:
        return 'KOREKSI SELISIH KAS';
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case ApprovalType.voidOrder:
        return const Color(0xFFDC2626); // red-600
      case ApprovalType.specialDiscount:
        return const Color(0xFFF59E0B); // amber-500
      case ApprovalType.purchaseOrder:
        return const Color(0xFF2563EB); // blue-600
      case ApprovalType.shiftVariance:
        return const Color(0xFF7C3AED); // purple-600
    }
  }
}

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Menunggu Otorisasi';
      case ApprovalStatus.approved:
        return 'Disetujui';
      case ApprovalStatus.rejected:
        return 'Ditolak';
    }
  }
}

class ApprovalRequest extends Equatable {
  final String id;
  final ApprovalType type;
  final String title;
  final String requestedBy;
  final String shiftName;
  final String? ticketNumber;
  final String? tableNumber;
  final int amount;
  final String? requestedItemsSummary;
  final String reason;
  final DateTime requestedAt;
  final ApprovalStatus status;
  final DateTime? decisionAt;
  final String? decisionNotes;
  final String? supplierName;

  const ApprovalRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.requestedBy,
    required this.shiftName,
    this.ticketNumber,
    this.tableNumber,
    required this.amount,
    this.requestedItemsSummary,
    required this.reason,
    required this.requestedAt,
    this.status = ApprovalStatus.pending,
    this.decisionAt,
    this.decisionNotes,
    this.supplierName,
  });

  ApprovalRequest copyWith({
    String? id,
    ApprovalType? type,
    String? title,
    String? requestedBy,
    String? shiftName,
    String? ticketNumber,
    String? tableNumber,
    int? amount,
    String? requestedItemsSummary,
    String? reason,
    DateTime? requestedAt,
    ApprovalStatus? status,
    DateTime? decisionAt,
    String? decisionNotes,
    String? supplierName,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      requestedBy: requestedBy ?? this.requestedBy,
      shiftName: shiftName ?? this.shiftName,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      amount: amount ?? this.amount,
      requestedItemsSummary: requestedItemsSummary ?? this.requestedItemsSummary,
      reason: reason ?? this.reason,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      decisionAt: decisionAt ?? this.decisionAt,
      decisionNotes: decisionNotes ?? this.decisionNotes,
      supplierName: supplierName ?? this.supplierName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        requestedBy,
        shiftName,
        ticketNumber,
        tableNumber,
        amount,
        requestedItemsSummary,
        reason,
        requestedAt,
        status,
        decisionAt,
        decisionNotes,
        supplierName,
      ];
}
