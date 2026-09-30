import 'package:equatable/equatable.dart';
import 'product_modifier.dart';

class PosCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  const PosCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'sortOrder': sortOrder,
  };

  factory PosCategory.fromJson(Map<String, dynamic> json) => PosCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? '☕',
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [id, name, icon, sortOrder];
}

class PosProduct extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final int price; // In IDR
  final int costPrice;
  final String categoryId;
  final String categoryName;
  final double stockQuantity;
  final bool isAvailable;
  final bool isBestSeller;
  final String? imageUrl;
  final List<ModifierGroup> modifierGroups;

  const PosProduct({
    required this.id,
    required this.name,
    this.description,
    required this.sku,
    this.barcode,
    required this.price,
    this.costPrice = 0,
    required this.categoryId,
    required this.categoryName,
    this.stockQuantity = 0.0,
    this.isAvailable = true,
    this.isBestSeller = false,
    this.imageUrl,
    this.modifierGroups = const [],
  });

  bool get hasModifiers => modifierGroups.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'sku': sku,
    'barcode': barcode,
    'price': price,
    'costPrice': costPrice,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'stockQuantity': stockQuantity,
    'isAvailable': isAvailable,
    'isBestSeller': isBestSeller,
    'imageUrl': imageUrl,
    'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
  };

  factory PosProduct.fromJson(Map<String, dynamic> json) => PosProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    sku: json['sku'] as String,
    barcode: json['barcode'] as String?,
    price: (json['price'] as num).toInt(),
    costPrice: (json['costPrice'] as num?)?.toInt() ?? 0,
    categoryId: json['categoryId'] as String,
    categoryName: json['categoryName'] as String? ?? '',
    stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
    isAvailable: json['isAvailable'] as bool? ?? true,
    isBestSeller: json['isBestSeller'] as bool? ?? false,
    imageUrl: json['imageUrl'] as String?,
    modifierGroups: (json['modifierGroups'] as List<dynamic>?)
            ?.map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    sku,
    barcode,
    price,
    costPrice,
    categoryId,
    categoryName,
    stockQuantity,
    isAvailable,
    isBestSeller,
    imageUrl,
    modifierGroups,
  ];
}
