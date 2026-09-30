import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/pos_product.dart';
import '../../../data/models/printer_config.dart';
import '../../../data/remote/pos_repository.dart';
import '../../../shared/math/order_math.dart';

enum PosStatus { initial, loading, ready, error, checkoutSuccess }

class PosState extends Equatable {
  final PosStatus status;
  final List<PosCategory> categories;
  final String selectedCategoryId;
  final String searchQuery;
  final List<PosProduct> allProducts;
  final List<PosProduct> filteredProducts;
  final List<CartItem> cartItems;
  final String tableNumber;
  final String orderType; // 'Dine-in' or 'Takeaway'
  final String customerName;
  final bool isMember;
  final int voucherDiscount;
  final List<ParkedBill> parkedBills;
  final OrderTotals totals;
  final PrinterDeviceConfig printerConfig;
  final Map<String, dynamic>? lastCheckoutResult;
  final String? errorMessage;

  const PosState({
    this.status = PosStatus.initial,
    this.categories = const [],
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.cartItems = const [],
    this.tableNumber = '04',
    this.orderType = 'Dine-in',
    this.customerName = 'Dian P.',
    this.isMember = true,
    this.voucherDiscount = 10000,
    this.parkedBills = const [],
    this.totals = OrderTotals.zero,

    this.printerConfig = const PrinterDeviceConfig(
      id: 'print-01',
      name: 'Epson TM-T82X (Thermal 80mm)',
      role: PrinterRole.cashier,
      connectionType: PrinterConnectionType.bluetooth,
      connectionAddress: '68:C6:3A:88:01',
      paperWidth: PrinterPaperWidth.mm80,
    ),
    this.lastCheckoutResult,
    this.errorMessage,
  });

  PosState copyWith({
    PosStatus? status,
    List<PosCategory>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    List<PosProduct>? allProducts,
    List<PosProduct>? filteredProducts,
    List<CartItem>? cartItems,
    String? tableNumber,
    String? orderType,
    String? customerName,
    bool? isMember,
    int? voucherDiscount,
    List<ParkedBill>? parkedBills,
    OrderTotals? totals,
    PrinterDeviceConfig? printerConfig,
    Map<String, dynamic>? lastCheckoutResult,
    String? errorMessage,
  }) {
    return PosState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      cartItems: cartItems ?? this.cartItems,
      tableNumber: tableNumber ?? this.tableNumber,
      orderType: orderType ?? this.orderType,
      customerName: customerName ?? this.customerName,
      isMember: isMember ?? this.isMember,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
      parkedBills: parkedBills ?? this.parkedBills,
      totals: totals ?? this.totals,
      printerConfig: printerConfig ?? this.printerConfig,
      lastCheckoutResult: lastCheckoutResult ?? this.lastCheckoutResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    selectedCategoryId,
    searchQuery,
    allProducts,
    filteredProducts,
    cartItems,
    tableNumber,
    orderType,
    customerName,
    isMember,
    voucherDiscount,
    parkedBills,
    totals,
    printerConfig,
    lastCheckoutResult,
    errorMessage,
  ];
}
