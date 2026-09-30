import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/kds_bloc.dart';
import '../../bloc/kds_event.dart';
import '../../bloc/kds_state.dart';
import '../../data/models/kds_ticket.dart';

class KdsHeader extends StatefulWidget {
  final VoidCallback onRecallPressed;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;

  const KdsHeader({
    super.key,
    required this.onRecallPressed,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  State<KdsHeader> createState() => _KdsHeaderState();
}

class _KdsHeaderState extends State<KdsHeader> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_now);

    return BlocBuilder<KdsBloc, KdsState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: LpColors.kdsHeader,
            border: Border(
              bottom: BorderSide(color: LpColors.kdsCardBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          constraints: const BoxConstraints(minHeight: 58),
          child: Row(
            children: [
              // 1. Left: Brand & Station Identity
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: LpColors.primary.withValues(alpha: 0.2),
                      border: Border.all(color: LpColors.primary, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_rounded,
                          color: LpColors.inversePrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TUMBUH KDS',
                          style: LpTypography.labelLg.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: LpColors.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'KDS Antrean Dapur & Bar',
                            style: LpTypography.titleSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cabang Tebet • Hub: #TB-01',
                        style: LpTypography.labelSm.copyWith(
                          color: const Color(0xFF9CA3AF),
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // 2. Center: Station Filter Tabs (Takes remaining space and scrolls if needed)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: LpColors.kdsBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LpColors.kdsCardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: KdsStation.values.map((station) {
                        final isSelected = state.selectedStation == station;
                        final count = state.getStationTicketCount(station);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () {
                              context.read<KdsBloc>().add(KdsFilterStation(station));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 40),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? LpColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    station.icon,
                                    size: 15,
                                    color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${station.label} ($count)',
                                    style: LpTypography.labelMd.copyWith(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                                      fontSize: 11,
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
              ),

              const SizedBox(width: 12),

              // 3. Right: Audio Toggle, Recall, Digital Clock & Kiosk Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio Toggle
                  InkWell(
                    onTap: () {
                      context.read<KdsBloc>().add(const KdsToggleAudio());
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: state.isAudioEnabled
                            ? const Color(0xFF064E3B).withValues(alpha: 0.6)
                            : const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: state.isAudioEnabled
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : const Color(0xFF374151),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state.isAudioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 16,
                            color: state.isAudioEnabled ? const Color(0xFF6EE7B7) : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            state.isAudioEnabled ? 'Audio On' : 'Mute',
                            style: LpTypography.labelSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: state.isAudioEnabled ? const Color(0xFF6EE7B7) : const Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Recall Button
                  InkWell(
                    onTap: widget.onRecallPressed,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: LpColors.secondaryFixed,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Recall (${state.recalledTickets.length})',
                            style: LpTypography.labelSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Digital Realtime Clock
                  Container(
                    constraints: const BoxConstraints(minWidth: 84),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LpColors.kdsBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LpColors.kdsCardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeStr,
                          style: LpTypography.titleMd.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            fontSize: 14,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'WIB • ONLINE',
                          style: LpTypography.labelSm.copyWith(
                            fontFamily: 'monospace',
                            color: const Color(0xFF9CA3AF),
                            fontSize: 9,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Fullscreen Kiosk Mode Button
                  InkWell(
                    onTap: widget.onToggleFullscreen,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A222D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LpColors.kdsCardBorder),
                      ),
                      child: Icon(
                        widget.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
