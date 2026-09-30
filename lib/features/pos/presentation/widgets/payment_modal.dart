import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class PaymentModal extends StatefulWidget {
  final int grandTotal;
  final String tableNumber;
  final String customerName;
  final String? customerPhone;
  final Function(OrderPaymentDetails details) onConfirmPayment;
  final VoidCallback onOpenCashDrawer;
  final bool autoStartQrisTimer;

  const PaymentModal({
    super.key,
    required this.grandTotal,
    required this.tableNumber,
    required this.customerName,
    this.customerPhone = '0812-3456-7890',
    required this.onConfirmPayment,
    required this.onOpenCashDrawer,
    this.autoStartQrisTimer = false,
  });

  static Future<void> show(
    BuildContext context, {
    required int grandTotal,
    required String tableNumber,
    required String customerName,
    String? customerPhone,
    required Function(OrderPaymentDetails details) onConfirmPayment,
    required VoidCallback onOpenCashDrawer,
    bool autoStartQrisTimer = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: LpColors.darkScrim,
      builder: (ctx) => PaymentModal(
        grandTotal: grandTotal,
        tableNumber: tableNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        onConfirmPayment: onConfirmPayment,
        onOpenCashDrawer: onOpenCashDrawer,
        autoStartQrisTimer: autoStartQrisTimer,
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  bool _isSplitPayment = true; // Defaults to Split mode matching Stitch screen 2b3e8ada336846cd9a08e31d0014dbcf
  PosPaymentMethod _singleMethod = PosPaymentMethod.cash;

  // Split details
  late int _split1QrisAmount;
  late int _split2CashAmount;
  int _cashReceived = 50000;

  // Full payment cash details
  late int _fullCashReceived;

  // Options
  bool _printPhysicalReceipt = true;
  bool _sendWhatsAppReceipt = true;

  // Timer simulation for QRIS
  int _qrisSecondsLeft = 298; // 04:58
  Timer? _qrisTimer;

  @override
  void initState() {
    super.initState();
    // Default split allocation matching Stitch design (e.g. 50k QRIS, remainder cash)
    if (widget.grandTotal > 50000) {
      _split1QrisAmount = 50000;
      _split2CashAmount = widget.grandTotal - 50000;
    } else {
      _split1QrisAmount = widget.grandTotal ~/ 2;
      _split2CashAmount = widget.grandTotal - _split1QrisAmount;
    }
    _fullCashReceived = widget.grandTotal;

    if (widget.autoStartQrisTimer) {
      _qrisTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _qrisSecondsLeft > 0) {
          setState(() => _qrisSecondsLeft--);
        }
      });
    }
  }

  @override
  void dispose() {
    _qrisTimer?.cancel();
    super.dispose();
  }

  String get _qrisTimerText {
    final m = (_qrisSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_qrisSecondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s detik';
  }

  int get _splitCashChange {
    final diff = _cashReceived - _split2CashAmount;
    return diff > 0 ? diff : 0;
  }

  int get _fullCashChange {
    final diff = _fullCashReceived - widget.grandTotal;
    return diff > 0 ? diff : 0;
  }

  String _calculatePecahanSaran(int kembalian) {
    if (kembalian <= 0) return 'Tidak ada kembalian';
    final parts = <String>[];
    int remaining = kembalian;

    final denominations = [100000, 50000, 20000, 10000, 5000, 2000, 1000, 500, 200, 100];
    for (final denom in denominations) {
      final count = remaining ~/ denom;
      if (count > 0) {
        parts.add('${count}x ${CurrencyFormatter.format(denom)}');
        remaining %= denom;
      }
    }
    return parts.take(3).join(' + ');
  }

  void _confirm() {
    OrderPaymentDetails details;

    if (_isSplitPayment) {
      details = OrderPaymentDetails(
        isSplitPayment: true,
        primaryMethod: PosPaymentMethod.cash,
        grandTotal: widget.grandTotal,
        totalPaid: _split1QrisAmount + _cashReceived,
        change: _splitCashChange,
        splits: [
          SplitPaymentEntry(
            id: 'split-1',
            method: PosPaymentMethod.qris,
            amount: _split1QrisAmount,
            referenceNumber: 'QRIS-BCA-9938201948102',
          ),
          SplitPaymentEntry(
            id: 'split-2',
            method: PosPaymentMethod.cash,
            amount: _split2CashAmount,
            cashGiven: _cashReceived,
            change: _splitCashChange,
          ),
        ],
        printPhysicalReceipt: _printPhysicalReceipt,
        sendWhatsAppReceipt: _sendWhatsAppReceipt,
        customerPhone: widget.customerPhone,
        customerName: widget.customerName,
        paidAt: DateTime.now(),
      );
    } else {
      details = OrderPaymentDetails(
        isSplitPayment: false,
        primaryMethod: _singleMethod,
        grandTotal: widget.grandTotal,
        totalPaid: _singleMethod == PosPaymentMethod.cash ? _fullCashReceived : widget.grandTotal,
        change: _singleMethod == PosPaymentMethod.cash ? _fullCashChange : 0,
        printPhysicalReceipt: _printPhysicalReceipt,
        sendWhatsAppReceipt: _sendWhatsAppReceipt,
        customerPhone: widget.customerPhone,
        customerName: widget.customerName,
        paidAt: DateTime.now(),
      );
    }

    widget.onConfirmPayment(details);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: 1100,
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: LpColors.surfacePanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LpColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Header
            _buildHeader(),
            // Tabs Switcher
            _buildTabSwitcher(),
            // Modal Body
            Expanded(
              child: _isSplitPayment ? _buildSplitBody() : _buildFullPaymentBody(),
            ),
            // Modal Footer
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
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LpColors.primaryGreen.withAlpha(120)),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: LpColors.primaryLight, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pembayaran Pesanan',
                            style: LpTypography.headlineSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF451A03).withAlpha(160),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD97706)),
                            ),
                            child: Text(
                              'Meja ${widget.tableNumber}',
                              style: LpTypography.labelSm.copyWith(
                                color: const Color(0xFFFCD34D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Tiket #TB-104 • Tamu: ${widget.customerName} (2 Pax)',
                              overflow: TextOverflow.ellipsis,
                              style: LpTypography.bodySm.copyWith(color: LpColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih skema pelunasan transaksi sebelum mencetak struk fisik/digital',
                        overflow: TextOverflow.ellipsis,
                        style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Total Pill & Close
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL TAGIHAN FINAL',
                    style: LpTypography.labelSm.copyWith(
                      color: LpColors.textMuted,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(widget.grandTotal),
                    style: LpTypography.dataCurrencyLg.copyWith(
                      color: LpColors.primaryLight,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.close, color: LpColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: LpColors.surfacePanel,
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(
                  title: 'Bayar Penuh',
                  icon: Icons.credit_card,
                  isActive: !_isSplitPayment,
                  onTap: () => setState(() => _isSplitPayment = false),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _buildTabButton(
                    title: 'Split Bayar / Pisah Tagihan (2 Metode)',
                    icon: Icons.call_split_rounded,
                    isActive: _isSplitPayment,
                    onTap: () => setState(() => _isSplitPayment = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Split balance indicator
          if (_isSplitPayment)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withAlpha(140),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LpColors.primaryGreen.withAlpha(120)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: LpColors.primaryLight),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Split Pas: ${CurrencyFormatter.format(_split1QrisAmount)} + ${CurrencyFormatter.format(_split2CashAmount)}',
                        overflow: TextOverflow.ellipsis,
                        style: LpTypography.labelSm.copyWith(
                          color: LpColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? LpColors.surfacePanel : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: LpColors.borderDark) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? LpColors.primaryLight : LpColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: LpTypography.labelSm.copyWith(
                  color: isActive ? Colors.white : LpColors.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1: QRIS Dinamis
          Expanded(
            child: SingleChildScrollView(
              child: _buildQrisColumn(),
            ),
          ),
          const SizedBox(width: 20),
          // Column 2: Tunai Kasir
          Expanded(
            child: SingleChildScrollView(
              child: _buildSplitCashColumn(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0284C7).withAlpha(120)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QRIS Dinamis Otomatis',
                            style: LpTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'BCA, Mandiri, BRI, GoPay, OVO, DANA',
                            style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(_split1QrisAmount),
                style: LpTypography.dataCurrencySm.copyWith(
                  color: const Color(0xFF38BDF8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: LpColors.borderDark, height: 20),
          // QR Graphic Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('QRIS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 14)),
                    Text('GPN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                // QR representation
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 130, color: Colors.grey.shade900),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('KOPI KITA - CABANG TEBET', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)),
                const Text('NMID: ID1020084920412', style: TextStyle(color: Colors.black54, fontSize: 9)),

              ],
            ),
          ),
          const SizedBox(height: 12),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: LpColors.surfacePanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LpColors.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top, size: 14, color: LpColors.accentAmber),
                const SizedBox(width: 6),
                Text('Berlaku: ', style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
                Text(_qrisTimerText, style: LpTypography.dataCurrencySm.copyWith(color: LpColors.accentAmber, fontSize: 12, fontWeight: FontWeight.bold)),
                Flexible(
                  child: Text(' • Menunggu scan tamu', overflow: TextOverflow.ellipsis, style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Webhook status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LpColors.primaryGreen.withAlpha(100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: LpColors.primaryLight, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Menunggu Webhook Bank', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontSize: 11)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Cek Manual', style: LpTypography.labelSm.copyWith(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCashColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD97706).withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tunai / Cash Kasir',
                            style: LpTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Pelunasan sisa tagihan secara fisik',
                            style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Sisa Tagihan', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 10)),
                  Text(
                    CurrencyFormatter.format(_split2CashAmount),
                    style: LpTypography.dataCurrencySm.copyWith(color: const Color(0xFFFCD34D), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: LpColors.borderDark, height: 16),
          // Quick Cash Chips
          Text('PECAHAN CEPAT LEMBAR UANG', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildQuickCashChip('Uang Pas', _split2CashAmount),
              const SizedBox(width: 6),
              _buildQuickCashChip('+200', _split2CashAmount + 200),
              const SizedBox(width: 6),
              _buildQuickCashChip('+5.200', 30000),
              const SizedBox(width: 6),
              _buildQuickCashChip('50.000', 50000),
            ],
          ),
          const SizedBox(height: 12),
          // Input Display
          Text('Nominal Uang Diterima dari Tamu:', style: LpTypography.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LpColors.surfacePanel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LpColors.primaryGreen, width: 1.5),
            ),
            child: Row(
              children: [
                Text('Rp', style: LpTypography.headlineSm.copyWith(color: LpColors.textMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CurrencyFormatter.format(_cashReceived).replaceAll('Rp ', ''),
                    style: LpTypography.dataCurrencyLg.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Highlighted Emerald Box: Kembalian
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LpColors.primaryLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.change_circle_outlined, size: 16, color: LpColors.primaryLight),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Kembalian Tunai Kasir',
                                  overflow: TextOverflow.ellipsis,
                                  style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Wajib diserahkan ke pelanggan',
                            style: LpTypography.labelSm.copyWith(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(_splitCashChange),
                      style: LpTypography.dataCurrencyLg.copyWith(
                        color: LpColors.primaryLight,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF047857), height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saran Pecahan Laci:', style: LpTypography.labelSm.copyWith(color: Colors.white70, fontSize: 10)),
                    Flexible(
                      child: Text(
                        _calculatePecahanSaran(_splitCashChange),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: LpTypography.dataCurrencySm.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Drawer status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status Laci: Auto-Pop saat Enter', style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
              Text('Laci Siap', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCashChip(String label, int amount) {
    final isSelected = _cashReceived == amount;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _cashReceived = amount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF064E3B) : LpColors.surfacePanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? LpColors.primaryLight : LpColors.borderDark),
          ),
          child: Column(
            children: [
              Text(label, style: LpTypography.labelSm.copyWith(color: isSelected ? LpColors.primaryLight : LpColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
              Text(
                CurrencyFormatter.format(amount).replaceAll('Rp ', ''),
                style: LpTypography.dataCurrencySm.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullPaymentBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PILIH METODE PEMBAYARAN', style: LpTypography.labelMd.copyWith(color: LpColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: PosPaymentMethod.values.map((method) {
              final isSel = _singleMethod == method;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _singleMethod = method),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSel ? LpColors.surfaceCardActive : LpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? LpColors.primaryGreen : LpColors.borderDark, width: isSel ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          Text(method.iconEmoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 8),
                          Text(
                            method.label,
                            style: LpTypography.bodyMd.copyWith(
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : LpColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (_singleMethod == PosPaymentMethod.cash) ...[
            Text('Pecahan Uang Tunai Diterima:', style: LpTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickFullCashChip('Uang Pas', widget.grandTotal),
                const SizedBox(width: 8),
                _buildQuickFullCashChip('Rp 50.000', 50000),
                const SizedBox(width: 8),
                _buildQuickFullCashChip('Rp 100.000', 100000),
                const SizedBox(width: 8),
                _buildQuickFullCashChip('Rp 200.000', 200000),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withAlpha(160),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LpColors.primaryLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kembalian Tunai', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
                      Text('Saran: ${_calculatePecahanSaran(_fullCashChange)}', style: LpTypography.bodySm.copyWith(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(_fullCashChange),
                    style: LpTypography.dataCurrencyLg.copyWith(color: LpColors.primaryLight, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ] else if (_singleMethod == PosPaymentMethod.qris) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 100, color: LpColors.primaryLight),
                  const SizedBox(height: 8),
                  Text('Tampilkan QRIS Dinamis ke Tamu', style: LpTypography.headlineSm.copyWith(color: Colors.white)),
                  Text('Total: ${CurrencyFormatter.format(widget.grandTotal)}', style: LpTypography.bodyMd.copyWith(color: LpColors.primaryLight)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFullCashChip(String label, int amount) {
    final isSelected = _fullCashReceived == amount;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _fullCashReceived = amount),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF064E3B) : LpColors.surfaceCard,
          side: BorderSide(color: isSelected ? LpColors.primaryLight : LpColors.borderDark),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: LpTypography.labelSm.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? LpColors.primaryLight : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: LpColors.borderDark)),
      ),
      child: Column(
        children: [
          // Checkboxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _printPhysicalReceipt,
                          activeColor: LpColors.primaryGreen,
                          onChanged: (val) => setState(() => _printPhysicalReceipt = val ?? true),
                        ),
                        Text('Cetak Struk Pelanggan Otomatis (Bluetooth 80mm)', style: LpTypography.bodySm.copyWith(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _sendWhatsAppReceipt,
                          activeColor: LpColors.primaryGreen,
                          onChanged: (val) => setState(() => _sendWhatsAppReceipt = val ?? false),
                        ),
                        Text('Kirim WhatsApp: ${widget.customerPhone ?? "-"}', style: LpTypography.bodySm.copyWith(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: LpColors.primaryLight, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Printer Ready', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Batal (ESC)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LpColors.textSecondary,
                  side: const BorderSide(color: LpColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onOpenCashDrawer,
                      icon: const Icon(Icons.inbox, size: 18, color: LpColors.accentAmber),
                      label: const Text('Buka Laci (F4)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LpColors.accentAmber,
                        side: const BorderSide(color: LpColors.borderDark),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _confirm,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Konfirmasi Pelunasan & Selesaikan Order (Enter)',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LpColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: LpTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
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
}
