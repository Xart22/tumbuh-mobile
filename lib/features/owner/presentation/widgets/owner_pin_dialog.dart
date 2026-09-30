import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class OwnerPinBottomSheet extends StatefulWidget {
  final String title;
  final String description;
  final ValueChanged<String> onConfirmed;

  const OwnerPinBottomSheet({
    super.key,
    this.title = 'Otorisasi Cepat Owner',
    this.description = 'Masukkan 6 Digit PIN atau Sidik Jari',
    required this.onConfirmed,
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Otorisasi Cepat Owner',
    String description = 'Masukkan 6 Digit PIN atau Sidik Jari',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OwnerPinBottomSheet(
        title: title,
        description: description,
        onConfirmed: (pin) => Navigator.pop(ctx, pin),
      ),
    );
  }

  @override
  State<OwnerPinBottomSheet> createState() => _OwnerPinBottomSheetState();
}

class _OwnerPinBottomSheetState extends State<OwnerPinBottomSheet> {
  String _enteredPin = '';

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
      });
      if (_enteredPin.length == 6) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            widget.onConfirmed(_enteredPin);
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onBiometric() {
    // Simulate biometric immediate authentication
    widget.onConfirmed('BIOMETRIC_AUTH');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LpColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LpColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Icon & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LpColors.primaryContainer.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: LpColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: LpTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LpColors.onSurface,
                      ),
                    ),
                    Text(
                      widget.description,
                      style: LpTypography.bodySm.copyWith(
                        color: LpColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6-Dot PIN Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: LpColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? LpColors.primary : LpColors.outlineVariant,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Tactile Keypad (3 columns x 4 rows)
            Column(
              children: [
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Biometric button
                    _buildActionButton(
                      icon: Icons.fingerprint,
                      label: 'Biometrik',
                      color: LpColors.primary,
                      onTap: _onBiometric,
                    ),
                    // 0 button
                    _buildDigitButton('0'),
                    // Backspace button
                    _buildActionButton(
                      icon: Icons.backspace_outlined,
                      label: 'Hapus',
                      color: LpColors.onSurfaceVariant,
                      onTap: _onBackspace,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildDigitButton(digit)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: LpColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: LpTypography.mono.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: LpColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color == LpColors.primary
              ? LpColors.primaryContainer.withAlpha(30)
              : LpColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(
            color: color == LpColors.primary
                ? LpColors.primaryContainer.withAlpha(80)
                : LpColors.outlineVariant.withAlpha(120),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 26,
            color: color,
          ),
        ),
      ),
    );
  }
}
