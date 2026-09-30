import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/product_modifier.dart';
import '../../../data/remote/pos_repository.dart';

import '../../../shared/math/order_math.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository posRepository;

  PosBloc({required this.posRepository}) : super(const PosState()) {
    on<PosLoadMenu>(_onLoadMenu);
    on<PosSelectCategory>(_onSelectCategory);
    on<PosSearchProducts>(_onSearchProducts);
    on<PosScanBarcode>(_onScanBarcode);
    on<PosAddToCart>(_onAddToCart);
    on<PosUpdateCartQuantity>(_onUpdateCartQuantity);
    on<PosRemoveCartItem>(_onRemoveCartItem);
    on<PosClearCart>(_onClearCart);
    on<PosSetTableNumber>(_onSetTableNumber);
    on<PosSetOrderType>(_onSetOrderType);
    on<PosSetCustomer>(_onSetCustomer);
    on<PosParkBill>(_onParkBill);
    on<PosRestoreParkedBill>(_onRestoreParkedBill);
    on<PosSubmitPayment>(_onSubmitPayment);
    on<PosUpdatePrinterConfig>(_onUpdatePrinterConfig);
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
      taxPercent: 10,
      serviceChargePercent: 0,
    );
  }

  Future<void> _onLoadMenu(PosLoadMenu event, Emitter<PosState> emit) async {
    emit(state.copyWith(status: PosStatus.loading));
    try {
      final categories = await posRepository.getCategories();
      final products = await posRepository.getProducts();

      // Initialize default cart items matching Stitch Screen 2d1abb020f314b258eae5cbb582c1616
      final arenProd = products.firstWhere(
        (p) => p.sku == 'KOP-AREN-01',
        orElse: () => products.first,
      );
      final croissantProd = products.firstWhere(
        (p) => p.sku == 'PAS-ALM-01',
        orElse: () => products[4],
      );
      final americanoProd = products.firstWhere(
        (p) => p.sku == 'KOP-AME-02',
        orElse: () => products[1],
      );

      final initialCart = [
        CartItem(
          id: 'cart-line-1',
          product: arenProd,
          quantity: 1,
          selectedModifiers: const [
            ModifierOption(id: 'sugar_50', name: 'Less Sugar 50%', priceDelta: 0),
            ModifierOption(id: 'milk_oat', name: 'Oat Milk Barista', priceDelta: 6000),
          ],
        ),
        CartItem(
          id: 'cart-line-2',
          product: croissantProd,
          quantity: 1,
          notes: 'Hangatkan / Toasting',
        ),
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

      emit(state.copyWith(
        status: PosStatus.ready,
        categories: categories,
        allProducts: products,
        filteredProducts: products,
        cartItems: initialCart,
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

  void _onRestoreParkedBill(PosRestoreParkedBill event, Emitter<PosState> emit) {
    final bills = posRepository.getParkedBills();
    final match = bills.firstWhere((b) => b.id == event.parkedBillId, orElse: () => bills.first);

    posRepository.removeParkedBill(match.id);
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
