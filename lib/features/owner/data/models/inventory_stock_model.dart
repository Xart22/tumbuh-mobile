import 'package:equatable/equatable.dart';

class StockAlertItem extends Equatable {
  final String id;
  final String name;
  final String category;
  final double currentStock;
  final String unit;
  final double minStock;
  final String supplierName;
  final bool isCritical;
  final double suggestedReorderQuantity;
  final int estimatedPricePerUnit;

  const StockAlertItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.minStock,
    required this.supplierName,
    required this.isCritical,
    required this.suggestedReorderQuantity,
    required this.estimatedPricePerUnit,
  });

  int get totalEstimatedCost => (suggestedReorderQuantity * estimatedPricePerUnit).round();

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        currentStock,
        unit,
        minStock,
        supplierName,
        isCritical,
        suggestedReorderQuantity,
        estimatedPricePerUnit,
      ];
}
