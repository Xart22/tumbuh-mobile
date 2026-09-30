import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../routing/app_router.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/auth_bloc.dart';

class CashierItem {
  final String id;
  final String name;
  final String initials;
  final String shift;
  final String roleNote;
  final bool isSupervisor;

  const CashierItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.shift,
    required this.roleNote,
    this.isSupervisor = false,
  });
}

class KasirLoginScreen extends StatefulWidget {
  const KasirLoginScreen({super.key});

  @override
  State<KasirLoginScreen> createState() => _KasirLoginScreenState();
}

class _KasirLoginScreenState extends State<KasirLoginScreen> {
  static const List<CashierItem> _scheduledCashiers = [
    CashierItem(
      id: 'cashier_01',
      name: 'Barista Rama',
      initials: 'BR',
      shift: 'Shift 1 Pagi (07:30 - 15:30)',
      roleNote: 'Aktif Dipilih',
    ),
    CashierItem(
      id: 'cashier_02',
      name: 'Kasir Dika',
      initials: 'DK',
      shift: 'Shift 2 Sore (15:00 - 23:00)',
      roleNote: 'Shift Selanjutnya',
    ),
    CashierItem(
      id: 'cashier_03',
      name: 'Supervisor Dian P.',
      initials: 'DP',
      shift: 'Akses Otorisasi & Void Penuh',
      roleNote: 'Manager on Duty',
      isSupervisor: true,
    ),
  ];

  late CashierItem _selectedCashier;
  String _enteredPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCashier = _scheduledCashiers[0];
  }

  void _onKeyPress(String key) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += key;
        _errorMessage = null;
      });

      if (_enteredPin.length == 6) {
        _submitPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  void _submitPin() {
    if (_enteredPin.length < 6) {
      setState(() {
        _errorMessage = 'PIN harus 6 digit angka.';
      });
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginKasirRequested(
            pin: _enteredPin,
            cashierName: _selectedCashier.name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthKasirAuthenticated) {
          // Enter through the shift gate: order creation needs an open shift.
          context.go('${AppRouter.shift}?autopos=1');
        } else if (state is AuthFailure) {
          setState(() {
            _errorMessage = state.message;
            _enteredPin = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1116),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT PANEL (42%): Device Binding & Cashier list
                      Expanded(
                        flex: 5,
                        child: _buildLeftPanel(),
                      ),
                      const SizedBox(width: 20),
                      // RIGHT PANEL (58%): PIN Touch Keypad
                      Expanded(
                        flex: 7,
                        child: _buildRightKeypadPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF171B22),
        border: Border(bottom: BorderSide(color: Color(0xFF2A303A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF004D34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0x4D85F8C4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tumbuh',
                        style: LpTypography.headlineSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x66059669)),
                        ),
                        child: Text(
                          'POS',
                          style: LpTypography.labelSm.copyWith(
                            color: const Color(0xFF85F8C4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Aplikasi Kasir Tablet Android v1.2.0',
                    style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),

          // Right: Outlet info & Sync indicator
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: Color(0xFFFEA619), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Kopi Kita – Cabang Tebet',
                        style: LpTypography.labelLg.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online • Database Lokal Siap Offline',
                        style: LpTypography.bodySm.copyWith(color: const Color(0xFF85F8C4)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                width: 1,
                color: const Color(0xFF2A303A),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRouter.setup),
                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                label: const Text('Setup'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E1116),
                  foregroundColor: const Color(0xFF94A3B8),
                  side: const BorderSide(color: Color(0xFF2A303A)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(60, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Device Binding Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF171B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A303A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x66059669)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF85F8C4)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Perangkat Resmi Terdaftar',
                                  style: LpTypography.labelSm.copyWith(
                                    color: const Color(0xFF85F8C4),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HW-ID: A9-8832',
                        style: LpTypography.dataMonoSm.copyWith(color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.tablet_android_rounded, color: Color(0xFF85F8C4), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Identifier Terverifikasi',
                              style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                            ),
                            Text(
                              'Tablet Kasir Utama #DEV-01 (Samsung Tab A9+)',
                              style: LpTypography.labelLg.copyWith(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF2A303A)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sinkronisasi Cloud:',
                        style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF85F8C4)),
                          const SizedBox(width: 4),
                          Text(
                            'Aktif • 0 pending',
                            style: LpTypography.bodySm.copyWith(color: const Color(0xFF85F8C4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Cashier Selector List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'PILIH KASIR BERTUGAS HARI INI',
                    style: LpTypography.labelSm.copyWith(
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ketuk nama untuk ganti',
                  style: LpTypography.bodySm.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scheduledCashiers.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cashier = _scheduledCashiers[index];
                final isSelected = cashier.id == _selectedCashier.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCashier = cashier;
                      _enteredPin = '';
                      _errorMessage = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF171B22) : const Color(0xFF12151B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : (cashier.isSupervisor ? const Color(0x4DFEA619) : const Color(0xFF2A303A)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : (cashier.isSupervisor
                                          ? const Color(0x33FEA619)
                                          : const Color(0xFF2A303A)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    cashier.initials,
                                    style: LpTypography.labelLg.copyWith(
                                      color: cashier.isSupervisor && !isSelected
                                          ? const Color(0xFFFEA619)
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
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
                                        Flexible(
                                          child: Text(
                                            cashier.name,
                                            style: LpTypography.labelLg.copyWith(
                                              color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0x33059669)
                                                : (cashier.isSupervisor
                                                    ? const Color(0x26FEA619)
                                                    : Colors.transparent),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            cashier.roleNote,
                                            style: LpTypography.labelSm.copyWith(
                                              color: isSelected
                                                  ? const Color(0xFF85F8C4)
                                                  : (cashier.isSupervisor
                                                      ? const Color(0xFFFEA619)
                                                      : const Color(0xFF64748B)),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cashier.shift,
                                      style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 16, color: Colors.white),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        // 3. Biometric Tablet Button
        InkWell(
          onTap: () {
            context.read<AuthBloc>().add(
                  AuthBiometricLoginRequested(
                    cashierId: _selectedCashier.id,
                    cashierName: _selectedCashier.name,
                  ),
                );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A303A)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1116),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A303A)),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF85F8C4), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opsi Biometrik Tablet',
                        style: LpTypography.labelLg.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Sentuh sensor sidik jari untuk login cepat',
                        style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightKeypadPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A303A)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
          // Header info
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1116),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2A303A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      'Kasir: ${_selectedCashier.name} (${_selectedCashier.shift.split(' ').first})',
                      style: LpTypography.bodySm.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan 6 Digit PIN Kasir',
                style: LpTypography.headlineMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gunakan PIN rahasia untuk membuka terminal kasir',
                style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),

              // 6 PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isFilled ? 18 : 16,
                    height: isFilled ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? const Color(0xFF85F8C4) : const Color(0xFF0E1116),
                      border: Border.all(
                        color: isFilled ? const Color(0xFF85F8C4) : const Color(0xFF475569),
                        width: 2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: const Color(0xFF85F8C4).withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: LpTypography.bodySm.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          // 3x4 Touch Numeric Keypad
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 14,
              childAspectRatio: 1.5,
              children: [
                _buildKeypadBtn('1'),
                _buildKeypadBtn('2'),
                _buildKeypadBtn('3'),
                _buildKeypadBtn('4'),
                _buildKeypadBtn('5'),
                _buildKeypadBtn('6'),
                _buildKeypadBtn('7'),
                _buildKeypadBtn('8'),
                _buildKeypadBtn('9'),
                _buildActionKeypadBtn(
                  label: 'C',
                  onTap: _onClear,
                  color: const Color(0xFFEF4444),
                ),
                _buildKeypadBtn('0'),
                _buildActionKeypadBtn(
                  icon: Icons.backspace_rounded,
                  onTap: _onDelete,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),

          // Action Login Button
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _enteredPin.length == 6 ? _submitPin : null,
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text('Masuk Terminal Kasir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF2A303A),
                  disabledForegroundColor: const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: LpTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildKeypadBtn(String number) {
    return Material(
      color: const Color(0xFF1E242E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onKeyPress(number),
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF059669).withValues(alpha: 0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A303A)),
          ),
          child: Center(
            child: Text(
              number,
              style: LpTypography.dataCurrencyLg.copyWith(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKeypadBtn({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: const Color(0xFF14181F),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A303A)),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label,
                    style: LpTypography.headlineMd.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}
