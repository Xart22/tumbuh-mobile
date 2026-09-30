import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/cash_denomination.dart';
import '../../../../routing/app_router.dart';
import '../../../../data/models/shift_model.dart';
import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/shift_bloc.dart';

class ShiftScreen extends StatefulWidget {
  /// When true (entry from cashier login), an already-open shift sends the
  /// cashier straight to POS instead of showing the close/reconcile view.
  final bool autoEnterPos;

  const ShiftScreen({super.key, this.autoEnterPos = false});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final TextEditingController _notesController = TextEditingController(
    text: 'Semua transaksi tunai dan QRIS telah sinkron ke cloud. Laci kas rapi, roll kertas printer cadangan 3 roll terisi.',
  );
  final TextEditingController _varianceReasonController = TextEditingController();
  final TextEditingController _floatController = TextEditingController(text: '500000');

  @override
  void initState() {
    super.initState();
    context.read<ShiftBloc>().add(ShiftLoadCurrent());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _varianceReasonController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShiftBloc, ShiftState>(
      listener: (context, state) {
        if (state is ShiftActiveLoaded && widget.autoEnterPos) {
          context.go(AppRouter.pos);
          return;
        }
        if (state is ShiftCloseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF059669),
              content: Text(
                'Shift #${state.closedShift.shiftNumber} berhasil ditutup & laci terkunci.',
                style: LpTypography.labelLg.copyWith(color: Colors.white),
              ),
            ),
          );
          context.go(AppRouter.pos);
        } else if (state is ShiftError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text(state.message),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ShiftLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E1116),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),
          );
        }

        if (state is ShiftNoActiveShift) {
          return _buildOpenShiftView();
        }

        if (state is ShiftActiveLoaded) {
          return _buildCloseShiftView(state);
        }

        return _buildOpenShiftView();
      },
    );
  }

  // ================= VIEW: BUKA SHIFT BARU =================
  Widget _buildOpenShiftView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        title: const Text('Buka Shift Kasir Baru'),
        backgroundColor: const Color(0xFF171B22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.pos),
        ),
      ),
      body: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF171B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A303A)),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66059669)),
                    ),
                    child: const Icon(Icons.login_rounded, color: Color(0xFF85F8C4), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modal Awal Laci Kasir (Cash Float)',
                        style: LpTypography.headlineSm.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Masukkan saldo modal kas fisik saat membuka shift',
                        style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'NOMINAL MODAL AWAL (IDR)',
                style: LpTypography.labelSm.copyWith(color: const Color(0xFF94A3B8), letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _floatController,
                keyboardType: TextInputType.number,
                style: LpTypography.dataCurrencyLg.copyWith(color: Colors.white, fontSize: 28),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: LpTypography.headlineMd.copyWith(color: const Color(0xFF64748B)),
                  fillColor: const Color(0xFF0E1116),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A303A)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Quick preset buttons
              Row(
                children: [
                  _buildQuickFloatBtn(200000, 'Rp 200rb'),
                  const SizedBox(width: 8),
                  _buildQuickFloatBtn(500000, 'Rp 500rb (Standar)'),
                  const SizedBox(width: 8),
                  _buildQuickFloatBtn(1000000, 'Rp 1 Juta'),
                ],
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final floatValue = int.tryParse(_floatController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500000;
                    final auth = context.read<AuthBloc>().state;
                    final user =
                        auth is AuthKasirAuthenticated ? auth.user : null;
                    context.read<ShiftBloc>().add(
                          ShiftOpenRequested(
                            initialFloat: floatValue,
                            cashierId: user?.id ?? 'cashier_01',
                            cashierName: user?.name ?? 'Kasir',
                            shiftName: 'Shift 1 Pagi',
                          ),
                        );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Buka Shift & Masuk POS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: LpTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFloatBtn(int amount, String label) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _floatController.text = amount.toString();
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF0E1116),
          foregroundColor: const Color(0xFF85F8C4),
          side: const BorderSide(color: Color(0xFF2A303A)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(60, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: LpTypography.labelSm),
      ),
    );
  }

  // ================= VIEW: TUTUP SHIFT & REKONSILIASI =================
  Widget _buildCloseShiftView(ShiftActiveLoaded state) {
    final shift = state.currentShift;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Column(
          children: [
            _buildCloseShiftHeader(shift),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT COLUMN (60%): Cash Count (Pecahan Fisik)
                    Expanded(
                      flex: 6,
                      child: _buildCashCountSection(state),
                    ),
                    const SizedBox(width: 16),
                    // RIGHT COLUMN (40%): System vs Physical Reconciliation
                    Expanded(
                      flex: 4,
                      child: _buildReconciliationSection(state),
                    ),
                  ],
                ),
              ),
            ),
            _buildDockedFooter(state),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseShiftHeader(ShiftModel shift) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF171B22),
        border: Border(bottom: BorderSide(color: Color(0xFF2A303A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x66059669)),
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF85F8C4), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tutup Kas Shift & Rekonsiliasi Drawer',
                        style: LpTypography.headlineSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF062D22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x66059669)),
                        ),
                        child: Text(
                          shift.shiftName,
                          style: LpTypography.labelSm.copyWith(color: const Color(0xFF85F8C4), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kasir: ${shift.cashierName} • Device: ${shift.deviceName} • Outlet: ${shift.outletName}',
                    style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              // Shift duration pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF12151B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A303A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jam Shift: ',
                      style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                    ),
                    Text(
                      '07:30 - 15:30',
                      style: LpTypography.dataMonoSm.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Buka Laci Manual button
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perintah Drawer Kick terkirim ke printer thermal.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFFFEA619)),
                label: const Text('Buka Laci Manual'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF12151B),
                  foregroundColor: const Color(0xFFCBD5E1),
                  side: const BorderSide(color: Color(0xFF2A303A)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(60, 38),
                ),
              ),
              const SizedBox(width: 8),

              // Kembali button
              OutlinedButton.icon(
                onPressed: () => context.go(AppRouter.pos),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF12151B),
                  foregroundColor: const Color(0xFF94A3B8),
                  side: const BorderSide(color: Color(0xFF2A303A)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(60, 38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashCountSection(ShiftActiveLoaded state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A303A)),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF12151B),
              border: Border(bottom: BorderSide(color: Color(0xFF2A303A))),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Penghitungan Uang Fisik (Cash Count)',
                          style: LpTypography.labelLg.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Hitung lembar & koin fisik pada laci kasir',
                          style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    context.read<ShiftBloc>().add(ShiftResetCounts());
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ),

          // Denominations List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.denominations.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final denom = state.denominations[index];
                return _buildDenominationRow(denom, index);
              },
            ),
          ),

          // Total Fisik Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF12151B),
              border: Border(top: BorderSide(color: Color(0xFF2A303A))),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF062D22), Color(0xFF171B22)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL FISIK TERHITUNG',
                            style: LpTypography.labelSm.copyWith(color: const Color(0xFF85F8C4), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Hasil akumulasi uang fisik di laci',
                            style: LpTypography.bodySm.copyWith(color: const Color(0xFFCBD5E1), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatIDR(state.totalPhysicalCash),
                        style: LpTypography.dataCurrencyLg.copyWith(color: Colors.white, fontSize: 24),
                      ),
                      Text(
                        '${state.denominations.fold<int>(0, (sum, d) => sum + d.count)} lembar/koin',
                        style: LpTypography.dataMonoSm.copyWith(color: const Color(0xFF85F8C4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationRow(CashDenomination denom, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12151B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A303A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Label & badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: denom.badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    denom.label,
                    style: LpTypography.labelSm.copyWith(
                      color: denom.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatIDR(denom.nominal),
                    style: LpTypography.labelLg.copyWith(color: Colors.white),
                  ),
                  Text(
                    denom.description,
                    style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Center: Stepper controls
          Row(
            children: [
              _buildStepperBtn(
                icon: Icons.remove,
                onTap: () {
                  context.read<ShiftBloc>().add(ShiftDenominationAdjusted(index: index, delta: -1));
                },
              ),
              Container(
                width: 64,
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1116),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A303A)),
                ),
                child: Center(
                  child: Text(
                    '${denom.count}',
                    style: LpTypography.dataCurrency.copyWith(color: Colors.white),
                  ),
                ),
              ),
              _buildStepperBtn(
                icon: Icons.add,
                onTap: () {
                  context.read<ShiftBloc>().add(ShiftDenominationAdjusted(index: index, delta: 1));
                },
              ),
            ],
          ),

          // Right: Subtotal
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SUBTOTAL',
                  style: LpTypography.labelSm.copyWith(color: const Color(0xFF64748B), fontSize: 10),
                ),
                Text(
                  CurrencyFormatter.formatIDR(denom.subtotal),
                  style: LpTypography.dataCurrency.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFF0E1116),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A303A)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildReconciliationSection(ShiftActiveLoaded state) {
    final shift = state.currentShift;
    final variance = state.variance;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A303A)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_rounded, color: Color(0xFFFEA619), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rekonsiliasi Sistem vs Fisik',
                  style: LpTypography.labelLg.copyWith(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Breakdown card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF12151B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A303A)),
              ),
              child: Column(
                children: [
                  _buildReconRow('Modal Kas Awal (Float In)', shift.initialFloat),
                  const SizedBox(height: 8),
                  _buildReconRow('Penjualan Tunai Sistem (${shift.cashSalesCount} trx)', shift.cashSales, isAddition: true),
                  const SizedBox(height: 8),
                  _buildReconRow('QRIS & EDC (Non-Tunai)', shift.nonCashSales, isNeutral: true),
                  const Divider(color: Color(0xFF2A303A), height: 20),
                  _buildReconRow('Total Kas Seharusnya di Laci:', shift.expectedCashInDrawer, isBold: true),
                  const SizedBox(height: 8),
                  _buildReconRow('Total Kas Fisik Terhitung:', state.totalPhysicalCash, isBold: true, highlightColor: const Color(0xFF85F8C4)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Variance banner
            _buildVarianceBanner(variance),
            const SizedBox(height: 14),

            // Handover notes
            Text(
              'CATATAN SERAH TERIMA SHIFT',
              style: LpTypography.labelSm.copyWith(color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: LpTypography.bodySm.copyWith(color: Colors.white),
              decoration: InputDecoration(
                fillColor: const Color(0xFF12151B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2A303A)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Supervisor badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF12151B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A303A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF85F8C4), size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Otorisasi Supervisor', style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8), fontSize: 11)),
                          Text('Dian P. (Manager On Duty)', style: LpTypography.labelSm.copyWith(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TERVERIFIKASI',
                      style: LpTypography.labelSm.copyWith(color: const Color(0xFF85F8C4), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconRow(String label, int amount, {bool isAddition = false, bool isNeutral = false, bool isBold = false, Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? LpTypography.labelLg.copyWith(color: Colors.white)
              : LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
        ),
        Text(
          '${isAddition ? "+ " : ""}${CurrencyFormatter.formatIDR(amount)}',
          style: isBold
              ? LpTypography.dataCurrency.copyWith(color: highlightColor ?? Colors.white, fontWeight: FontWeight.w700)
              : LpTypography.dataMonoSm.copyWith(color: isNeutral ? const Color(0xFF64748B) : Colors.white),
        ),
      ],
    );
  }

  Widget _buildVarianceBanner(int variance) {
    final isZero = variance == 0;
    final isMinus = variance < 0;

    final bgColor = isZero
        ? const Color(0xFF062D22)
        : (isMinus ? const Color(0xFF450A0A) : const Color(0xFF422006));
    final borderColor = isZero
        ? const Color(0xFF059669)
        : (isMinus ? const Color(0xFFEF4444) : const Color(0xFFFEA619));
    final textColor = isZero
        ? const Color(0xFF85F8C4)
        : (isMinus ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isZero ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELISIH KAS (VARIANCE)',
                    style: LpTypography.labelSm.copyWith(color: textColor, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    isZero ? 'KAS PAS / BALANCE PERFECT' : (isMinus ? 'SELISIH KURANG (MINUS)' : 'SELISIH LEBIH (SURPLUS)'),
                    style: LpTypography.bodySm.copyWith(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatIDR(variance.abs()),
                style: LpTypography.dataCurrencyLg.copyWith(color: textColor, fontSize: 18),
              ),
              Text(
                isZero ? '100% Cocok' : (isMinus ? 'Wajib Alasan' : 'Surplus'),
                style: LpTypography.dataMonoSm.copyWith(color: textColor, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDockedFooter(ShiftActiveLoaded state) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF171B22),
        border: Border(top: BorderSide(color: Color(0xFF2A303A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Printer Thermal 80mm Terhubung',
                style: LpTypography.bodySm.copyWith(color: const Color(0xFFCBD5E1)),
              ),
              const SizedBox(width: 16),
              const Text('•', style: TextStyle(color: Color(0xFF2A303A))),
              const SizedBox(width: 16),
              const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 6),
              Text(
                'Cloud Sync: Up to Date',
                style: LpTypography.bodySm.copyWith(color: const Color(0xFFCBD5E1)),
              ),
            ],
          ),

          Row(
            children: [
              // Print Summary Button
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mencetak Bukti Rekapitulasi Shift ke Printer 80mm...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFFFEA619)),
                label: const Text('Cetak Rekap Shift (Thermal 80mm)'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF12151B),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF2A303A)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(100, 48),
                ),
              ),
              const SizedBox(width: 12),

              // Tutup Shift Primary CTA Button
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ShiftBloc>().add(
                        ShiftCloseRequested(
                          handoverNotes: _notesController.text,
                          varianceReason: state.variance != 0 ? _varianceReasonController.text : null,
                        ),
                      );
                },
                icon: const Icon(Icons.lock_rounded, size: 20),
                label: const Text('Tutup Shift & Kunci Drawer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: LpTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
