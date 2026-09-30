import 'dart:math' as math;

/// Represents an item line for order math preview calculations.
class OrderMathItem {
  final String id;
  final String name;
  final int unitPrice;
  final int quantity;
  final List<int> modifierPrices;
  final int itemDiscountAmount;

  const OrderMathItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.modifierPrices = const [],
    this.itemDiscountAmount = 0,
  });

  /// Price of one unit including its modifiers.
  int get unitPriceWithModifiers {
    final modifiersTotal = modifierPrices.fold<int>(0, (sum, p) => sum + p);
    return unitPrice + modifiersTotal;
  }

  /// Total price for this line before line discounts.
  int get lineGrossTotal => unitPriceWithModifiers * quantity;

  /// Line total after line discount.
  int get lineNetTotal => math.max(0, lineGrossTotal - itemDiscountAmount);
}

/// Parameters for order calculation.
class OrderCalculationParams {
  final List<OrderMathItem> items;
  final double orderDiscountPercent; // e.g. 10.0 for 10%
  final int orderDiscountNominal; // Fixed Rp discount
  final double serviceChargeRate; // e.g. 0.05 for 5%
  final double taxRate; // e.g. 0.10 for 10% PB1
  final bool taxIncludesService; // Standard PB1 applies to (subtotal + service)
  final int roundingBase; // e.g. 100 or 500 (0 to disable)

  const OrderCalculationParams({
    required this.items,
    this.orderDiscountPercent = 0.0,
    this.orderDiscountNominal = 0,
    this.serviceChargeRate = 0.0,
    this.taxRate = 0.0,
    this.taxIncludesService = true,
    this.roundingBase = 0,
  });
}

/// Result of order total calculations.
class OrderTotals {
  final int grossSubtotal;
  final int itemDiscounts;
  final int orderDiscount;
  final int totalDiscount;
  final int netSubtotal;
  final int serviceCharge;
  final int tax;
  final int rounding;
  final int finalTotal;

  const OrderTotals({
    required this.grossSubtotal,
    required this.itemDiscounts,
    required this.orderDiscount,
    required this.totalDiscount,
    required this.netSubtotal,
    required this.serviceCharge,
    required this.tax,
    required this.rounding,
    required this.finalTotal,
  });

  // Ergonomic property aliases for UI and POS Cart
  int get subtotal => grossSubtotal;
  int get voucherDiscount => orderDiscount;
  int get itemDiscountTotal => itemDiscounts;
  int get taxableAmount => netSubtotal;
  int get grandTotal => finalTotal;
  int get serviceChargePercent => 0;
  int get taxPercent => 10;

  static const OrderTotals zero = OrderTotals(
    grossSubtotal: 0,
    itemDiscounts: 0,
    orderDiscount: 0,
    totalDiscount: 0,
    netSubtotal: 0,
    serviceCharge: 0,
    tax: 0,
    rounding: 0,
    finalTotal: 0,
  );
}

class OrderItemDraft {
  final String id;
  final int price;
  final int quantity;
  final int discount;

  const OrderItemDraft({
    required this.id,
    required this.price,
    required this.quantity,
    this.discount = 0,
  });
}

/// Client-side draft order math preview calculator.
/// Note: The backend server is strictly authoritative (computeOrderTotals).
/// This class provides instant reactive UI previews for the cashier and cart drawer.
class OrderMath {
  OrderMath._();

  static OrderTotals computeOrderTotals(OrderCalculationParams params) {
    // 1. Gross Subtotal & Item Discounts
    int grossSubtotal = 0;
    int itemDiscounts = 0;

    for (final item in params.items) {
      grossSubtotal += item.lineGrossTotal;
      itemDiscounts += item.itemDiscountAmount;
    }

    final subtotalAfterItemDiscounts = math.max(0, grossSubtotal - itemDiscounts);

    // 2. Order Level Discount (Percent or Nominal)
    int calculatedOrderDiscount = 0;
    if (params.orderDiscountPercent > 0) {
      calculatedOrderDiscount = (subtotalAfterItemDiscounts * (params.orderDiscountPercent / 100)).round();
    } else if (params.orderDiscountNominal > 0) {
      calculatedOrderDiscount = params.orderDiscountNominal;
    }

    // Discount cannot exceed subtotal
    final orderDiscount = math.min(subtotalAfterItemDiscounts, calculatedOrderDiscount);
    final totalDiscount = itemDiscounts + orderDiscount;
    final netSubtotal = math.max(0, grossSubtotal - totalDiscount);

    // 3. Service Charge
    final serviceCharge = (netSubtotal * params.serviceChargeRate).round();

    // 4. Tax (PB1 / PPN)
    final taxableBase = params.taxIncludesService ? (netSubtotal + serviceCharge) : netSubtotal;
    final tax = (taxableBase * params.taxRate).round();

    final subtotalWithTaxAndService = netSubtotal + serviceCharge + tax;

    // 5. Rounding
    int rounding = 0;
    if (params.roundingBase > 1 && subtotalWithTaxAndService > 0) {
      final remainder = subtotalWithTaxAndService % params.roundingBase;
      if (remainder != 0) {
        // Nearest rounding
        if (remainder >= (params.roundingBase / 2)) {
          rounding = params.roundingBase - remainder;
        } else {
          rounding = -remainder;
        }
      }
    }

    final finalTotal = math.max(0, subtotalWithTaxAndService + rounding);

    return OrderTotals(
      grossSubtotal: grossSubtotal,
      itemDiscounts: itemDiscounts,
      orderDiscount: orderDiscount,
      totalDiscount: totalDiscount,
      netSubtotal: netSubtotal,
      serviceCharge: serviceCharge,
      tax: tax,
      rounding: rounding,
      finalTotal: finalTotal,
    );
  }

  static OrderTotals calculateDraft({
    required List<OrderItemDraft> items,
    int voucherDiscount = 0,
    double taxPercent = 10.0,
    double serviceChargePercent = 0.0,
    int roundingBase = 0,
    // Backend applies tax and service independently on the after-discount
    // subtotal (see computeOrderTotals in tumbuh-be), not tax-on-service.
    bool taxIncludesService = false,
  }) {
    return computeOrderTotals(
      OrderCalculationParams(
        items: items
            .map((i) => OrderMathItem(
                  id: i.id,
                  name: '',
                  unitPrice: i.price,
                  quantity: i.quantity,
                  itemDiscountAmount: i.discount,
                ))
            .toList(),
        orderDiscountNominal: voucherDiscount,
        taxRate: taxPercent / 100.0,
        serviceChargeRate: serviceChargePercent / 100.0,
        roundingBase: roundingBase,
        taxIncludesService: taxIncludesService,
      ),
    );
  }

  static String formatCurrency(num amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final digits = absAmount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return '${isNegative ? "-Rp " : "Rp "}${buffer.toString()}';
  }
}

