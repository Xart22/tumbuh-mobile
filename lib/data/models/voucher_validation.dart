import 'package:equatable/equatable.dart';

class VoucherValidation extends Equatable {
  final String code;
  final String name;
  final int discountAmount;
  final int finalTotal;

  const VoucherValidation({
    required this.code,
    required this.name,
    required this.discountAmount,
    required this.finalTotal,
  });

  factory VoucherValidation.fromJson(Map<String, dynamic> json) =>
      VoucherValidation(
        code: json['code'] as String? ?? '',
        name: json['voucherName'] as String? ?? 'Voucher',
        discountAmount: (json['discountAmount'] as num?)?.round() ?? 0,
        finalTotal: (json['finalTotal'] as num?)?.round() ?? 0,
      );

  @override
  List<Object?> get props => [code, name, discountAmount, finalTotal];
}
