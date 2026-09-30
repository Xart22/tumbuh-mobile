import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/pos_bloc.dart';
import '../../bloc/pos_event.dart';
import '../../bloc/pos_state.dart';

/// Search-and-pick CRM customer to attach to the running order.
class CustomerPickerModal extends StatefulWidget {
  const CustomerPickerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: LpColors.darkScrim,
      builder: (_) => const CustomerPickerModal(),
    );
  }

  @override
  State<CustomerPickerModal> createState() => _CustomerPickerModalState();
}

class _CustomerPickerModalState extends State<CustomerPickerModal> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosBloc>().add(const PosSearchCustomers(''));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<PosBloc>().add(PosSearchCustomers(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LpColors.surfaceModal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Pilih Pelanggan',
                    style: LpTypography.headlineSm.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau nomor HP',
                  hintStyle: const TextStyle(color: LpColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: LpColors.textSecondary),
                  filled: true,
                  fillColor: LpColors.surfacePanel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<PosBloc, PosState>(
                builder: (context, state) {
                  if (state.customerResults.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada pelanggan.',
                        style: TextStyle(color: LpColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.customerResults.length,
                    itemBuilder: (context, index) {
                      final customer = state.customerResults[index];
                      return ListTile(
                        leading: const Icon(Icons.person_rounded, color: LpColors.accentAmber),
                        title: Text(customer.name, style: const TextStyle(color: Colors.white)),
                        subtitle: customer.phone != null
                            ? Text(customer.phone!, style: const TextStyle(color: LpColors.textSecondary))
                            : null,
                        onTap: () {
                          context.read<PosBloc>().add(PosSelectCustomer(customer));
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: LpColors.borderDark),
            TextButton.icon(
              onPressed: () {
                context.read<PosBloc>().add(const PosClearCustomer());
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.person_off_rounded, color: LpColors.textSecondary),
              label: const Text('Hapus pelanggan (Tamu)', style: TextStyle(color: LpColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
