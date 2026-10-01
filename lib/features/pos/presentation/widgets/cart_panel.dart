import 'package:flutter/material.dart';
import '../../../../data/models/cart_item.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class CartPanel extends StatelessWidget {
  final List<CartItem> cartItems;
  final OrderTotals totals;
  final String tableNumber;
  final String orderType;
  final String customerName;
  final bool isMember;
  final int parkedBillCount;
  final Function(String lineId, int delta) onUpdateQuantity;
  final Function(String lineId) onRemoveItem;
  final VoidCallback onParkBill;
  final VoidCallback onOpenPayment;
  final VoidCallback? onSelectCustomer;
  final VoidCallback? onApplyVoucher;
  final VoidCallback? onRemoveVoucher;
  final Function(PosPaymentMethod method)? onQuickPay;

  const CartPanel({
    super.key,
    required this.cartItems,
    required this.totals,
    required this.tableNumber,
    required this.orderType,
    required this.customerName,
    required this.isMember,
    this.parkedBillCount = 0,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onParkBill,
    required this.onOpenPayment,
    this.onSelectCustomer,
    this.onApplyVoucher,
    this.onRemoveVoucher,
    this.onQuickPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: LpColors.surfacePanel,
        border: Border(left: BorderSide(color: LpColors.borderDark)),
      ),
      child: Column(
        children: [
          // 1. Header: Table info & Dine-in
          _buildCartHeader(),
          // 2. Action buttons: Member & Parkir Bill
          _buildQuickActionRow(context),
          // 3. Cart Items List
          Expanded(child: _buildItemList()),
          // 4. Totals & Checkout Actions
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: LpColors.surfaceCard,
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        children: [
          // Table pill
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF451A03).withAlpha(180),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: Center(
              child: Text(
                tableNumber,
                style: LpTypography.dataCurrencySm.copyWith(
                  color: LpColors.accentAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Meja $tableNumber',
                      style: LpTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withAlpha(180),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LpColors.primaryGreen.withAlpha(120)),
                      ),
                      child: Text(
                        orderType,
                        style: LpTypography.labelSm.copyWith(
                          color: LpColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tamu: $customerName (2 Org)',
                  style: LpTypography.bodySm.copyWith(
                    color: LpColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1116),
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        children: [
          // Member pill
          Expanded(
            child: GestureDetector(
              onTap: onSelectCustomer,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: LpColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LpColors.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, size: 16, color: LpColors.accentAmber),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Member: $customerName ⭐',
                        overflow: TextOverflow.ellipsis,
                        style: LpTypography.bodySm.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Parkir Bill (F2)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onParkBill,
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: LpColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD97706).withAlpha(150),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pause_circle_outline, size: 16, color: LpColors.accentAmber),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Parkir Bill (F2)',
                          overflow: TextOverflow.ellipsis,
                          style: LpTypography.bodySm.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFCD34D),
                          ),
                        ),
                      ),
                      if (parkedBillCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$parkedBillCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 48, color: LpColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Keranjang Masih Kosong',
              style: LpTypography.headlineSm.copyWith(
                color: LpColors.textMuted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih menu dari katalog di sebelah kiri',
              style: LpTypography.bodySm.copyWith(color: LpColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: cartItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),

      itemBuilder: (ctx, idx) {
        final item = cartItems[idx];
        return _buildCartItemCard(item);
      },
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LpColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: LpTypography.bodySm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(item.unitPrice),
                          style: LpTypography.dataCurrencySm.copyWith(
                            color: LpColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (item.unitPrice != item.product.price) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(Base ${CurrencyFormatter.format(item.product.price)})',
                            style: LpTypography.dataCurrencySm.copyWith(
                              color: LpColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Delete line
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: LpColors.textMuted),
                onPressed: () => onRemoveItem(item.id),
                tooltip: 'Hapus ${item.product.name}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          // Modifier badges
          if (item.selectedModifiers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.selectedModifiers.map((mod) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: LpColors.surfacePanel,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: LpColors.borderDark),
                  ),
                  child: Text(
                    mod.priceDelta > 0
                        ? '${mod.name} (+${CurrencyFormatter.format(mod.priceDelta)})'
                        : mod.name,
                    style: LpTypography.labelSm.copyWith(
                      color: mod.priceDelta > 0
                          ? LpColors.primaryLight
                          : const Color(0xFFFCD34D),
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // Kitchen notes
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🔥 ${item.notes}',
                style: LpTypography.bodySm.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const Divider(color: LpColors.borderDark, height: 16),
          // Bottom Stepper Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty & Catatan',
                style: LpTypography.labelSm.copyWith(
                  color: LpColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: LpColors.surfacePanel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LpColors.borderDark),
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Kurangi jumlah',
                      child: InkWell(
                        onTap: () => onUpdateQuantity(item.id, -1),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.remove, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: LpTypography.dataCurrencySm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Tambah jumlah',
                      child: InkWell(
                        onTap: () => onUpdateQuantity(item.id, 1),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: LpColors.surfaceCard,
        border: Border(top: BorderSide(color: LpColors.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subtotal (${cartItems.length} item)',
                  style: LpTypography.bodySm.copyWith(color: LpColors.textSecondary),
                ),
              ),
              Text(
                CurrencyFormatter.format(totals.subtotal),
                style: LpTypography.dataCurrencySm.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Voucher (tap to add / remove)
          GestureDetector(
            onTap: totals.voucherDiscount > 0 ? onRemoveVoucher : onApplyVoucher,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        totals.voucherDiscount > 0
                            ? Icons.local_offer
                            : Icons.add_card_rounded,
                        size: 14,
                        color: LpColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          totals.voucherDiscount > 0
                              ? 'Diskon Voucher Member'
                              : 'Tambah Voucher',
                          overflow: TextOverflow.ellipsis,
                          style: LpTypography.bodySm.copyWith(color: LpColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                if (totals.voucherDiscount > 0)
                  Text(
                    '-${CurrencyFormatter.format(totals.voucherDiscount)}',
                    style: LpTypography.dataCurrencySm.copyWith(
                      color: LpColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // PB1 Pajak Restoran 10%
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pajak Restoran (PB1 10%)',
                  style: LpTypography.bodySm.copyWith(color: LpColors.textSecondary),
                ),
              ),
              Text(
                CurrencyFormatter.format(totals.tax),
                style: LpTypography.dataCurrencySm.copyWith(color: Colors.white),
              ),
            ],
          ),
          const Divider(color: LpColors.borderDark, height: 18),
          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: LpTypography.labelSm.copyWith(
                        color: LpColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Termasuk PB1 & Layanan',
                      style: LpTypography.labelSm.copyWith(
                        color: LpColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(totals.grandTotal),
                style: LpTypography.dataCurrencyLg.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),


          // Quick Payment Method Chips
          Row(
            children: [
              _buildQuickPayChip('💵 Tunai', PosPaymentMethod.cash),
              const SizedBox(width: 6),
              _buildQuickPayChip('📱 QRIS', PosPaymentMethod.qris),
              const SizedBox(width: 6),
              _buildQuickPayChip('💳 Debit', PosPaymentMethod.debit),
            ],
          ),
          const SizedBox(height: 12),
          // Checkout Button (52px Emerald)
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: cartItems.isEmpty ? null : onOpenPayment,
              icon: const Icon(Icons.payments_outlined, size: 20),
              label: Text(
                'Lanjut Bayar (${CurrencyFormatter.format(totals.grandTotal)})',
                style: LpTypography.headlineSm.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LpColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPayChip(String label, PosPaymentMethod method) {
    return Expanded(
      child: OutlinedButton(
        onPressed: cartItems.isEmpty
            ? null
            : () {
                if (onQuickPay != null) {
                  onQuickPay!(method);
                } else {
                  onOpenPayment();
                }
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: LpColors.textPrimary,
          side: const BorderSide(color: LpColors.borderDark),
          backgroundColor: LpColors.surfacePanel,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: LpTypography.labelSm.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
