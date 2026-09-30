import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/pos_bloc.dart';
import '../../bloc/pos_event.dart';
import '../../bloc/pos_state.dart';

/// Apply a voucher code to the running order (validated by the backend).
class VoucherModal extends StatefulWidget {
  const VoucherModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: LpColors.darkScrim,
      builder: (_) => const VoucherModal(),
    );
  }

  @override
  State<VoucherModal> createState() => _VoucherModalState();
}

class _VoucherModalState extends State<VoucherModal> {
  final _controller = TextEditingController();
  String? _submittedCode;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Masukkan kode voucher.');
      return;
    }
    setState(() {
      _submittedCode = code;
      _error = null;
    });
    context.read<PosBloc>().add(PosApplyVoucher(code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listener: (context, state) {
        if (_submittedCode == null) return;
        if (state.voucherError != null) {
          setState(() => _error = state.voucherError);
        } else if (state.appliedVoucherCode == _submittedCode) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: LpColors.surfaceModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Tambah Voucher',
                      style: LpTypography.headlineSm.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Kode voucher',
                    hintStyle: const TextStyle(color: LpColors.textMuted),
                    prefixIcon: const Icon(Icons.local_offer_outlined, color: LpColors.textSecondary),
                    filled: true,
                    fillColor: LpColors.surfacePanel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: LpTypography.bodySm.copyWith(color: LpColors.critical),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Terapkan Voucher'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
