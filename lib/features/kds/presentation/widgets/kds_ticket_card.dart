import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/kds_bloc.dart';
import '../../bloc/kds_event.dart';
import '../../bloc/kds_state.dart';
import '../../data/models/kds_ticket.dart';

class KdsTicketCard extends StatelessWidget {
  final KdsTicket ticket;
  final bool isFirstInQueue;

  const KdsTicketCard({
    super.key,
    required this.ticket,
    this.isFirstInQueue = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KdsBloc, KdsState>(
      builder: (context, state) {
        final urgency = ticket.calculateUrgency(state.currentTime);
        final elapsedFormatted = ticket.formatElapsed(state.currentTime);
        final masukFormatted = 'Masuk: ${DateFormat('HH:mm').format(ticket.enteredAt)} WIB';

        return Container(
          width: 390,
          decoration: BoxDecoration(
            color: LpColors.kdsCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: urgency.borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Alert Header (Color-coded by Urgency)
              _buildHeader(urgency, elapsedFormatted, masukFormatted),

              // 2. Scrollable Items Container
              Expanded(
                child: Container(
                  color: LpColors.kdsCardInner,
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      // Items List
                      ...ticket.items.map((item) => _buildItemRow(context, item)),

                      // Special Instructions / Allergy Banner
                      if (ticket.specialInstructions != null && ticket.specialInstructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF450A0A).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFB91C1C).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.feedback_rounded,
                                color: Color(0xFFF87171),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'INSTRUKSI KHUSUS TAMU:',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Color(0xFFF87171),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ticket.specialInstructions!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFECACA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Sticky Bottom 52px Bump Button
              _buildBumpFooter(context, urgency),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(KdsUrgency urgency, String elapsedFormatted, String masukFormatted) {
    final isTakeAway = ticket.orderType.toLowerCase().contains('take');
    final isDriver = ticket.tableOrCustomer.toLowerCase().contains('driver') ||
        ticket.tableOrCustomer.toLowerCase().contains('gojek') ||
        ticket.tableOrCustomer.toLowerCase().contains('grab');

    return Container(
      color: urgency.headerBgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Table/Customer & Order Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDriver ? Icons.two_wheeler_rounded : Icons.table_restaurant_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          ticket.tableOrCustomer,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isTakeAway ? 'TAKE AWAY' : 'DINE-IN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Row 2: Ticket Number & Elapsed SLA Timer Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                ticket.ticketNumber,
                style: LpTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  fontSize: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: urgency == KdsUrgency.overdue
                        ? const Color(0xFFF87171)
                        : (urgency == KdsUrgency.warning
                            ? const Color(0xFFFCD34D)
                            : (urgency == KdsUrgency.fresh
                                ? const Color(0xFF34D399)
                                : const Color(0xFF60A5FA))),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      urgency.icon,
                      size: 15,
                      color: urgency == KdsUrgency.overdue
                          ? const Color(0xFFFCA5A5)
                          : (urgency == KdsUrgency.warning
                              ? const Color(0xFFFDE68A)
                              : (urgency == KdsUrgency.fresh
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF93C5FD))),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      elapsedFormatted,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      urgency.badgeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: urgency == KdsUrgency.overdue
                            ? const Color(0xFFFECACA)
                            : (urgency == KdsUrgency.warning
                                ? const Color(0xFFFDE68A)
                                : (urgency == KdsUrgency.fresh
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFBFDBFE))),
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Row 3: Server Name & Entered Time / Delivery note
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  masukFormatted,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ticket.customerArrivalNote ?? 'Server: ${ticket.serverName}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: ticket.customerArrivalNote != null ? FontWeight.bold : FontWeight.normal,
                      color: ticket.customerArrivalNote != null ? const Color(0xFFA7F3D0) : Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, KdsTicketItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.isCompleted ? const Color(0x8018202C) : const Color(0xFF1B2330),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isCompleted
              ? const Color(0xFF2D3748)
              : (item.station == KdsStation.kitchen
                  ? const Color(0xFFD97706).withValues(alpha: 0.5)
                  : const Color(0xFF2D3748)),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 32x32dp Checklist Toggle Button
          InkWell(
            onTap: () {
              context.read<KdsBloc>().add(KdsToggleItemDone(
                    ticketId: ticket.id,
                    itemId: item.id,
                  ));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.isCompleted ? const Color(0xFF047857) : const Color(0xFF0B0F15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.isCompleted ? const Color(0xFF10B981) : const Color(0xFF6D7A72),
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 10),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        style: LpTypography.titleMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          color: item.isCompleted ? const Color(0xFF9CA3AF) : Colors.white,
                        ),
                      ),
                    ),
                    if (item.stationBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF374151)),
                        ),
                        child: Text(
                          item.stationBadge!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.stationBadge == 'Siap Saji'
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                          ),
                        ),
                      ),
                  ],
                ),

                // Modifier Tag Box
                if (item.modifierText != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF451A03).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF92400E).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      item.modifierText!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFDDB8),
                      ),
                    ),
                  ),
                ],

                // Notes / Kitchen Instructions
                if (item.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: item.isCompleted ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBumpFooter(BuildContext context, KdsUrgency urgency) {
    final status = ticket.status;
    final buttonColor = status.bumpButtonColor(urgency);
    final buttonLabel = status.bumpButtonLabel;
    final buttonIcon = status.bumpButtonIcon;

    return Container(
      padding: const EdgeInsets.all(8),
      color: LpColors.kdsCard,
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            context.read<KdsBloc>().add(KdsBumpTicket(ticketId: ticket.id));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          icon: Icon(buttonIcon, size: 20),
          label: Text(
            buttonLabel,
            style: LpTypography.labelLg.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
