import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/remote/kitchen_repository.dart';
import '../data/mock/kds_mock_data.dart';
import '../data/models/kds_ticket.dart';
import 'kds_event.dart';
import 'kds_state.dart';

class KdsBloc extends Bloc<KdsEvent, KdsState> {
  Timer? _timer;
  Timer? _pollTimer;
  final KitchenRepository? _kitchenRepository;
  static const Duration _pollInterval = Duration(seconds: 10);

  KdsBloc({KitchenRepository? kitchenRepository, bool autoStartTimer = false})
      : _kitchenRepository = kitchenRepository,
        super(KdsState(currentTime: DateTime.now())) {
    on<KdsLoadTickets>(_onLoadTickets);
    on<KdsFilterStation>(_onFilterStation);
    on<KdsToggleItemDone>(_onToggleItemDone);
    on<KdsBumpTicket>(_onBumpTicket);
    on<KdsRecallTicket>(_onRecallTicket);
    on<KdsToggleAudio>(_onToggleAudio);
    on<KdsTick>(_onTick);
    on<KdsAddTicket>(_onAddTicket);

    if (autoStartTimer) {
      _startPeriodicTimer();
    }
    if (_kitchenRepository != null) {
      _pollTimer = Timer.periodic(
        _pollInterval,
        (_) => add(const KdsLoadTickets()),
      );
    }
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(KdsTick(DateTime.now()));
    });
  }

  void _playChimeIfEnabled() {
    if (state.isAudioEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {
        // Ignored on platforms without system sound
      }
    }
  }

  Future<void> _onLoadTickets(KdsLoadTickets event, Emitter<KdsState> emit) async {
    final repo = _kitchenRepository;
    if (repo == null) {
      emit(state.copyWith(
        tickets: KdsMockData.getInitialTickets(),
        recalledTickets: KdsMockData.getInitialRecalledTickets(),
        currentTime: DateTime.now(),
        isLoading: false,
      ));
      return;
    }

    try {
      final tickets = await repo.fetchTickets();
      emit(state.copyWith(
        tickets: tickets,
        currentTime: DateTime.now(),
        isLoading: false,
      ));
    } catch (_) {
      // Keep the last known queue; a later poll retries.
      emit(state.copyWith(currentTime: DateTime.now(), isLoading: false));
    }
  }

  /// Re-fetches the queue while preserving locally tracked recalled tickets.
  Future<void> _refreshQueue(Emitter<KdsState> emit) async {
    final repo = _kitchenRepository;
    if (repo == null) return;
    try {
      final tickets = await repo.fetchTickets();
      emit(state.copyWith(tickets: tickets, currentTime: DateTime.now()));
    } catch (_) {
      // ignore transient poll errors
    }
  }

  void _onFilterStation(KdsFilterStation event, Emitter<KdsState> emit) {
    emit(state.copyWith(selectedStation: event.station));
  }

  Future<void> _onToggleItemDone(KdsToggleItemDone event, Emitter<KdsState> emit) async {
    if (_kitchenRepository != null) {
      try {
        await _kitchenRepository.bumpItem(event.itemId);
        await _refreshQueue(emit);
      } catch (_) {}
      return;
    }

    final updatedTickets = state.tickets.map((ticket) {
      if (ticket.id != event.ticketId) return ticket;

      final updatedItems = ticket.items.map((item) {
        if (item.id != event.itemId) return item;
        return item.copyWith(isCompleted: !item.isCompleted);
      }).toList();

      final allDone = updatedItems.isNotEmpty && updatedItems.every((i) => i.isCompleted);
      final newStatus = allDone ? KdsTicketStatus.ready : ticket.status;

      return ticket.copyWith(
        items: updatedItems,
        status: newStatus,
      );
    }).toList();

    _playChimeIfEnabled();
    emit(state.copyWith(tickets: updatedTickets));
  }

  Future<void> _onBumpTicket(KdsBumpTicket event, Emitter<KdsState> emit) async {
    final ticketIndex = state.tickets.indexWhere((t) => t.id == event.ticketId);
    if (ticketIndex == -1) return;

    final ticket = state.tickets[ticketIndex];
    _playChimeIfEnabled();

    final repo = _kitchenRepository;
    if (repo != null) {
      try {
        if (ticket.status == KdsTicketStatus.ready) {
          await repo.serveOrder(ticket.id);
          final served = ticket.copyWith(
            status: KdsTicketStatus.served,
            items: ticket.items
                .map((i) => i.copyWith(isCompleted: true))
                .toList(),
          );
          emit(state.copyWith(
            tickets: List<KdsTicket>.from(state.tickets)..removeAt(ticketIndex),
            recalledTickets: [served, ...state.recalledTickets],
          ));
        } else {
          for (final item in ticket.items.where((i) => !i.isCompleted)) {
            await repo.bumpItem(item.id);
          }
          await _refreshQueue(emit);
        }
      } catch (_) {
        // Surfaced by the next poll.
      }
      return;
    }

    if (ticket.status == KdsTicketStatus.queued) {
      // Advance to cooking
      final updatedList = List<KdsTicket>.from(state.tickets);
      updatedList[ticketIndex] = ticket.copyWith(status: KdsTicketStatus.cooking);
      emit(state.copyWith(tickets: updatedList));
    } else if (ticket.status == KdsTicketStatus.cooking && !ticket.isAllItemsCompleted) {
      // Advance to ready (or complete all items)
      final completedItems = ticket.items.map((i) => i.copyWith(isCompleted: true)).toList();
      final updatedList = List<KdsTicket>.from(state.tickets);
      updatedList[ticketIndex] = ticket.copyWith(
        status: KdsTicketStatus.ready,
        items: completedItems,
      );
      emit(state.copyWith(tickets: updatedList));
    } else {
      // Bump / Complete and move to recalledTickets
      final updatedTickets = List<KdsTicket>.from(state.tickets)..removeAt(ticketIndex);
      final bumpedTicket = ticket.copyWith(
        status: KdsTicketStatus.served,
        items: ticket.items.map((i) => i.copyWith(isCompleted: true)).toList(),
      );
      final updatedRecalled = [bumpedTicket, ...state.recalledTickets];

      emit(state.copyWith(
        tickets: updatedTickets,
        recalledTickets: updatedRecalled,
      ));
    }
  }

  Future<void> _onRecallTicket(KdsRecallTicket event, Emitter<KdsState> emit) async {
    final recallIndex = state.recalledTickets.indexWhere((t) => t.id == event.ticketId);
    if (recallIndex == -1) return;

    if (_kitchenRepository != null) {
      try {
        await _kitchenRepository.recallOrder(event.ticketId);
        final updatedRecalled = List<KdsTicket>.from(state.recalledTickets)
          ..removeAt(recallIndex);
        emit(state.copyWith(recalledTickets: updatedRecalled));
        await _refreshQueue(emit);
      } catch (_) {}
      return;
    }

    final ticketToRestore = state.recalledTickets[recallIndex];
    final updatedRecalled = List<KdsTicket>.from(state.recalledTickets)..removeAt(recallIndex);

    final restoredTicket = ticketToRestore.copyWith(
      status: KdsTicketStatus.ready,
    );

    final updatedTickets = [restoredTicket, ...state.tickets];

    _playChimeIfEnabled();
    emit(state.copyWith(
      tickets: updatedTickets,
      recalledTickets: updatedRecalled,
    ));
  }

  void _onToggleAudio(KdsToggleAudio event, Emitter<KdsState> emit) {
    emit(state.copyWith(isAudioEnabled: !state.isAudioEnabled));
  }

  void _onTick(KdsTick event, Emitter<KdsState> emit) {
    emit(state.copyWith(currentTime: event.currentTime));
  }

  void _onAddTicket(KdsAddTicket event, Emitter<KdsState> emit) {
    _playChimeIfEnabled();
    emit(state.copyWith(
      tickets: [...state.tickets, event.ticket],
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _pollTimer?.cancel();
    return super.close();
  }
}
