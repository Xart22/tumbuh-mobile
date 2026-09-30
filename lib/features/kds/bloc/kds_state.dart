import 'package:equatable/equatable.dart';
import '../data/models/kds_ticket.dart';

class KdsState extends Equatable {
  final List<KdsTicket> tickets;
  final List<KdsTicket> recalledTickets;
  final KdsStation selectedStation;
  final bool isAudioEnabled;
  final bool isLoading;
  final DateTime currentTime;
  final int baseCompletedCount;

  const KdsState({
    this.tickets = const [],
    this.recalledTickets = const [],
    this.selectedStation = KdsStation.all,
    this.isAudioEnabled = true,
    this.isLoading = false,
    required this.currentTime,
    this.baseCompletedCount = 32,
  });

  List<KdsTicket> get filteredTickets {
    if (selectedStation == KdsStation.all) {
      return tickets;
    }
    return tickets.where((t) => t.hasStation(selectedStation)).toList();
  }

  int getStationTicketCount(KdsStation station) {
    if (station == KdsStation.all) {
      return tickets.length;
    }
    return tickets.where((t) => t.hasStation(station)).length;
  }

  int get cookingCount {
    return tickets.where((t) => t.status == KdsTicketStatus.cooking).length;
  }

  int get overdueCount {
    return tickets.where((t) => t.calculateUrgency(currentTime) == KdsUrgency.overdue).length;
  }

  int get completedTodayCount {
    return baseCompletedCount + recalledTickets.length;
  }

  String get avgCompletionTimeFormatted => '08:24 mnt';

  KdsState copyWith({
    List<KdsTicket>? tickets,
    List<KdsTicket>? recalledTickets,
    KdsStation? selectedStation,
    bool? isAudioEnabled,
    bool? isLoading,
    DateTime? currentTime,
    int? baseCompletedCount,
  }) {
    return KdsState(
      tickets: tickets ?? this.tickets,
      recalledTickets: recalledTickets ?? this.recalledTickets,
      selectedStation: selectedStation ?? this.selectedStation,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isLoading: isLoading ?? this.isLoading,
      currentTime: currentTime ?? this.currentTime,
      baseCompletedCount: baseCompletedCount ?? this.baseCompletedCount,
    );
  }

  @override
  List<Object?> get props => [
        tickets,
        recalledTickets,
        selectedStation,
        isAudioEnabled,
        isLoading,
        currentTime,
        baseCompletedCount,
      ];
}
