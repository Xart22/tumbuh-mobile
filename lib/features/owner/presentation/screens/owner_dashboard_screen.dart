import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../data/remote/owner_repository.dart';
import '../../bloc/owner_bloc.dart';
import '../../bloc/owner_event.dart';
import '../../bloc/owner_state.dart';
import '../../data/models/approval_model.dart';
import '../widgets/owner_approvals_view.dart';
import '../widgets/owner_grid_kpis.dart';
import '../widgets/owner_hourly_chart.dart';
import '../widgets/owner_inventory_view.dart';
import '../widgets/owner_kpi_card.dart';
import '../widgets/owner_pin_dialog.dart';
import '../widgets/owner_reports_view.dart';
import '../widgets/owner_settings_view.dart';
import '../widgets/owner_top_bar.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        OwnerRepository? ownerRepository;
        try {
          ownerRepository = context.read<OwnerRepository>();
        } catch (_) {
          ownerRepository = null;
        }
        return OwnerBloc(ownerRepository: ownerRepository);
      },
      child: const _OwnerDashboardContent(),
    );
  }
}

class _OwnerDashboardContent extends StatelessWidget {
  const _OwnerDashboardContent();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OwnerBloc>();

    return BlocConsumer<OwnerBloc, OwnerState>(
      listenWhen: (previous, current) =>
          previous.lastDecisionMessage != current.lastDecisionMessage &&
          current.lastDecisionMessage != null,
      listener: (context, state) {
        if (state.lastDecisionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.lastDecisionMessage!,
                style: LpTypography.bodySm.copyWith(color: Colors.white),
              ),
              backgroundColor: LpColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: LpColors.background,
          appBar: OwnerTopBar(
            currentOutlet: state.selectedOutlet,
            availableOutlets: state.availableOutlets,
            pendingApprovalsCount: state.pendingApprovalsCount,
            onOutletSelected: (outlet) => bloc.add(OwnerSelectOutlet(outlet)),
            onApprovalsTap: () => bloc.add(const OwnerSelectTab(3)),
            onNotificationsTap: () => bloc.add(const OwnerSelectTab(3)),
          ),
          body: IndexedStack(
            index: state.currentTabIndex,
            children: [
              // Tab 0: Dashboard
              _buildDashboardTab(context, bloc, state),

              // Tab 1: Laporan
              OwnerReportsView(
                kpiData: state.kpiData,
                topProducts: state.topProducts,
                paymentShares: state.paymentShares,
                selectedDateRange: state.reportDateRange,
                onDateRangeChanged: (range) => bloc.add(OwnerChangeReportDateRange(range)),
              ),

              // Tab 2: Stok Bahan
              OwnerInventoryView(
                items: state.stockAlerts,
                onQuickReorder: (itemId, qty) =>
                    bloc.add(OwnerQuickReorderItem(itemId: itemId, quantity: qty)),
              ),

              // Tab 3: Persetujuan
              OwnerApprovalsView(
                approvals: state.filteredApprovals,
                currentFilter: state.approvalFilter,
                pendingCount: state.pendingApprovalsCount,
                approvedCount: state.approvedCount,
                rejectedCount: state.rejectedCount,
                onFilterChanged: (filter) => bloc.add(OwnerFilterApprovalStatus(filter)),
                onApprove: (id, pin) => bloc.add(OwnerApproveRequest(requestId: id, pin: pin)),
                onReject: (id, reason) =>
                    bloc.add(OwnerRejectRequest(requestId: id, reason: reason)),
              ),

              // Tab 4: Pengaturan
              OwnerSettingsView(
                currentOutlet: state.selectedOutlet,
                availableOutlets: state.availableOutlets,
                onOutletChanged: (outlet) => bloc.add(OwnerSelectOutlet(outlet)),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context, bloc, state),
        );
      },
    );
  }

  Widget _buildDashboardTab(BuildContext context, OwnerBloc bloc, OwnerState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Primary Financial KPI Card
        OwnerKpiCard(kpiData: state.kpiData),
        const SizedBox(height: 12),

        // 2. 2x2 Grid Secondary Metrics
        OwnerGridKpis(kpiData: state.kpiData),
        const SizedBox(height: 16),

        // 3. Urgent Action Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'PERSETUJUAN & ALERT MENDESAK',
                style: LpTypography.labelSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.outline,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (state.pendingApprovalsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '${state.pendingApprovalsCount} Butuh Aksi',
                  style: LpTypography.mono.copyWith(
                    color: Colors.red.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Urgent Void Approval Quick Card
        if (state.approvals.any((a) => a.type == ApprovalType.voidOrder && a.status == ApprovalStatus.pending)) ...[
          _buildQuickVoidCard(context, bloc, state.approvals.firstWhere((a) => a.type == ApprovalType.voidOrder && a.status == ApprovalStatus.pending)),
          const SizedBox(height: 10),
        ],

        // Critical Inventory Alert Banner
        _buildCriticalStockBanner(context, bloc, state),
        const SizedBox(height: 16),

        // 4. Tren Penjualan Per Jam
        OwnerHourlyChart(points: state.hourlySales),
      ],
    );
  }

  Widget _buildQuickVoidCard(BuildContext context, OwnerBloc bloc, ApprovalRequest voidReq) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: LpColors.secondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PERSETUJUAN VOID DIBUTUHKAN',
                        style: LpTypography.labelSm.copyWith(
                          color: LpColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '2 mnt lalu',
                style: LpTypography.mono.copyWith(
                  color: LpColors.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Kasir ',
              style: LpTypography.bodySm.copyWith(color: LpColors.onSurface, fontSize: 11),
              children: [
                TextSpan(
                  text: voidReq.requestedBy,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' meminta void tiket '),
                TextSpan(
                  text: voidReq.ticketNumber ?? '',
                  style: LpTypography.mono.copyWith(
                    color: LpColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' (${OrderMath.formatCurrency(voidReq.amount)}).',
                ),
              ],
            ),
          ),
          if (voidReq.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: LpColors.outlineVariant.withAlpha(100)),
              ),
              child: Text(
                '"${voidReq.reason}"',
                style: LpTypography.bodySm.copyWith(
                  fontStyle: FontStyle.italic,
                  color: LpColors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LpColors.primary,
                    foregroundColor: LpColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size.fromHeight(38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Setujui (PIN)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final pin = await OwnerPinBottomSheet.show(
                      context,
                      title: 'Otorisasi Void',
                      description: 'Masukkan PIN Owner untuk menyetujui void',
                    );
                    if (pin != null && pin.isNotEmpty) {
                      bloc.add(OwnerApproveRequest(requestId: voidReq.id, pin: pin));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: LpColors.error,
                  side: const BorderSide(color: LpColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(80, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Tolak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  bloc.add(OwnerRejectRequest(
                    requestId: voidReq.id,
                    reason: 'Ditolak cepat dari dashboard ringkasan',
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalStockBanner(BuildContext context, OwnerBloc bloc, OwnerState state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.red, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stok Kritis: Sirup Karamel',
                        style: LpTypography.bodySm.copyWith(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Sisa 1 botol (Batas Min. 3 botol)',
                        style: LpTypography.bodySm.copyWith(
                          color: LpColors.onSurfaceVariant,
                          fontSize: 10,
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
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => bloc.add(const OwnerSelectTab(2)),
            child: const Text('Restok', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, OwnerBloc bloc, OwnerState state) {
    final tabs = [
      _NavTabItem(icon: Icons.grid_view, label: 'Dashboard'),
      _NavTabItem(icon: Icons.bar_chart, label: 'Laporan'),
      _NavTabItem(icon: Icons.inventory_2_outlined, label: 'Stok Bahan'),
      _NavTabItem(
        icon: Icons.fact_check_outlined,
        label: 'Persetujuan',
        badgeCount: state.pendingApprovalsCount,
      ),
      _NavTabItem(icon: Icons.settings_outlined, label: 'Pengaturan'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: LpColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: LpColors.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final idx = entry.key;
              final tab = entry.value;
              final isSelected = state.currentTabIndex == idx;

              return Expanded(
                child: InkWell(
                  onTap: () => bloc.add(OwnerSelectTab(idx)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: isSelected
                                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                                  : const EdgeInsets.all(4),
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: LpColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    )
                                  : null,
                              child: Icon(
                                tab.icon,
                                size: 22,
                                color: isSelected
                                    ? LpColors.onPrimaryContainer
                                    : LpColors.onSurfaceVariant,
                              ),
                            ),
                            if (tab.badgeCount != null && tab.badgeCount! > 0)
                              Positioned(
                                top: -2,
                                right: isSelected ? 8 : -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: LpColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${tab.badgeCount}',
                                      style: LpTypography.mono.copyWith(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: LpTypography.labelSm.copyWith(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? LpColors.primary : LpColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem {
  final IconData icon;
  final String label;
  final int? badgeCount;

  _NavTabItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });
}
