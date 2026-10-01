import 'package:flutter/material.dart';
import '../../../../data/models/cart_item.dart';
import '../../../../data/models/pos_product.dart';
import '../../../../data/models/product_modifier.dart';
import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class ProductOptionsModal extends StatefulWidget {
  final PosProduct product;

  /// Modifier groups to render (already loaded/merged by the caller).
  final List<ModifierGroup> groups;
  final Function(CartItem item) onAddToCart;

  const ProductOptionsModal({
    super.key,
    required this.product,
    required this.groups,
    required this.onAddToCart,
  });

  static Future<void> show(
    BuildContext context, {
    required PosProduct product,
    required List<ModifierGroup> groups,
    required Function(CartItem item) onAddToCart,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: LpColors.darkScrim,
      builder: (ctx) => ProductOptionsModal(
        product: product,
        groups: groups,
        onAddToCart: onAddToCart,
      ),
    );
  }

  @override
  State<ProductOptionsModal> createState() => _ProductOptionsModalState();
}

class _ProductOptionsModalState extends State<ProductOptionsModal> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();
  final Map<String, List<ModifierOption>> _selectedModifiers = {};

  @override
  void initState() {
    super.initState();
    // Initialize default selections
    for (final group in widget.groups) {
      final defaults = group.options.where((o) => o.isDefault).toList();
      if (defaults.isNotEmpty) {
        _selectedModifiers[group.id] = defaults;
      } else if (group.selectionType == ModifierSelectionType.singleRequired &&
          group.options.isNotEmpty) {
        _selectedModifiers[group.id] = [group.options.first];
      } else {
        _selectedModifiers[group.id] = [];
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleOption(ModifierGroup group, ModifierOption option) {
    setState(() {
      final currentList = List<ModifierOption>.from(_selectedModifiers[group.id] ?? []);

      if (group.selectionType == ModifierSelectionType.singleRequired) {
        _selectedModifiers[group.id] = [option];
      } else {
        // Multi selection
        final exists = currentList.any((o) => o.id == option.id);
        if (exists) {
          currentList.removeWhere((o) => o.id == option.id);
        } else {
          if (currentList.length < group.maxSelection) {
            currentList.add(option);
          }
        }
        _selectedModifiers[group.id] = currentList;
      }
    });
  }

  List<ModifierOption> get _allSelectedModifiers {
    final list = <ModifierOption>[];
    for (final entry in _selectedModifiers.values) {
      list.addAll(entry);
    }
    return list;
  }

  int get _unitPrice {
    final modTotal = _allSelectedModifiers.fold<int>(0, (sum, m) => sum + m.priceDelta);
    return widget.product.price + modTotal;
  }

  int get _totalPrice => _unitPrice * _quantity;

  void _submit() {
    final item = CartItem.create(
      product: widget.product,
      selectedModifiers: _allSelectedModifiers,
      quantity: _quantity,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    widget.onAddToCart(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 1000,
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: LpColors.surfaceModal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LpColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(200),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in widget.groups) ...[
                      _buildModifierGroup(group),
                      const SizedBox(height: 24),
                    ],
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),
            // Sticky Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141820),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LpColors.borderDark),
            ),
            child: const Center(
              child: Icon(Icons.coffee_rounded, color: LpColors.primaryGreen, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withAlpha(180),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LpColors.primaryGreen.withAlpha(120)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.coffee, size: 12, color: LpColors.primaryLight),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.categoryName,
                            style: LpTypography.labelSm.copyWith(
                              color: LpColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.product.isBestSeller) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF451A03).withAlpha(180),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD97706)),
                        ),
                        child: Text(
                          '★ Menu Terlaris #1',
                          style: LpTypography.labelSm.copyWith(
                            color: const Color(0xFFFCD34D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.name,
                  style: LpTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Harga Dasar: ',
                      style: LpTypography.bodySm.copyWith(color: LpColors.textMuted),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.product.price),
                      style: LpTypography.dataCurrencySm.copyWith(
                        color: LpColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // SKU and Close Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SKU: ${widget.product.sku}',
                style: LpTypography.dataCurrencySm.copyWith(
                  color: LpColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: LpColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stok Tersedia: ${widget.product.stockQuantity.toInt()} porsi',
                    style: LpTypography.labelSm.copyWith(
                      color: LpColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Cancel / Close
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Batal (Esc)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LpColors.textSecondary,
              side: const BorderSide(color: LpColors.borderDark),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierGroup(ModifierGroup group) {
    final selectedInGroup = _selectedModifiers[group.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: LpColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.name,
                  style: LpTypography.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: LpColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: group.isRequired
                        ? const Color(0xFF064E3B).withAlpha(160)
                        : const Color(0xFF451A03).withAlpha(160),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: group.isRequired
                          ? LpColors.primaryGreen.withAlpha(120)
                          : LpColors.accentAmber.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    group.isRequired ? 'WAJIB (PILIH 1)' : 'OPSIONAL (BISA BANYAK)',
                    style: LpTypography.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: group.isRequired
                          ? LpColors.primaryLight
                          : LpColors.accentAmber,
                    ),
                  ),
                ),
              ],
            ),
            if (group.subtitle != null)
              Text(
                group.subtitle!,
                style: LpTypography.labelSm.copyWith(color: LpColors.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Grid options
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: group.options.map((option) {
            final isSelected = selectedInGroup.any((o) => o.id == option.id);
            return _buildOptionCard(group, option, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    ModifierGroup group,
    ModifierOption option,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleOption(group, option),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? LpColors.surfaceCardActive : LpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? LpColors.primaryGreen : LpColors.borderDark,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      option.name,
                      style: LpTypography.bodySm.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : LpColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: isSelected ? LpColors.primaryLight : LpColors.textMuted,
                  ),
                ],
              ),
              if (option.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  option.subtitle!,
                  style: LpTypography.labelSm.copyWith(
                    color: isSelected ? LpColors.primaryLight : LpColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                option.priceDelta > 0
                    ? '+${CurrencyFormatter.format(option.priceDelta)}'
                    : '+Rp 0',
                style: LpTypography.dataCurrencySm.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: option.priceDelta > 0
                      ? LpColors.primaryLight
                      : LpColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CATATAN KHUSUS UNTUK BARISTA & KITCHEN',
              style: LpTypography.labelMd.copyWith(
                fontWeight: FontWeight.bold,
                color: LpColors.textPrimary,
              ),
            ),
            Text(
              'Muncul di KDS & Struk',
              style: LpTypography.labelSm.copyWith(color: LpColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          style: LpTypography.bodyMd.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ketik catatan khusus (mis. Pisahkan es batu di cup terpisah, latte art love)...',
            hintStyle: LpTypography.bodySm.copyWith(color: LpColors.textMuted),
            fillColor: const Color(0xFF12151C),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: LpColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: LpColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Preset quick chips
        Row(
          children: [
            Text(
              'Preset Cepat: ',
              style: LpTypography.labelSm.copyWith(color: LpColors.textMuted),
            ),
            const SizedBox(width: 8),
            _buildPresetChip('Cup Takeaway Terpisah'),
            const SizedBox(width: 8),
            _buildPresetChip('Hangatkan Sedikit'),
            const SizedBox(width: 8),
            _buildPresetChip('Double Cup Pelindung'),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label) {
    return ActionChip(
      label: Text(label, style: LpTypography.labelSm.copyWith(color: LpColors.textPrimary, fontSize: 11)),
      backgroundColor: LpColors.surfaceCard,
      side: const BorderSide(color: LpColors.borderDark),
      onPressed: () {
        setState(() {
          if (_notesController.text.isEmpty) {
            _notesController.text = label;
          } else {
            _notesController.text = '${_notesController.text}, $label';
          }
        });
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF13171E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Quantity stepper
          Row(
            children: [
              Text(
                'JUMLAH',
                style: LpTypography.labelSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: LpColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LpColors.borderDark),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: LpTypography.headlineSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Price Calculation Breakdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Subtotal Produk',
                style: LpTypography.labelSm.copyWith(color: LpColors.textMuted),
              ),
              Text(
                CurrencyFormatter.format(_totalPrice),
                style: LpTypography.dataCurrencyLg.copyWith(
                  color: LpColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Submit Button (52px Emerald)
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('Tambah ke Keranjang • ${CurrencyFormatter.format(_totalPrice)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LpColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: LpTypography.headlineSm.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
