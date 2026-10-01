import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/customer_summary.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/printer_config.dart';


abstract class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class PosLoadMenu extends PosEvent {
  const PosLoadMenu();
}

class PosSelectCategory extends PosEvent {
  final String categoryId;
  const PosSelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class PosSearchProducts extends PosEvent {
  final String query;
  const PosSearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class PosScanBarcode extends PosEvent {
  final String barcode;
  const PosScanBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class PosAddToCart extends PosEvent {
  final CartItem item;
  const PosAddToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class PosUpdateCartQuantity extends PosEvent {
  final String lineId;
  final int delta; // +1 or -1
  const PosUpdateCartQuantity({required this.lineId, required this.delta});

  @override
  List<Object?> get props => [lineId, delta];
}

class PosRemoveCartItem extends PosEvent {
  final String lineId;
  const PosRemoveCartItem(this.lineId);

  @override
  List<Object?> get props => [lineId];
}

class PosClearCart extends PosEvent {
  const PosClearCart();
}

/// Full per-session reset (logout / 401): cart, parkir, customer, voucher.
class PosSessionReset extends PosEvent {
  const PosSessionReset();
}

class PosSwitchOutlet extends PosEvent {
  final String outletId;
  const PosSwitchOutlet(this.outletId);

  @override
  List<Object?> get props => [outletId];
}

class PosSetTableNumber extends PosEvent {
  final String tableNumber;
  const PosSetTableNumber(this.tableNumber);

  @override
  List<Object?> get props => [tableNumber];
}

class PosSetOrderType extends PosEvent {
  final String orderType;
  const PosSetOrderType(this.orderType);

  @override
  List<Object?> get props => [orderType];
}

class PosSetCustomer extends PosEvent {
  final String customerName;
  final bool isMember;
  final int voucherDiscount;
  const PosSetCustomer({
    required this.customerName,
    this.isMember = false,
    this.voucherDiscount = 0,
  });

  @override
  List<Object?> get props => [customerName, isMember, voucherDiscount];
}

class PosSearchCustomers extends PosEvent {
  final String query;
  const PosSearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}

class PosSelectCustomer extends PosEvent {
  final CustomerSummary customer;
  const PosSelectCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class PosClearCustomer extends PosEvent {
  const PosClearCustomer();
}

class PosMoveParkedBill extends PosEvent {
  final String orderId;
  final String tableNumber;
  const PosMoveParkedBill({required this.orderId, required this.tableNumber});

  @override
  List<Object?> get props => [orderId, tableNumber];
}

class PosApplyVoucher extends PosEvent {
  final String code;
  const PosApplyVoucher(this.code);

  @override
  List<Object?> get props => [code];
}

class PosRemoveVoucher extends PosEvent {
  const PosRemoveVoucher();
}

class PosParkBill extends PosEvent {
  const PosParkBill();
}

class PosRestoreParkedBill extends PosEvent {
  final String parkedBillId;
  const PosRestoreParkedBill(this.parkedBillId);

  @override
  List<Object?> get props => [parkedBillId];
}

class PosSubmitPayment extends PosEvent {
  final OrderPaymentDetails paymentDetails;
  final String cashierName;

  const PosSubmitPayment({
    required this.paymentDetails,
    required this.cashierName,
  });

  @override
  List<Object?> get props => [paymentDetails, cashierName];
}

class PosUpdatePrinterConfig extends PosEvent {
  final PrinterDeviceConfig config;
  const PosUpdatePrinterConfig(this.config);

  @override
  List<Object?> get props => [config];
}
