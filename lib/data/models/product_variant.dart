import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String id;
  final String name;
  final int priceAdjustment; // IDR delta on top of the product base price
  final bool isActive;

  const ProductVariant({
    required this.id,
    required this.name,
    this.priceAdjustment = 0,
    this.isActive = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Varian',
        priceAdjustment: (json['priceAdjustment'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, name, priceAdjustment, isActive];
}
