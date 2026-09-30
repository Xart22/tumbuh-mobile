import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tumbuh_mobile/data/models/cart_item.dart';
import 'package:tumbuh_mobile/data/models/pos_product.dart';


import 'package:tumbuh_mobile/features/pos/bloc/pos_bloc.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_event.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_state.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/cart_panel.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/customer_picker_modal.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/voucher_modal.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/payment_modal.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/product_card.dart';
import 'package:tumbuh_mobile/features/pos/presentation/widgets/product_options_modal.dart';
import 'package:tumbuh_mobile/shared/theme/app_colors.dart';
import 'package:tumbuh_mobile/shared/theme/app_typography.dart';


class PosTabletScreen extends StatefulWidget {
  final bool enableQrisTimer;
  const PosTabletScreen({super.key, this.enableQrisTimer = true});

  @override
  State<PosTabletScreen> createState() => _PosTabletScreenState();
}

class _PosTabletScreenState extends State<PosTabletScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load POS menu catalog if not already loaded
    if (context.read<PosBloc>().state.status == PosStatus.initial) {
      context.read<PosBloc>().add(const PosLoadMenu());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onProductTapped(PosProduct product) {
    if (product.hasModifiers) {
      ProductOptionsModal.show(
        context,
        product: product,
        onAddToCart: (item) {
          context.read<PosBloc>().add(PosAddToCart(item));
        },
      );
    } else {
      context.read<PosBloc>().add(PosAddToCart(CartItem.create(product: product)));
    }
  }

  void _openPaymentModal(BuildContext context, PosState state) {
    PaymentModal.show(
      context,
      grandTotal: state.totals.grandTotal,
      tableNumber: state.tableNumber,
      customerName: state.customerName,
      customerPhone: '0812-3456-7890',
      autoStartQrisTimer: widget.enableQrisTimer,
      onConfirmPayment: (paymentDetails) {
        context.read<PosBloc>().add(PosSubmitPayment(
          paymentDetails: paymentDetails,
          cashierName: 'Barista Rama',
        ));
      },
      onOpenCashDrawer: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laci kasir berhasil dibuka (RJ11 Pin 2 Pulse)'),
            backgroundColor: LpColors.primaryGreen,
          ),
        );
      },
    );
  }

  void _promptMoveTable(BuildContext context, String orderId, String currentTable) {
    final controller = TextEditingController(text: currentTable);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LpColors.surfaceCard,
        title: const Text('Pindah Meja', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Nomor meja tujuan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final table = controller.text.trim();
              Navigator.of(ctx).pop();
              if (table.isEmpty) return;
              context.read<PosBloc>().add(
                    PosMoveParkedBill(orderId: orderId, tableNumber: table),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pindah meja ke "$table" diproses.'),
                  backgroundColor: LpColors.accentAmber,
                ),
              );
            },
            child: const Text('Pindah'),
          ),
        ],
      ),
    );
  }

  void _showParkedBillsSheet(BuildContext context, PosState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LpColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        if (state.parkedBills.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Tidak ada bill yang sedang diparkir.', style: TextStyle(color: Colors.white)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.parkedBills.length,
          itemBuilder: (c, i) {
            final bill = state.parkedBills[i];
            return ListTile(
              title: Text('Tiket #${bill.ticketNumber} - Meja ${bill.tableNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${bill.items.length} item • ${bill.customerName}', style: const TextStyle(color: LpColors.textMuted)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _promptMoveTable(context, bill.id, bill.tableNumber);
                    },
                    child: const Text('Pindah'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.read<PosBloc>().add(PosRestoreParkedBill(bill.id));
                    },
                    child: const Text('Buka Kembali'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PosBloc, PosState>(
      listener: (context, state) {
        if (state.status == PosStatus.checkoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan berhasil diselesaikan! No Order: ${state.lastCheckoutResult?['orderId'] ?? ''}'),
              backgroundColor: LpColors.primaryGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: LpColors.surfaceDark,
          body: Column(
            children: [
              // ================= TOP HEADER BAR =================
              _buildHeader(context, state),
              // ================= MAIN SPLIT WORKSPACE =================
              Expanded(
                child: Row(
                  children: [
                    // LEFT: Catalog & Filter Section
                    Expanded(
                      child: _buildCatalogSection(context, state),
                    ),
                    // RIGHT: 380px Fixed Width Cart Drawer
                    CartPanel(
                      cartItems: state.cartItems,
                      totals: state.totals,
                      tableNumber: state.tableNumber,
                      orderType: state.orderType,
                      customerName: state.customerName,
                      isMember: state.isMember,
                      onSelectCustomer: () => CustomerPickerModal.show(context),
                      onApplyVoucher: () => VoucherModal.show(context),
                      onRemoveVoucher: () => context.read<PosBloc>().add(const PosRemoveVoucher()),
                      parkedBillCount: state.parkedBills.length,
                      onUpdateQuantity: (lineId, delta) {
                        context.read<PosBloc>().add(PosUpdateCartQuantity(lineId: lineId, delta: delta));
                      },
                      onRemoveItem: (lineId) {
                        context.read<PosBloc>().add(PosRemoveCartItem(lineId));
                      },
                      onParkBill: () {
                        if (state.cartItems.isNotEmpty) {
                          context.read<PosBloc>().add(const PosParkBill());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bill berhasil diparkir (F2)!'), backgroundColor: LpColors.accentAmber),
                          );
                        } else if (state.parkedBills.isNotEmpty) {
                          _showParkedBillsSheet(context, state);
                        }
                      },
                      onOpenPayment: () => _openPaymentModal(context, state),
                      onQuickPay: (method) => _openPaymentModal(context, state),
                    ),
                  ],
                ),
              ),
              // ================= BOTTOM HOTKEYS BAR =================
              _buildHotkeysFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PosState state) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: LpColors.surfacePanel,
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Logo & Outlet Info
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [LpColors.primaryGreen, Color(0xFF004F36)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: LpColors.primaryGreen.withAlpha(100)),
                  ),
                  child: const Center(
                    child: Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tumbuh',
                            style: LpTypography.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: LpColors.primaryLight.withAlpha(120)),
                            ),
                            child: Text(
                              'POS',
                              style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('|', style: TextStyle(color: LpColors.borderDark)),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: LpColors.accentAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Kopi Kita - Cabang Tebet',
                              style: LpTypography.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kasir: Barista Rama (Shift Pagi)',
                        style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Center: Operational Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF111923),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LpColors.primaryGreen.withAlpha(100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: LpColors.primaryLight, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Online', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text('•', style: TextStyle(color: LpColors.borderDark)),
                const SizedBox(width: 6),
                Text('Sync 0 pending', style: LpTypography.dataCurrencySm.copyWith(color: LpColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Right: Terminal Actions
          Row(
            children: [
              // Buka Laci Kasir
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laci kasir terbuka!'), backgroundColor: LpColors.accentAmber),
                  );
                },
                icon: const Icon(Icons.inbox, size: 16, color: LpColors.accentAmber),
                label: const Text('Buka Laci Kas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: LpColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              // Ganti Shift
              OutlinedButton.icon(
                onPressed: () => context.push('/shift'),
                icon: const Icon(Icons.swap_horiz, size: 16, color: LpColors.primaryLight),
                label: const Text('Ganti Shift'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: LpColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              // KDS (Kitchen Display System)
              IconButton(
                onPressed: () => context.push('/kds'),
                icon: const Icon(Icons.soup_kitchen_outlined, color: LpColors.accentAmber),
                tooltip: 'Kitchen Display System (KDS)',
                style: IconButton.styleFrom(
                  backgroundColor: LpColors.surfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              // Printer & Hardware Settings
              IconButton(
                onPressed: () => context.push('/printer-settings'),
                icon: const Icon(Icons.print_outlined, color: LpColors.primaryLight),
                tooltip: 'Manajemen Printer',
                style: IconButton.styleFrom(
                  backgroundColor: LpColors.surfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              // Lock / Logout
              IconButton(
                onPressed: () => context.go('/kasir-login'),
                icon: const Icon(Icons.lock_outline, color: LpColors.textSecondary),
                tooltip: 'Kunci Layar Kasir',
                style: IconButton.styleFrom(
                  backgroundColor: LpColors.surfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSection(BuildContext context, PosState state) {
    return Column(
      children: [
        // Search & Category Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: LpColors.surfacePanel,
            border: Border(bottom: BorderSide(color: LpColors.borderDark)),
          ),
          child: Column(
            children: [
              // Search Input & Barcode Scan
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (q) => context.read<PosBloc>().add(PosSearchProducts(q)),
                        style: LpTypography.bodyMd.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Cari menu, SKU, atau rasa (cth: Aren, Croissant, Cold Brew)...',
                          hintStyle: LpTypography.bodySm.copyWith(color: LpColors.textMuted),
                          prefixIcon: const Icon(Icons.search, size: 20, color: LpColors.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: LpColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<PosBloc>().add(const PosSearchProducts(''));
                                  },
                                )
                              : null,
                          fillColor: LpColors.surfaceCard,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: LpColors.borderDark),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: LpColors.primaryGreen),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Scan Barcode Button
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Simulate scanner input
                        context.read<PosBloc>().add(const PosScanBarcode('KOP-AREN-01'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Barcode KOP-AREN-01 discan!'), backgroundColor: LpColors.primaryGreen),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 20, color: LpColors.primaryLight),
                      label: const Text('Scan SKU'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: LpColors.borderDark),
                        backgroundColor: LpColors.surfaceCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Category filter pills
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),

                  itemBuilder: (ctx, idx) {
                    final cat = state.categories[idx];
                    final isSel = state.selectedCategoryId == cat.id;
                    return InkWell(
                      onTap: () => context.read<PosBloc>().add(PosSelectCategory(cat.id)),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? LpColors.primaryGreen : LpColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? LpColors.primaryLight : LpColors.borderDark,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: LpTypography.labelSm.copyWith(
                                color: isSel ? Colors.white : LpColors.textSecondary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Products 4-column Grid
        Expanded(
          child: state.filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada produk yang cocok dengan pencarian.',
                    style: LpTypography.bodyMd.copyWith(color: LpColors.textMuted),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.76,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.filteredProducts.length,
                  itemBuilder: (ctx, idx) {
                    final product = state.filteredProducts[idx];
                    return ProductCard(
                      product: product,
                      onTap: () => _onProductTapped(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHotkeysFooter() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF090B0E),
        border: Border(top: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildHotkeyTag('F1', 'Cari Menu'),
              const SizedBox(width: 14),
              _buildHotkeyTag('F2', 'Parkir Bill'),
              const SizedBox(width: 14),
              _buildHotkeyTag('F4', 'Buka Drawer'),
              const SizedBox(width: 14),
              _buildHotkeyTag('Space', 'Bayar Tunai Pas'),
            ],
          ),
          Row(
            children: [
              Text('Tumbuh POS v2.4.1 (Stable)', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 11)),
              const SizedBox(width: 8),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: LpColors.primaryLight, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Terminal #01', style: LpTypography.labelSm.copyWith(color: LpColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotkeyTag(String key, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: LpColors.surfaceCard,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: LpColors.borderDark),
          ),
          child: Text(
            key,
            style: LpTypography.dataCurrencySm.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
