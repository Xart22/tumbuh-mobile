import 'package:flutter/material.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/inventory_stock_model.dart';

class OwnerInventoryView extends StatefulWidget {
  final List<StockAlertItem> items;
  final void Function(String itemId, double quantity) onQuickReorder;

  const OwnerInventoryView({
    super.key,
    required this.items,
    required this.onQuickReorder,
  });

  @override
  State<OwnerInventoryView> createState() => _OwnerInventoryViewState();
}

class _OwnerInventoryViewState extends State<OwnerInventoryView> {
  String _selectedFilter = 'Kritis & Habis';

  void _showPoConfirmation(BuildContext context, StockAlertItem item) {
    double qty = item.suggestedReorderQuantity;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LpColors.surface,
        title: Row(
          children: [
            const Icon(Icons.post_add, color: LpColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Buat Purchase Order Cepat',
              style: LpTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: LpColors.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bahan: ${item.name}',
              style: LpTypography.bodySm.copyWith(
                fontWeight: FontWeight.bold,
                color: LpColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supplier: ${item.supplierName}',
              style: LpTypography.bodySm.copyWith(color: LpColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LpColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah Pesanan:',
                        style: LpTypography.bodySm.copyWith(color: LpColors.onSurfaceVariant),
                      ),
                      Text(
                        '$qty ${item.unit}',
                        style: LpTypography.mono.copyWith(
                          fontWeight: FontWeight.bold,
                          color: LpColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimasi Biaya:',
                        style: LpTypography.bodySm.copyWith(color: LpColors.onSurfaceVariant),
                      ),
                      Text(
                        OrderMath.formatCurrency((qty * item.estimatedPricePerUnit).round()),
                        style: LpTypography.mono.copyWith(
                          fontWeight: FontWeight.bold,
                          color: LpColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: LpColors.primary,
              foregroundColor: LpColors.onPrimary,
            ),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Kirim PO via WA'),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onQuickReorder(item.id, qty);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = widget.items.where((i) => i.isCritical).length;

    List<StockAlertItem> displayedItems = widget.items;
    if (_selectedFilter == 'Kritis & Habis') {
      displayedItems = widget.items.where((i) => i.isCritical).toList();
    } else if (_selectedFilter == 'Aman') {
      displayedItems = widget.items.where((i) => !i.isCritical).toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('Semua (48)'),
              const SizedBox(width: 8),
              _buildFilterButton('Kritis & Habis', count: criticalCount, isCriticalTag: true),
              const SizedBox(width: 8),
              _buildFilterButton('Aman (44)'),
              const SizedBox(width: 8),
              _buildFilterButton('Menunggu Kirim (2)'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Alert Banner Kritis
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), // amber-50
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade900),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$criticalCount Bahan Membutuhkan Restock!',
                            style: LpTypography.bodySm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF78350F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MENDESAK',
                            style: LpTypography.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biji kopi dan sirup diprediksi habis sebelum pukul 19:00 WIB berdasarkan traffic pesanan kasir.',
                      style: LpTypography.bodySm.copyWith(
                        color: Colors.amber.shade900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    'STATUS BAHAN BAKU',
                    style: LpTypography.labelSm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: LpColors.outline,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '(Diperbarui 15:42)',
                    style: LpTypography.mono.copyWith(
                      color: LpColors.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune, size: 14, color: LpColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Filter Kategori',
                  style: LpTypography.bodySm.copyWith(
                    color: LpColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 4. Stock Cards Feed
        ...displayedItems.map((item) => _buildStockCard(context, item)),
      ],
    );
  }

  Widget _buildFilterButton(String label, {int? count, bool isCriticalTag = false}) {
    final cleanLabel = label.split(' (')[0];
    final isSelected = _selectedFilter == cleanLabel || (_selectedFilter == 'Kritis & Habis' && isCriticalTag);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = cleanLabel;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isCriticalTag ? Colors.red.shade50 : LpColors.primary)
              : LpColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isCriticalTag ? Colors.red.shade300 : LpColors.primary)
                : LpColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCriticalTag) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              cleanLabel,
              style: LpTypography.labelSm.copyWith(
                color: isSelected
                    ? (isCriticalTag ? Colors.red.shade800 : LpColors.onPrimary)
                    : LpColors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isCriticalTag ? Colors.red : LpColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: LpTypography.mono.copyWith(
                    color: isCriticalTag ? Colors.white : LpColors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, StockAlertItem item) {
    final ratio = (item.currentStock / item.minStock).clamp(0.0, 1.0);
    final percentage = (ratio * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LpColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCritical ? Colors.red.shade200 : LpColors.outlineVariant.withAlpha(120),
          width: item.isCritical ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isCritical)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: Colors.red.shade600,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'KRITIS ($percentage%)',
                            style: LpTypography.mono.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Estimasi Habis: Shift 2',
                    style: LpTypography.bodySm.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.isCritical ? Colors.red.shade50 : LpColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.category.contains('Kopi') ? Icons.coffee : Icons.inventory_2_outlined,
                        color: item.isCritical ? Colors.red.shade700 : LpColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.category} • ${item.id.toUpperCase()}',
                            style: LpTypography.labelSm.copyWith(
                              color: LpColors.outline,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.name,
                            style: LpTypography.bodySm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: LpColors.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 12, color: LpColors.outline),
                              const SizedBox(width: 4),
                              Text(
                                item.supplierName,
                                style: LpTypography.bodySm.copyWith(
                                  color: LpColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stock Meter
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.isCritical ? Colors.red.shade50.withAlpha(120) : LpColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Sisa Stok Fisik:',
                              style: LpTypography.bodySm.copyWith(
                                color: LpColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.currentStock} ${item.unit}',
                                style: LpTypography.mono.copyWith(
                                  color: item.isCritical ? Colors.red.shade700 : LpColors.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                ' / Min ${item.minStock} ${item.unit}',
                                style: LpTypography.mono.copyWith(
                                  color: LpColors.outline,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: item.isCritical ? Colors.red.shade100 : LpColors.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.isCritical ? Colors.red.shade600 : LpColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Terakhir:',
                            style: LpTypography.bodySm.copyWith(
                              color: LpColors.outline,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            '${OrderMath.formatCurrency(item.estimatedPricePerUnit)}/${item.unit}',
                            style: LpTypography.mono.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: LpColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LpColors.primary,
                        foregroundColor: LpColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.post_add, size: 16),
                      label: const Text(
                        '+ Buat PO',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      onPressed: () => _showPoConfirmation(context, item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
