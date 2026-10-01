import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../data/models/cash_denomination.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/remote/shift_repository.dart';

// --- Events ---
abstract class ShiftEvent extends Equatable {
  const ShiftEvent();
  @override
  List<Object?> get props => [];
}

class ShiftLoadCurrent extends ShiftEvent {}

/// Full reset on logout / 401: drop the in-memory active shift.
class ShiftSessionReset extends ShiftEvent {}

class ShiftOpenRequested extends ShiftEvent {
  final int initialFloat;
  final String cashierId;
  final String cashierName;
  final String? shiftName;

  const ShiftOpenRequested({
    required this.initialFloat,
    required this.cashierId,
    required this.cashierName,
    this.shiftName,
  });

  @override
  List<Object?> get props => [initialFloat, cashierId, cashierName, shiftName];
}

class ShiftDenominationAdjusted extends ShiftEvent {
  final int index;
  final int delta;

  const ShiftDenominationAdjusted({required this.index, required this.delta});

  @override
  List<Object?> get props => [index, delta];
}

class ShiftDenominationSet extends ShiftEvent {
  final int index;
  final int count;

  const ShiftDenominationSet({required this.index, required this.count});

  @override
  List<Object?> get props => [index, count];
}

class ShiftResetCounts extends ShiftEvent {}

class ShiftCloseRequested extends ShiftEvent {
  final String handoverNotes;
  final String? varianceReason;
  final String? supervisorPin;

  const ShiftCloseRequested({
    required this.handoverNotes,
    this.varianceReason,
    this.supervisorPin,
  });

  @override
  List<Object?> get props => [handoverNotes, varianceReason, supervisorPin];
}

// --- States ---
abstract class ShiftState extends Equatable {
  const ShiftState();
  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftNoActiveShift extends ShiftState {}

class ShiftActiveLoaded extends ShiftState {
  final ShiftModel currentShift;
  final List<CashDenomination> denominations;
  final int totalPhysicalCash;
  final int variance;

  const ShiftActiveLoaded({
    required this.currentShift,
    required this.denominations,
    required this.totalPhysicalCash,
    required this.variance,
  });

  bool get isBalancePerfect => variance == 0;
  bool get isMinus => variance < 0;
  bool get isSurplus => variance > 0;

  @override
  List<Object?> get props => [currentShift, denominations, totalPhysicalCash, variance];
}

class ShiftCloseSuccess extends ShiftState {
  final ShiftModel closedShift;
  const ShiftCloseSuccess(this.closedShift);

  @override
  List<Object?> get props => [closedShift];
}

class ShiftError extends ShiftState {
  final String message;
  const ShiftError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository _shiftRepository;
  final AnalyticsService? _analytics;

  ShiftBloc({required ShiftRepository shiftRepository, AnalyticsService? analytics})
      : _shiftRepository = shiftRepository,
        _analytics = analytics,
        super(ShiftInitial()) {
    on<ShiftLoadCurrent>(_onLoadCurrent);
    on<ShiftSessionReset>(_onSessionReset);
    on<ShiftOpenRequested>(_onOpenShift);
    on<ShiftDenominationAdjusted>(_onAdjustDenomination);
    on<ShiftDenominationSet>(_onSetDenomination);
    on<ShiftResetCounts>(_onResetCounts);
    on<ShiftCloseRequested>(_onCloseShift);
  }

  Future<void> _onLoadCurrent(ShiftLoadCurrent event, Emitter<ShiftState> emit) async {
    emit(ShiftLoading());
    try {
      final shift = await _shiftRepository.getCurrentShift();
      if (shift == null || !shift.isOpen) {
        emit(ShiftNoActiveShift());
      } else {
        final denoms = CashDenomination.defaultDenominations();
        final totalPhysical = denoms.fold<int>(0, (sum, d) => sum + d.subtotal);
        final variance = totalPhysical - shift.expectedCashInDrawer;

        emit(
          ShiftActiveLoaded(
            currentShift: shift,
            denominations: denoms,
            totalPhysicalCash: totalPhysical,
            variance: variance,
          ),
        );
      }
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  void _onSessionReset(ShiftSessionReset event, Emitter<ShiftState> emit) {
    emit(ShiftNoActiveShift());
  }

  Future<void> _onOpenShift(ShiftOpenRequested event, Emitter<ShiftState> emit) async {
    emit(ShiftLoading());
    try {
      final shift = await _shiftRepository.openShift(
        initialFloat: event.initialFloat,
        cashierId: event.cashierId,
        cashierName: event.cashierName,
        shiftName: event.shiftName,
      );

      _analytics?.log('shift_open', {'float': event.initialFloat});

      final denoms = CashDenomination.defaultDenominations();
      final totalPhysical = denoms.fold<int>(0, (sum, d) => sum + d.subtotal);
      final variance = totalPhysical - shift.expectedCashInDrawer;

      emit(
        ShiftActiveLoaded(
          currentShift: shift,
          denominations: denoms,
          totalPhysicalCash: totalPhysical,
          variance: variance,
        ),
      );
    } catch (e) {
      _analytics?.log('shift_open_failed', {'error': e.toString()});
      emit(ShiftError(e.toString()));
    }
  }

  void _onAdjustDenomination(ShiftDenominationAdjusted event, Emitter<ShiftState> emit) {
    if (state is! ShiftActiveLoaded) return;
    final currentState = state as ShiftActiveLoaded;

    final updatedDenoms = List<CashDenomination>.from(currentState.denominations);
    final target = updatedDenoms[event.index];
    final newCount = (target.count + event.delta).clamp(0, 9999);
    updatedDenoms[event.index] = target.copyWith(count: newCount);

    final newTotal = updatedDenoms.fold<int>(0, (sum, d) => sum + d.subtotal);
    final newVariance = newTotal - currentState.currentShift.expectedCashInDrawer;

    emit(
      ShiftActiveLoaded(
        currentShift: currentState.currentShift,
        denominations: updatedDenoms,
        totalPhysicalCash: newTotal,
        variance: newVariance,
      ),
    );
  }

  void _onSetDenomination(ShiftDenominationSet event, Emitter<ShiftState> emit) {
    if (state is! ShiftActiveLoaded) return;
    final currentState = state as ShiftActiveLoaded;

    final updatedDenoms = List<CashDenomination>.from(currentState.denominations);
    final target = updatedDenoms[event.index];
    final newCount = event.count.clamp(0, 9999);
    updatedDenoms[event.index] = target.copyWith(count: newCount);

    final newTotal = updatedDenoms.fold<int>(0, (sum, d) => sum + d.subtotal);
    final newVariance = newTotal - currentState.currentShift.expectedCashInDrawer;

    emit(
      ShiftActiveLoaded(
        currentShift: currentState.currentShift,
        denominations: updatedDenoms,
        totalPhysicalCash: newTotal,
        variance: newVariance,
      ),
    );
  }

  void _onResetCounts(ShiftResetCounts event, Emitter<ShiftState> emit) {
    if (state is! ShiftActiveLoaded) return;
    final currentState = state as ShiftActiveLoaded;

    final updatedDenoms = CashDenomination.defaultDenominations();
    final newTotal = 0;
    final newVariance = newTotal - currentState.currentShift.expectedCashInDrawer;

    emit(
      ShiftActiveLoaded(
        currentShift: currentState.currentShift,
        denominations: updatedDenoms,
        totalPhysicalCash: newTotal,
        variance: newVariance,
      ),
    );
  }

  Future<void> _onCloseShift(ShiftCloseRequested event, Emitter<ShiftState> emit) async {
    if (state is! ShiftActiveLoaded) return;
    final currentState = state as ShiftActiveLoaded;

    emit(ShiftLoading());
    try {
      final breakdown = <String, int>{};
      for (final d in currentState.denominations) {
        breakdown[d.label] = d.count;
      }

      final closedShift = await _shiftRepository.closeShift(
        shiftId: currentState.currentShift.id,
        actualCash: currentState.totalPhysicalCash,
        handoverNotes: event.handoverNotes,
        varianceReason: event.varianceReason,
        supervisorPin: event.supervisorPin,
        denominationBreakdown: breakdown,
      );

      _analytics?.log('shift_close', {'variance': closedShift.variance});
      emit(ShiftCloseSuccess(closedShift));
    } catch (e) {
      _analytics?.log('shift_close_failed', {'error': e.toString()});
      emit(ShiftError(e.toString()));
      // Re-emit loaded state so user doesn't lose inputs
      emit(currentState);
    }
  }
}
