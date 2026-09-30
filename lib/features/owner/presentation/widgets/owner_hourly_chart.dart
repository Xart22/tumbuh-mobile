import 'package:flutter/material.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/owner_dashboard_model.dart';

class OwnerHourlyChart extends StatelessWidget {
  final List<HourlySalesPoint> points;

  const OwnerHourlyChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final peakPoint = points.firstWhere(
      (p) => p.isPeak,
      orElse: () => points.first,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LpColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Penjualan Per Jam',
                      style: LpTypography.labelLg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LpColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pola traffic jam sibuk gerai',
                      style: LpTypography.bodySm.copyWith(
                        color: LpColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LpColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hari ini',
                      style: LpTypography.bodySm.copyWith(
                        color: LpColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: LpColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Peak Highlight Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: LpColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Jam Puncak Tertinggi',
                    style: LpTypography.bodySm.copyWith(
                      color: LpColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${peakPoint.hour}:00',
                      style: LpTypography.mono.copyWith(
                        color: LpColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '•',
                        style: LpTypography.bodySm.copyWith(color: LpColors.outline),
                      ),
                    ),
                    Text(
                      OrderMath.formatCurrency(peakPoint.amount),
                      style: LpTypography.mono.copyWith(
                        color: LpColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bars Container
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points.map((point) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (point.isPeak)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: LpColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Peak',
                              style: LpTypography.mono.copyWith(
                                color: LpColors.onPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: point.heightFactor.clamp(0.1, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: point.isPeak
                                      ? LpColors.primary
                                      : point.heightFactor > 0.5
                                          ? LpColors.primary.withAlpha(150)
                                          : LpColors.surfaceContainerHigh,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Hour Axis Labels
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: LpColors.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points.map((point) {
                return Expanded(
                  child: Center(
                    child: Text(
                      point.label,
                      style: LpTypography.mono.copyWith(
                        fontSize: 9,
                        color: point.isPeak ? LpColors.primary : LpColors.outline,
                        fontWeight: point.isPeak ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
