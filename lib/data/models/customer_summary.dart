import 'package:equatable/equatable.dart';

class CustomerSummary extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final int loyaltyPoints;
  final int stampsCount;

  const CustomerSummary({
    required this.id,
    required this.name,
    this.phone,
    this.loyaltyPoints = 0,
    this.stampsCount = 0,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) => CustomerSummary(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Tamu',
        phone: json['phone'] as String?,
        loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
        stampsCount: (json['stampsCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, name, phone, loyaltyPoints, stampsCount];
}
