import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/customer_summary.dart';
import '../../../data/models/outlet_summary.dart';
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
  final String? customerId;
  final String? customerPhone;
  final bool isMember;
  final List<CustomerSummary> customerResults;
  final List<OutletSummary> outlets;
  final String? activeOutletId;
  final int voucherDiscount;
  final String? appliedVoucherCode;
  final String? voucherError;
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
    this.tableNumber = '-',
    this.orderType = 'Dine-in',
    this.customerName = 'Tamu',
    this.customerId,
    this.customerPhone,
    this.isMember = false,
    this.customerResults = const [],
    this.outlets = const [],
    this.activeOutletId,
    this.voucherDiscount = 0,
    this.appliedVoucherCode,
    this.voucherError,
    this.parkedBills = const [],
    this.totals = OrderTotals.zero,

    this.printerConfig = const PrinterDeviceConfig(
      id: 'unset',
      name: 'Belum ada printer (atur di Manajemen Printer)',
      role: PrinterRole.cashier,
      connectionType: PrinterConnectionType.network,
      connectionAddress: '',
      isConnected: false,
      batteryPercent: 0,
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
    String? customerId,
    String? customerPhone,
    bool clearCustomer = false,
    bool? isMember,
    List<CustomerSummary>? customerResults,
    List<OutletSummary>? outlets,
    String? activeOutletId,
    int? voucherDiscount,
    String? appliedVoucherCode,
    bool clearVoucher = false,
    String? voucherError,
    bool clearVoucherError = false,
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
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerPhone:
          clearCustomer ? null : (customerPhone ?? this.customerPhone),
      isMember: isMember ?? this.isMember,
      customerResults: customerResults ?? this.customerResults,
      outlets: outlets ?? this.outlets,
      activeOutletId: activeOutletId ?? this.activeOutletId,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
      appliedVoucherCode:
          clearVoucher ? null : (appliedVoucherCode ?? this.appliedVoucherCode),
      voucherError:
          clearVoucherError ? null : (voucherError ?? this.voucherError),
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
    customerId,
    customerPhone,
    isMember,
    customerResults,
    outlets,
    activeOutletId,
    voucherDiscount,
    appliedVoucherCode,
    voucherError,
    parkedBills,
    totals,
    printerConfig,
    lastCheckoutResult,
    errorMessage,
  ];
}
