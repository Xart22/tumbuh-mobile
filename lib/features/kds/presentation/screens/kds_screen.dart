import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/kds_bloc.dart';
import '../../bloc/kds_event.dart';
import '../../bloc/kds_state.dart';
import '../../data/models/kds_ticket.dart';
import '../widgets/kds_header.dart';
import '../widgets/kds_metrics_bar.dart';
import '../widgets/kds_recall_modal.dart';
import '../widgets/kds_ticket_card.dart';

class KdsScreen extends StatefulWidget {
  final bool autoStartTimer;

  const KdsScreen({
    super.key,
    this.autoStartTimer = true,
  });

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  late final KdsBloc _bloc;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _laneScrollController = ScrollController();
  Timer? _liveTicker;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _bloc = KdsBloc(autoStartTimer: false);
    _bloc.add(const KdsLoadTickets());

    if (widget.autoStartTimer) {
      _liveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _bloc.add(KdsTick(DateTime.now()));
        }
      });
    }
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    _laneScrollController.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _cycleNextStation() {
    final current = _bloc.state.selectedStation;
    final allStations = KdsStation.values;
    final nextIndex = (allStations.indexOf(current) + 1) % allStations.length;
    _bloc.add(KdsFilterStation(allStations[nextIndex]));
  }

  void _bumpFirstTicket() {
    final tickets = _bloc.state.filteredTickets;
    if (tickets.isNotEmpty) {
      _bloc.add(KdsBumpTicket(ticketId: tickets.first.id));
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _bumpFirstTicket();
      } else if (event.logicalKey == LogicalKeyboardKey.f1) {
        _cycleNextStation();
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        KdsRecallModal.show(context, bloc: _bloc);
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        _bumpFirstTicket();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isFullscreen) {
          _toggleFullscreen();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: LpColors.kdsBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Industrial Header
                KdsHeader(
                  isFullscreen: _isFullscreen,
                  onToggleFullscreen: _toggleFullscreen,
                  onRecallPressed: () => KdsRecallModal.show(context, bloc: _bloc),
                ),

                // 2. Performance Metrics & Hotkeys Sub-Bar
                const KdsMetricsBar(),

                // 3. Main Horizontal Scrollable Ticket Lanes
                Expanded(
                  child: BlocBuilder<KdsBloc, KdsState>(
                    builder: (context, state) {
                      final tickets = state.filteredTickets;

                      if (tickets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161C24),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: LpColors.kdsCardBorder, width: 2),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 44,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Semua Pesanan Selesai!',
                                style: LpTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dapur siaga menerima pesanan baru dari POS Kasir.',
                                style: LpTypography.bodyMedium.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.read<KdsBloc>().add(const KdsFilterStation(KdsStation.all));
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LpColors.inversePrimary,
                                  side: const BorderSide(color: LpColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Tampilkan Semua Station'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Scrollbar(
                        controller: _laneScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _laneScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < tickets.length; i++) ...[
                                KdsTicketCard(
                                  ticket: tickets[i],
                                  isFirstInQueue: i == 0,
                                ),
                                if (i < tickets.length - 1) const SizedBox(width: 16),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Subtle floating quick switch back to POS Kasir
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/pos');
              }
            },
            backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.point_of_sale_rounded, size: 20),
            label: const Text(
              'POS Kasir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
