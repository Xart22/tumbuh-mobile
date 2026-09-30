import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/mock/kds_mock_data.dart';
import '../data/models/kds_ticket.dart';
import 'kds_event.dart';
import 'kds_state.dart';

class KdsBloc extends Bloc<KdsEvent, KdsState> {
  Timer? _timer;

  KdsBloc({bool autoStartTimer = false})
      : super(KdsState(currentTime: DateTime.now())) {
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

  void _onLoadTickets(KdsLoadTickets event, Emitter<KdsState> emit) {
    emit(state.copyWith(
      tickets: KdsMockData.getInitialTickets(),
      recalledTickets: KdsMockData.getInitialRecalledTickets(),
      currentTime: DateTime.now(),
      isLoading: false,
    ));
  }

  void _onFilterStation(KdsFilterStation event, Emitter<KdsState> emit) {
    emit(state.copyWith(selectedStation: event.station));
  }

  void _onToggleItemDone(KdsToggleItemDone event, Emitter<KdsState> emit) {
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

  void _onBumpTicket(KdsBumpTicket event, Emitter<KdsState> emit) {
    final ticketIndex = state.tickets.indexWhere((t) => t.id == event.ticketId);
    if (ticketIndex == -1) return;

    final ticket = state.tickets[ticketIndex];
    _playChimeIfEnabled();

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

  void _onRecallTicket(KdsRecallTicket event, Emitter<KdsState> emit) {
    final recallIndex = state.recalledTickets.indexWhere((t) => t.id == event.ticketId);
    if (recallIndex == -1) return;

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
    return super.close();
  }
}
