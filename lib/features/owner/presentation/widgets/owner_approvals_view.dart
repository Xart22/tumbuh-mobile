import 'package:flutter/material.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/approval_model.dart';
import 'owner_pin_dialog.dart';

class OwnerApprovalsView extends StatelessWidget {
  final List<ApprovalRequest> approvals;
  final ApprovalStatus currentFilter;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final ValueChanged<ApprovalStatus> onFilterChanged;
  final void Function(String requestId, String pin) onApprove;
  final void Function(String requestId, String reason) onReject;

  const OwnerApprovalsView({
    super.key,
    required this.approvals,
    required this.currentFilter,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.onFilterChanged,
    required this.onApprove,
    required this.onReject,
  });

  void _handleApproveWithPin(BuildContext context, ApprovalRequest request) async {
    final pin = await OwnerPinBottomSheet.show(
      context,
      title: 'Otorisasi ${request.type.label}',
      description: 'Masukkan PIN Owner untuk menyetujui ${request.ticketNumber ?? ""}',
    );

    if (pin != null && pin.isNotEmpty) {
      onApprove(request.id, pin);
    }
  }

  void _handleRejectPrompt(BuildContext context, ApprovalRequest request) {
    final controller = TextEditingController(text: 'Tidak disetujui');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LpColors.surface,
        title: Text(
          'Tolak Permintaan',
          style: LpTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: LpColors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan alasan penolakan untuk kasir / cabang:',
              style: LpTypography.bodySm.copyWith(color: LpColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Alasan penolakan...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LpColors.error,
              foregroundColor: LpColors.onError,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onReject(request.id, controller.text);
            },
            child: const Text('Tolak Permintaan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Filter Tab Pills
        Container(
          color: LpColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(
                  label: 'Menunggu Otorisasi',
                  count: pendingCount,
                  status: ApprovalStatus.pending,
                  hasIndicator: true,
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Disetujui',
                  count: approvedCount,
                  status: ApprovalStatus.approved,
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Ditolak',
                  count: rejectedCount,
                  status: ApprovalStatus.rejected,
                ),
              ],
            ),
          ),
        ),

        // 2. Scrollable List of Requests
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Security info banner
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withAlpha(180), // amber-100
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Color(0xFFB45309), // amber-700
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Otorisasi Level Owner Diperlukan. ',
                          style: LpTypography.bodySm.copyWith(
                            color: const Color(0xFF78350F),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Tindakan void dan diskon di luar wewenang kasir akan langsung memperbarui status terminal POS kasir secara real-time.',
                              style: LpTypography.bodySm.copyWith(
                                color: const Color(0xFF92400E),
                                fontWeight: FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (approvals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: LpColors.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada permintaan pada kategori ini',
                        style: LpTypography.bodyMd.copyWith(
                          color: LpColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...approvals.map((req) => _buildApprovalCard(context, req)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required ApprovalStatus status,
    bool hasIndicator = false,
  }) {
    final isSelected = currentFilter == status;
    return InkWell(
      onTap: () => onFilterChanged(status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? LpColors.primary : LpColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LpColors.primary : LpColors.outlineVariant,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LpColors.primary.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIndicator && count > 0) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: LpTypography.labelSm.copyWith(
                color: isSelected ? LpColors.onPrimary : LpColors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? LpColors.primaryContainer : LpColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: LpTypography.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? LpColors.onPrimaryContainer : LpColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, ApprovalRequest req) {
    Color cardBorderColor;
    Color ribbonBgColor;
    Color tagColor;
    String tagLabel;

    switch (req.type) {
      case ApprovalType.voidOrder:
        cardBorderColor = Colors.red.shade200;
        ribbonBgColor = const Color(0xFFFEF2F2);
        tagColor = Colors.red.shade600;
        tagLabel = 'MENDESAK';
        break;
      case ApprovalType.specialDiscount:
        cardBorderColor = Colors.amber.shade200;
        ribbonBgColor = const Color(0xFFFFFBEB);
        tagColor = Colors.amber.shade700;
        tagLabel = 'Maks Kasir: 10%';
        break;
      case ApprovalType.purchaseOrder:
        cardBorderColor = Colors.blue.shade200;
        ribbonBgColor = const Color(0xFFEFF6FF);
        tagColor = Colors.blue.shade700;
        tagLabel = 'Stok Kritis 0.8 kg';
        break;
      case ApprovalType.shiftVariance:
        cardBorderColor = Colors.purple.shade200;
        ribbonBgColor = const Color(0xFFFAF5FF);
        tagColor = Colors.purple.shade700;
        tagLabel = 'Audit Kasir';
        break;
    }

    final requesterInitial = req.requestedBy.isNotEmpty
        ? req.requestedBy.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'AP';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: LpColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: ribbonBgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: req.type.badgeBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            req.type.label,
                            style: LpTypography.labelSm.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatMinutesAgo(req.requestedAt),
                        style: LpTypography.bodySm.copyWith(
                          color: LpColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tagColor.withAlpha(100)),
                  ),
                  child: Text(
                    tagLabel,
                    style: LpTypography.labelSm.copyWith(
                      color: tagColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Requester & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: req.type.badgeBgColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                requesterInitial,
                                style: LpTypography.mono.copyWith(
                                  color: req.type.badgeBgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.requestedBy,
                                  style: LpTypography.bodySm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: LpColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${req.ticketNumber ?? ""} • ${req.tableNumber ?? req.shiftName}',
                                  style: LpTypography.bodySm.copyWith(
                                    color: LpColors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
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
                        Text(
                          'NOMINAL',
                          style: LpTypography.labelSm.copyWith(
                            color: LpColors.outline,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          OrderMath.formatCurrency(req.amount),
                          style: LpTypography.mono.copyWith(
                            color: req.type == ApprovalType.voidOrder
                                ? Colors.red.shade600
                                : LpColors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Item description / summary
                if (req.requestedItemsSummary != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LpColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.requestedItemsSummary!,
                      style: LpTypography.bodySm.copyWith(
                        color: LpColors.onSurface,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Cashier Note / Reason
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ribbonBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorderColor.withAlpha(120)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 14, color: tagColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '"${req.reason}"',
                          style: LpTypography.bodySm.copyWith(
                            fontStyle: FontStyle.italic,
                            color: LpColors.onSurface,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Decision State or Action Buttons
                if (req.status == ApprovalStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LpColors.error,
                            side: const BorderSide(color: LpColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Tolak'),
                          onPressed: () => _handleRejectPrompt(context, req),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LpColors.primary,
                            foregroundColor: LpColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.lock_open, size: 16),
                          label: Text(
                            req.type == ApprovalType.purchaseOrder
                                ? 'Approve (Kirim WA)'
                                : 'Setujui (PIN)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _handleApproveWithPin(context, req),
                        ),
                      ),
                    ],
                  ),
                ] else if (req.status == ApprovalStatus.approved) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Disetujui: ${req.decisionNotes ?? ""}',
                            style: LpTypography.bodySm.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Ditolak: ${req.decisionNotes ?? ""}',
                            style: LpTypography.bodySm.copyWith(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
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

  String _formatMinutesAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    return '${diff.inHours} jam lalu';
  }
}
