import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/pos_bloc.dart';

/// Shows the dynamic QRIS payload and polls the order until the gateway
/// webhook marks it paid.
class QrisPaymentModal extends StatefulWidget {
  final String qrString;
  final int grandTotal;
  final String serverOrderId;

  const QrisPaymentModal({
    super.key,
    required this.qrString,
    required this.grandTotal,
    required this.serverOrderId,
  });

  static Future<void> show(
    BuildContext context, {
    required String qrString,
    required int grandTotal,
    required String serverOrderId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: LpColors.darkScrim,
      builder: (_) => QrisPaymentModal(
        qrString: qrString,
        grandTotal: grandTotal,
        serverOrderId: serverOrderId,
      ),
    );
  }

  @override
  State<QrisPaymentModal> createState() => _QrisPaymentModalState();
}

class _QrisPaymentModalState extends State<QrisPaymentModal> {
  Timer? _poll;
  int _secondsLeft = 300; // 5 minutes
  bool _checking = false;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 300));
      if (_secondsLeft % 5 == 0) _checkStatus();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_checking || _paid) return;
    _checking = true;
    final paid = await context.read<PosBloc>().isOrderPaid(widget.serverOrderId);
    _checking = false;
    if (!mounted) return;
    if (paid) {
      setState(() => _paid = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    }
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LpColors.surfaceModal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QRIS Dinamis', style: LpTypography.headlineSm.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(widget.grandTotal),
                style: LpTypography.dataCurrencyLg.copyWith(
                  color: LpColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_paid)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Icon(Icons.check_circle_rounded, size: 96, color: LpColors.primaryLight),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: widget.qrString,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _paid ? 'Pembayaran diterima' : 'Menunggu pembayaran • $_timerText',
                style: LpTypography.bodySm.copyWith(color: LpColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                  FilledButton.icon(
                    onPressed: _checkStatus,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Cek Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
