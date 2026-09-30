import 'package:flutter/material.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/owner_dashboard_model.dart';

class OwnerKpiCard extends StatelessWidget {
  final OwnerKpiData kpiData;

  const OwnerKpiCard({
    super.key,
    required this.kpiData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LpColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LpColors.outlineVariant.withAlpha(120),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent line
          Container(
            height: 4,
            color: LpColors.primary,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'TOTAL OMZET HARI INI',
                              style: LpTypography.labelSm.copyWith(
                                color: LpColors.outline,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: LpColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: LpColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: LpColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Real-time',
                            style: LpTypography.labelSm.copyWith(
                              color: LpColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Revenue & Growth Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        OrderMath.formatCurrency(kpiData.todayRevenue),
                        style: LpTypography.mono.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: LpColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: LpColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: LpColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '+${kpiData.growthVsYesterdayPct}%',
                            style: LpTypography.mono.copyWith(
                              color: LpColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'vs kemarin pada jam yang sama',
                  style: LpTypography.bodySm.copyWith(
                    color: LpColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),

                // Target Progress Bar
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: LpColors.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Target Omzet: ',
                                style: LpTypography.bodySm.copyWith(
                                  color: LpColors.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${(kpiData.targetProgressPct * 100).toInt()}% tercapai',
                                    style: LpTypography.mono.copyWith(
                                      color: LpColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            OrderMath.formatCurrency(kpiData.targetRevenue),
                            style: LpTypography.mono.copyWith(
                              color: LpColors.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: kpiData.targetProgressPct,
                          minHeight: 8,
                          backgroundColor: LpColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(LpColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
