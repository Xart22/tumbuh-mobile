import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/device/device_service.dart';
import '../../../../routing/app_router.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/auth_bloc.dart';

class KasirLoginScreen extends StatefulWidget {
  const KasirLoginScreen({super.key});

  @override
  State<KasirLoginScreen> createState() => _KasirLoginScreenState();
}

class _KasirLoginScreenState extends State<KasirLoginScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  String _deviceIdLabel = '-';
  String _deviceLabel = 'Memuat info perangkat...';

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    DeviceService? deviceService;
    try {
      deviceService = context.read<DeviceService>();
    } catch (_) {
      deviceService = null;
    }
    if (deviceService == null) {
      if (mounted) setState(() => _deviceLabel = 'Perangkat Kasir');
      return;
    }
    final info = await deviceService.getDeviceInfo();
    if (!mounted) return;
    setState(() {
      _deviceIdLabel = info.deviceId;
      _deviceLabel = '${info.deviceName} (${info.osVersion})';
    });
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
          AuthLoginKasirRequested(pin: _enteredPin),
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
                        'ID: $_deviceIdLabel',
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
                              _deviceLabel,
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

            // 2. Cashier notice — the backend identifies the employee by PIN,
            // so no cashier list exists pre-login.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF12151B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A303A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_rounded, color: Color(0xFF85F8C4), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kasir diidentifikasi dari PIN. Masukkan 6 digit PIN Anda untuk masuk.',
                      style: LpTypography.bodySm.copyWith(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 3. Biometric Tablet Button
        InkWell(
          onTap: () {
            context.read<AuthBloc>().add(
                  const AuthBiometricLoginRequested(
                    cashierId: 'biometric',
                    cashierName: 'Kasir',
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
                      'Kasir diidentifikasi dari PIN',
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
