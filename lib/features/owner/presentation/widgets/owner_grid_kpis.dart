import 'package:flutter/material.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/owner_dashboard_model.dart';

class OwnerGridKpis extends StatelessWidget {
  final OwnerKpiData kpiData;

  const OwnerGridKpis({
    super.key,
    required this.kpiData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            // Card 1: Laba Kotor
            _buildMetricCard(
              title: 'Laba Kotor (Margin)',
              icon: Icons.account_balance_wallet_outlined,
              primaryValue: OrderMath.formatCurrency(kpiData.grossProfit),
              bottomWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LpColors.secondaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${kpiData.grossMarginPct}% Sehat',
                  style: LpTypography.mono.copyWith(
                    color: LpColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Card 2: Total Transaksi
            _buildMetricCard(
              title: 'Total Transaksi',
              icon: Icons.receipt_long_outlined,
              primaryValue: '${kpiData.transactionCount} Struk',
              bottomWidget: Text(
                'Rata-rata: ${OrderMath.formatCurrency(kpiData.avgTicket)}',
                style: LpTypography.bodySm.copyWith(
                  color: LpColors.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Card 3: Bill Berjalan
            _buildMetricCard(
              title: 'Bill Berjalan',
              icon: Icons.table_restaurant_outlined,
              primaryValue: '${kpiData.openBillsCount} Meja Open',
              bottomWidget: Text(
                'Tertahan: ${OrderMath.formatCurrency(kpiData.openBillsValue)}',
                style: LpTypography.bodySm.copyWith(
                  color: LpColors.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Card 4: Setoran Kasir
            _buildMetricCard(
              title: 'Setoran Kasir',
              icon: Icons.payments_outlined,
              primaryValue: OrderMath.formatCurrency(kpiData.cashierDeposit),
              bottomWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LpColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  kpiData.cashVariance == 0
                      ? 'Selisih Rp 0 Pas'
                      : 'Selisih ${OrderMath.formatCurrency(kpiData.cashVariance)}',
                  style: LpTypography.labelSm.copyWith(
                    color: kpiData.cashVariance == 0 ? LpColors.primary : LpColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required String primaryValue,
    required Widget bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LpColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LpColors.outlineVariant.withAlpha(120),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: LpTypography.labelSm.copyWith(
                    color: LpColors.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: LpColors.outline),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              primaryValue,
              style: LpTypography.mono.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LpColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          bottomWidget,
        ],
      ),
    );
  }
}
