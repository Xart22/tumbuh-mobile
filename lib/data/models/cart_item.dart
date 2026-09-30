import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'pos_product.dart';
import 'product_modifier.dart';

class CartItem extends Equatable {
  final String id;
  final PosProduct product;
  final List<ModifierOption> selectedModifiers;
  final int quantity;
  final String? notes;
  final int itemDiscount; // IDR per line

  const CartItem({
    required this.id,
    required this.product,
    this.selectedModifiers = const [],
    this.quantity = 1,
    this.notes,
    this.itemDiscount = 0,
  });

  factory CartItem.create({
    required PosProduct product,
    List<ModifierOption> selectedModifiers = const [],
    int quantity = 1,
    String? notes,
    int itemDiscount = 0,
  }) {
    return CartItem(
      id: const Uuid().v4(),
      product: product,
      selectedModifiers: selectedModifiers,
      quantity: quantity,
      notes: notes,
      itemDiscount: itemDiscount,
    );
  }

  /// Unit price including modifier price deltas
  int get unitPrice {
    final modifierTotal = selectedModifiers.fold<int>(
      0,
      (sum, mod) => sum + mod.priceDelta,
    );
    return product.price + modifierTotal;
  }

  /// Total price before discount
  int get grossTotal => unitPrice * quantity;

  /// Net total after item-level discount
  int get netTotal {
    final total = grossTotal - itemDiscount;
    return total > 0 ? total : 0;
  }

  CartItem copyWith({
    String? id,
    PosProduct? product,
    List<ModifierOption>? selectedModifiers,
    int? quantity,
    String? notes,
    int? itemDiscount,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      itemDiscount: itemDiscount ?? this.itemDiscount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product.toJson(),
    'selectedModifiers': selectedModifiers.map((m) => m.toJson()).toList(),
    'quantity': quantity,
    'notes': notes,
    'itemDiscount': itemDiscount,
    'unitPrice': unitPrice,
    'netTotal': netTotal,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    product: PosProduct.fromJson(json['product'] as Map<String, dynamic>),
    selectedModifiers: (json['selectedModifiers'] as List<dynamic>?)
            ?.map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    notes: json['notes'] as String?,
    itemDiscount: (json['itemDiscount'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [id, product, selectedModifiers, quantity, notes, itemDiscount];
}
