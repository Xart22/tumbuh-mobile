import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/kds_bloc.dart';
import '../../bloc/kds_state.dart';

class KdsMetricsBar extends StatelessWidget {
  const KdsMetricsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KdsBloc, KdsState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: LpColors.kdsSubBar,
            border: Border(
              bottom: BorderSide(color: LpColors.kdsBorderSubtle, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. KPI Throughput metrics
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Average Completion Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: LpColors.inversePrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rata-rata Penyelesaian:',
                          style: LpTypography.labelSm.copyWith(
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.avgCompletionTimeFormatted,
                          style: LpTypography.labelMd.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('|', style: TextStyle(color: Color(0xFF374151))),
                    ),

                    // Completed Today
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF34D399),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Selesai Hari Ini:',
                          style: LpTypography.labelSm.copyWith(
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.completedTodayCount} Pesanan',
                          style: LpTypography.labelMd.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('|', style: TextStyle(color: Color(0xFF374151))),
                    ),

                    // Cooking Now
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sedang Dimasak:',
                          style: LpTypography.labelSm.copyWith(
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.cookingCount} Tiket',
                          style: LpTypography.labelMd.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFDE68A),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('|', style: TextStyle(color: Color(0xFF374151))),
                    ),

                    // Overdue SLA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF450A0A).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF991B1B).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: LpColors.error,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Melewati SLA (>15 mnt):',
                            style: LpTypography.labelSm.copyWith(
                              color: const Color(0xFFFCA5A5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.overdueCount} Tiket',
                            style: LpTypography.labelMd.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

              // 2. Keyboard shortcut hints
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildKbdHint('F1', 'Filter'),
                  const SizedBox(width: 10),
                  _buildKbdHint('F2', 'Recall'),
                  const SizedBox(width: 10),
                  _buildKbdHint('Space', 'Bump Tiket #1'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKbdHint(String keyLabel, String actionLabel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          actionLabel,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
