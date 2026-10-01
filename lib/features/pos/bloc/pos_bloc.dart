import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/outlet_pricing.dart';
import '../../../data/models/pos_product.dart';
import '../../../data/models/product_modifier.dart';
import '../../../data/remote/pos_repository.dart';

import '../../../shared/math/order_math.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository posRepository;

  /// Active outlet pricing; refreshed on menu load, defaults until then.
  OutletPricing _pricing = OutletPricing.legacy;

  PosBloc({required this.posRepository}) : super(const PosState()) {
    on<PosLoadMenu>(_onLoadMenu);
    on<PosSelectCategory>(_onSelectCategory);
    on<PosSearchProducts>(_onSearchProducts);
    on<PosScanBarcode>(_onScanBarcode);
    on<PosAddToCart>(_onAddToCart);
    on<PosUpdateCartQuantity>(_onUpdateCartQuantity);
    on<PosRemoveCartItem>(_onRemoveCartItem);
    on<PosClearCart>(_onClearCart);
    on<PosSessionReset>(_onSessionReset);
    on<PosSwitchOutlet>(_onSwitchOutlet);
    on<PosSetTableNumber>(_onSetTableNumber);
    on<PosSetOrderType>(_onSetOrderType);
    on<PosSetCustomer>(_onSetCustomer);
    on<PosSearchCustomers>(_onSearchCustomers);
    on<PosSelectCustomer>(_onSelectCustomer);
    on<PosClearCustomer>(_onClearCustomer);
    on<PosApplyVoucher>(_onApplyVoucher);
    on<PosRemoveVoucher>(_onRemoveVoucher);
    on<PosMoveParkedBill>(_onMoveParkedBill);
    on<PosParkBill>(_onParkBill);
    on<PosRestoreParkedBill>(_onRestoreParkedBill);
    on<PosSubmitPayment>(_onSubmitPayment);
    on<PosUpdatePrinterConfig>(_onUpdatePrinterConfig);
  }

  /// Loads backend modifier groups for a product (used by the options modal).
  Future<List<ModifierGroup>> loadModifiers(String productId) =>
      posRepository.getProductModifiers(productId);

  /// Barcode/SKU lookup for the scanner (backend exact match, local fallback).
  Future<PosProduct?> lookupProduct(String code) =>
      posRepository.lookupByCode(code);

  /// True once the backend marks an order paid (QRIS/e-wallet webhook settle).
  Future<bool> isOrderPaid(String serverOrderId) async {
    final status = await posRepository.fetchOrderPaymentStatus(serverOrderId);
    return status == 'paid';
  }

  OrderTotals _recalculateTotals(List<CartItem> items, int voucherDiscount) {
    final orderDraftItems = items.map((ci) {
      return OrderItemDraft(
        id: ci.id,
        price: ci.unitPrice,
        quantity: ci.quantity,
        discount: ci.itemDiscount,
      );
    }).toList();

    return OrderMath.calculateDraft(
      items: orderDraftItems,
      voucherDiscount: voucherDiscount,
      taxPercent: _pricing.taxEnabled ? _pricing.taxRate : 0,
      serviceChargePercent:
          _pricing.serviceChargeEnabled ? _pricing.serviceChargeRate : 0,
      roundingBase: _pricing.roundingBase,
    );
  }

  Future<void> _onLoadMenu(PosLoadMenu event, Emitter<PosState> emit) async {
    emit(state.copyWith(status: PosStatus.loading));
    try {
      _pricing = await posRepository.getOutletPricing() ?? OutletPricing.legacy;
      final categories = await posRepository.getCategories();
      final products = await posRepository.getProducts();

      // Demo cart only when the bundled seed SKUs are present. With a real
      // backend catalog these SKUs differ, so the cart starts empty instead of
      // fabricating lines. ponytail: drop entirely once seed fallback is gone.
      PosProduct? bySku(String sku) {
        for (final p in products) {
          if (p.sku == sku) return p;
        }
        return null;
      }

      final arenProd = bySku('KOP-AREN-01');
      final croissantProd = bySku('PAS-ALM-01');
      final americanoProd = bySku('KOP-AME-02');

      final initialCart = <CartItem>[
        if (arenProd != null)
          CartItem(
            id: 'cart-line-1',
            product: arenProd,
            quantity: 1,
            selectedModifiers: const [
              ModifierOption(id: 'sugar_50', name: 'Less Sugar 50%', priceDelta: 0),
              ModifierOption(id: 'milk_oat', name: 'Oat Milk Barista', priceDelta: 6000),
            ],
          ),
        if (croissantProd != null)
          CartItem(
            id: 'cart-line-2',
            product: croissantProd,
            quantity: 1,
            notes: 'Hangatkan / Toasting',
          ),
        if (americanoProd != null)
          CartItem(
            id: 'cart-line-3',
            product: americanoProd,
            quantity: 1,
            selectedModifiers: const [
              ModifierOption(id: 'top_syrup', name: 'Syrup Hazelnut', priceDelta: 4000),
            ],
          ),
      ];

      final totals = _recalculateTotals(initialCart, state.voucherDiscount);
      final parkedBills = await posRepository.fetchParkedBills();
      final outlets = await posRepository.fetchOutlets();
      final activeOutletId = await posRepository.getActiveOutletId() ??
          (outlets.isNotEmpty ? outlets.first.id : null);

      emit(state.copyWith(
        status: PosStatus.ready,
        categories: categories,
        allProducts: products,
        filteredProducts: products,
        cartItems: initialCart,
        parkedBills: parkedBills,
        outlets: outlets,
        activeOutletId: activeOutletId,
        totals: totals,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PosStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSelectCategory(PosSelectCategory event, Emitter<PosState> emit) {
    final catId = event.categoryId;
    var filtered = state.allProducts;
    if (catId != 'all') {
      filtered = filtered.where((p) => p.categoryId == catId).toList();
    }
    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
    }
    emit(state.copyWith(
      selectedCategoryId: catId,
      filteredProducts: filtered,
    ));
  }

  void _onSearchProducts(PosSearchProducts event, Emitter<PosState> emit) {
    final query = event.query;
    var filtered = state.allProducts;
    if (state.selectedCategoryId != 'all') {
      filtered = filtered.where((p) => p.categoryId == state.selectedCategoryId).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.barcode != null && p.barcode!.contains(q)) ||
            (p.description != null && p.description!.toLowerCase().contains(q));
      }).toList();
    }
    emit(state.copyWith(
      searchQuery: query,
      filteredProducts: filtered,
    ));
  }

  Future<void> _onScanBarcode(PosScanBarcode event, Emitter<PosState> emit) async {
    final product = await posRepository.lookupByCode(event.barcode);
    if (product != null) {
      // Add directly if no modifiers required
      if (!product.hasModifiers) {
        add(PosAddToCart(CartItem.create(product: product)));
      }
    }
  }

  void _onAddToCart(PosAddToCart event, Emitter<PosState> emit) {
    final currentList = List<CartItem>.from(state.cartItems);

    // If exact same product and modifiers exist, increment quantity
    final existingIdx = currentList.indexWhere((ci) =>
        ci.product.id == event.item.product.id &&
        ci.selectedModifiers == event.item.selectedModifiers &&
        ci.notes == event.item.notes);

    if (existingIdx >= 0) {
      final existing = currentList[existingIdx];
      currentList[existingIdx] = existing.copyWith(quantity: existing.quantity + event.item.quantity);
    } else {
      currentList.add(event.item);
    }

    final totals = _recalculateTotals(currentList, state.voucherDiscount);
    emit(state.copyWith(cartItems: currentList, totals: totals));
  }

  void _onUpdateCartQuantity(PosUpdateCartQuantity event, Emitter<PosState> emit) {
    final currentList = List<CartItem>.from(state.cartItems);
    final idx = currentList.indexWhere((ci) => ci.id == event.lineId);
    if (idx >= 0) {
      final item = currentList[idx];
      final newQty = item.quantity + event.delta;
      if (newQty <= 0) {
        currentList.removeAt(idx);
      } else {
        currentList[idx] = item.copyWith(quantity: newQty);
      }
      final totals = _recalculateTotals(currentList, state.voucherDiscount);
      emit(state.copyWith(cartItems: currentList, totals: totals));
    }
  }

  void _onRemoveCartItem(PosRemoveCartItem event, Emitter<PosState> emit) {
    final currentList = List<CartItem>.from(state.cartItems)
      ..removeWhere((ci) => ci.id == event.lineId);
    final totals = _recalculateTotals(currentList, state.voucherDiscount);
    emit(state.copyWith(cartItems: currentList, totals: totals));
  }

  void _onClearCart(PosClearCart event, Emitter<PosState> emit) {
    final totals = _recalculateTotals(const [], 0);
    emit(state.copyWith(cartItems: const [], voucherDiscount: 0, totals: totals));
  }

  Future<void> _onSwitchOutlet(PosSwitchOutlet event, Emitter<PosState> emit) async {
    await posRepository.switchOutlet(event.outletId);
    emit(state.copyWith(activeOutletId: event.outletId));
    add(const PosLoadMenu());
  }

  void _onSessionReset(PosSessionReset event, Emitter<PosState> emit) {
    posRepository.clearLocalParkedBills();
    final totals = _recalculateTotals(const [], 0);
    emit(state.copyWith(
      cartItems: const [],
      voucherDiscount: 0,
      clearVoucher: true,
      clearVoucherError: true,
      clearCustomer: true,
      customerName: 'Tamu',
      isMember: false,
      customerResults: const [],
      parkedBills: const [],
      totals: totals,
    ));
  }

  void _onSetTableNumber(PosSetTableNumber event, Emitter<PosState> emit) {
    emit(state.copyWith(tableNumber: event.tableNumber));
  }

  void _onSetOrderType(PosSetOrderType event, Emitter<PosState> emit) {
    emit(state.copyWith(orderType: event.orderType));
  }

  void _onSetCustomer(PosSetCustomer event, Emitter<PosState> emit) {
    final totals = _recalculateTotals(state.cartItems, event.voucherDiscount);
    emit(state.copyWith(
      customerName: event.customerName,
      isMember: event.isMember,
      voucherDiscount: event.voucherDiscount,
      totals: totals,
    ));
  }

  Future<void> _onSearchCustomers(
    PosSearchCustomers event,
    Emitter<PosState> emit,
  ) async {
    final results = await posRepository.searchCustomers(event.query);
    emit(state.copyWith(customerResults: results));
  }

  void _onSelectCustomer(PosSelectCustomer event, Emitter<PosState> emit) {
    emit(state.copyWith(
      customerId: event.customer.id,
      customerName: event.customer.name,
      isMember: true,
    ));
  }

  void _onClearCustomer(PosClearCustomer event, Emitter<PosState> emit) {
    emit(state.copyWith(
      clearCustomer: true,
      customerName: 'Tamu',
      isMember: false,
    ));
  }

  Future<void> _onApplyVoucher(
    PosApplyVoucher event,
    Emitter<PosState> emit,
  ) async {
    emit(state.copyWith(clearVoucherError: true));
    try {
      final validation = await posRepository.validateVoucher(
        code: event.code,
        orderTotal: state.totals.grossSubtotal,
      );
      final totals =
          _recalculateTotals(state.cartItems, validation.discountAmount);
      emit(state.copyWith(
        voucherDiscount: validation.discountAmount,
        appliedVoucherCode: validation.code,
        clearVoucherError: true,
        totals: totals,
      ));
    } catch (e) {
      emit(state.copyWith(
        clearVoucher: true,
        voucherDiscount: 0,
        voucherError: e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('ValidationException: ', '')
            .replaceAll('NotFoundException: ', ''),
      ));
    }
  }

  void _onRemoveVoucher(PosRemoveVoucher event, Emitter<PosState> emit) {
    final totals = _recalculateTotals(state.cartItems, 0);
    emit(state.copyWith(
      voucherDiscount: 0,
      clearVoucher: true,
      clearVoucherError: true,
      totals: totals,
    ));
  }

  Future<void> _onMoveParkedBill(
    PosMoveParkedBill event,
    Emitter<PosState> emit,
  ) async {
    final tableId = await posRepository.resolveTableId(event.tableNumber);
    if (tableId == null) {
      emit(state.copyWith(
        errorMessage: 'Meja "${event.tableNumber}" tidak ditemukan.',
      ));
      return;
    }
    final moved = await posRepository.moveOrderTable(event.orderId, tableId);
    if (!moved) {
      emit(state.copyWith(errorMessage: 'Gagal memindahkan meja.'));
      return;
    }
    final parked = await posRepository.fetchParkedBills();
    emit(state.copyWith(parkedBills: parked, errorMessage: ''));
  }

  Future<void> _onParkBill(PosParkBill event, Emitter<PosState> emit) async {
    if (state.cartItems.isEmpty) return;

    await posRepository.parkBill(
      tableNumber: state.tableNumber,
      orderType: state.orderType,
      customerName: state.customerName,
      items: state.cartItems,
    );

    final bills = posRepository.getParkedBills();
    final clearedTotals = _recalculateTotals(const [], 0);

    emit(state.copyWith(
      cartItems: const [],
      parkedBills: bills,
      totals: clearedTotals,
    ));
  }

  Future<void> _onRestoreParkedBill(PosRestoreParkedBill event, Emitter<PosState> emit) async {
    final bills = posRepository.getParkedBills();
    final match = bills.firstWhere((b) => b.id == event.parkedBillId, orElse: () => bills.first);

    await posRepository.resumeParkedBill(match.id);
    final remainingBills = posRepository.getParkedBills();
    final totals = _recalculateTotals(match.items, state.voucherDiscount);

    emit(state.copyWith(
      cartItems: match.items,
      tableNumber: match.tableNumber,
      orderType: match.orderType,
      customerName: match.customerName,
      parkedBills: remainingBills,
      totals: totals,
    ));
  }

  Future<void> _onSubmitPayment(PosSubmitPayment event, Emitter<PosState> emit) async {
    emit(state.copyWith(status: PosStatus.loading));
    try {
      final result = await posRepository.submitOrderAndPayment(
        tableNumber: state.tableNumber,
        orderType: state.orderType,
        customerName: state.customerName,
        cashierName: event.cashierName,
        items: state.cartItems,
        totals: state.totals,
        payment: event.paymentDetails,
        customerId: state.customerId,
        printerConfig: state.printerConfig,
      );

      final resetTotals = _recalculateTotals(const [], 0);
      emit(state.copyWith(
        status: PosStatus.checkoutSuccess,
        cartItems: const [],
        totals: resetTotals,
        lastCheckoutResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PosStatus.error,
        errorMessage: 'Gagal menyelesaikan pembayaran: $e',
      ));
    }
  }

  void _onUpdatePrinterConfig(PosUpdatePrinterConfig event, Emitter<PosState> emit) {
    emit(state.copyWith(printerConfig: event.config));
  }
}
