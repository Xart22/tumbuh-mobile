import 'package:equatable/equatable.dart';
import '../data/models/kds_ticket.dart';

abstract class KdsEvent extends Equatable {
  const KdsEvent();

  @override
  List<Object?> get props => [];
}

class KdsLoadTickets extends KdsEvent {
  const KdsLoadTickets();
}

class KdsFilterStation extends KdsEvent {
  final KdsStation station;

  const KdsFilterStation(this.station);

  @override
  List<Object?> get props => [station];
}

class KdsToggleItemDone extends KdsEvent {
  final String ticketId;
  final String itemId;

  const KdsToggleItemDone({
    required this.ticketId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [ticketId, itemId];
}

class KdsBumpTicket extends KdsEvent {
  final String ticketId;

  const KdsBumpTicket({required this.ticketId});

  @override
  List<Object?> get props => [ticketId];
}

class KdsRecallTicket extends KdsEvent {
  final String ticketId;

  const KdsRecallTicket({required this.ticketId});

  @override
  List<Object?> get props => [ticketId];
}

class KdsToggleAudio extends KdsEvent {
  const KdsToggleAudio();
}

class KdsTick extends KdsEvent {
  final DateTime currentTime;

  KdsTick([DateTime? time]) : currentTime = time ?? DateTime.now();

  @override
  List<Object?> get props => [currentTime];
}

class KdsAddTicket extends KdsEvent {
  final KdsTicket ticket;

  const KdsAddTicket(this.ticket);

  @override
  List<Object?> get props => [ticket];
}
