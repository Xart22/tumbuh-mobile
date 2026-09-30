import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/kds_bloc.dart';
import '../../bloc/kds_event.dart';
import '../../bloc/kds_state.dart';

class KdsRecallModal extends StatelessWidget {
  const KdsRecallModal({super.key});

  static Future<void> show(BuildContext context, {required KdsBloc bloc}) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: bloc,
        child: const KdsRecallModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LpColors.kdsCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LpColors.kdsCardBorder, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: BlocBuilder<KdsBloc, KdsState>(
          builder: (context, state) {
            final recalled = state.recalledTickets;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: LpColors.kdsHeader,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: LpColors.kdsCardBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            color: LpColors.secondaryFixed,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Recall Tiket Selesai (${recalled.length})',
                            style: LpTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Modal Content
                Expanded(
                  child: recalled.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF6B7280),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum Ada Tiket yang Diselesaikan',
                                style: LpTypography.titleMedium.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tiket yang di-bump akan muncul di sini untuk di-recall.',
                                style: LpTypography.bodySmall.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: recalled.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ticket = recalled[index];
                            final timeStr = DateFormat('HH:mm').format(ticket.enteredAt);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2330),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: LpColors.kdsCardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              ticket.ticketNumber,
                                              style: LpTypography.titleLarge.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black38,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                ticket.tableOrCustomer,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '• Masuk: $timeStr WIB',
                                              style: const TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ticket.items
                                              .map((item) => '${item.quantity}x ${item.name}')
                                              .join(', '),
                                          style: const TextStyle(
                                            color: Color(0xFFD1D5DB),
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<KdsBloc>().add(KdsRecallTicket(ticketId: ticket.id));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: LpColors.secondary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.replay_rounded, size: 18),
                                    label: const Text(
                                      'Kembalikan',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
