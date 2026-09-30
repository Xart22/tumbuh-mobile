import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

enum KdsStation {
  all(label: 'Semua Station', icon: Icons.apps_rounded),
  barista(label: 'Barista / Coffee', icon: Icons.coffee_rounded),
  kitchen(label: 'Dapur Utama / Kitchen', icon: Icons.soup_kitchen_rounded),
  pastry(label: 'Bakery & Pastry', icon: Icons.bakery_dining_rounded);

  const KdsStation({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

enum KdsUrgency {
  newOrder,
  fresh,
  warning,
  overdue;

  Color get headerBgColor {
    switch (this) {
      case KdsUrgency.overdue:
        return LpColors.kdsOverdue;
      case KdsUrgency.warning:
        return LpColors.kdsAmber;
      case KdsUrgency.fresh:
        return LpColors.kdsFresh;
      case KdsUrgency.newOrder:
        return LpColors.kdsNew;
    }
  }

  Color get borderColor {
    switch (this) {
      case KdsUrgency.overdue:
        return LpColors.kdsOverdueBorder;
      case KdsUrgency.warning:
        return LpColors.kdsAmberBorder;
      case KdsUrgency.fresh:
        return LpColors.kdsFreshBorder;
      case KdsUrgency.newOrder:
        return LpColors.kdsNewBorder;
    }
  }

  String get badgeLabel {
    switch (this) {
      case KdsUrgency.overdue:
        return 'OVERDUE';
      case KdsUrgency.warning:
        return 'MNT';
      case KdsUrgency.fresh:
        return 'FRESH';
      case KdsUrgency.newOrder:
        return 'BARU';
    }
  }

  IconData get icon {
    switch (this) {
      case KdsUrgency.overdue:
        return Icons.alarm_rounded;
      case KdsUrgency.warning:
      case KdsUrgency.fresh:
        return Icons.schedule_rounded;
      case KdsUrgency.newOrder:
        return Icons.update_rounded;
    }
  }

  bool get shouldPulse => this == KdsUrgency.overdue;
}

enum KdsTicketStatus {
  queued,
  cooking,
  ready,
  served;

  String get bumpButtonLabel {
    switch (this) {
      case KdsTicketStatus.queued:
        return 'Mulai Masak / Proses';
      case KdsTicketStatus.cooking:
        return 'Selesaikan Order (F3)';
      case KdsTicketStatus.ready:
        return 'Selesaikan & Serve Tiket (Space)';
      case KdsTicketStatus.served:
        return 'Tiket Selesai';
    }
  }

  IconData get bumpButtonIcon {
    switch (this) {
      case KdsTicketStatus.queued:
        return Icons.soup_kitchen_rounded;
      case KdsTicketStatus.cooking:
        return Icons.check_circle_rounded;
      case KdsTicketStatus.ready:
        return Icons.done_all_rounded;
      case KdsTicketStatus.served:
        return Icons.task_alt_rounded;
    }
  }

  Color bumpButtonColor(KdsUrgency urgency) {
    switch (this) {
      case KdsTicketStatus.ready:
        return urgency == KdsUrgency.overdue ? LpColors.error : LpColors.primary;
      case KdsTicketStatus.cooking:
        return urgency == KdsUrgency.warning ? const Color(0xFF855300) : LpColors.primaryContainer;
      case KdsTicketStatus.queued:
        return LpColors.kdsNew;
      case KdsTicketStatus.served:
        return LpColors.darkShellPanelElevated;
    }
  }
}

class KdsTicketItem {
  final String id;
  final String name;
  final int quantity;
  final KdsStation station;
  final String? stationBadge;
  final String? modifierText;
  final String? notes;
  final bool isCompleted;

  const KdsTicketItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.station,
    this.stationBadge,
    this.modifierText,
    this.notes,
    this.isCompleted = false,
  });

  KdsTicketItem copyWith({
    String? id,
    String? name,
    int? quantity,
    KdsStation? station,
    String? stationBadge,
    String? modifierText,
    String? notes,
    bool? isCompleted,
  }) {
    return KdsTicketItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      station: station ?? this.station,
      stationBadge: stationBadge ?? this.stationBadge,
      modifierText: modifierText ?? this.modifierText,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class KdsTicket {
  final String id;
  final String ticketNumber;
  final String orderType;
  final String tableOrCustomer;
  final String serverName;
  final DateTime enteredAt;
  final List<KdsTicketItem> items;
  final String? specialInstructions;
  final String? customerArrivalNote;
  final KdsTicketStatus status;
  final KdsUrgency? urgencyOverride;
  final int? fixedElapsedSeconds;

  const KdsTicket({
    required this.id,
    required this.ticketNumber,
    required this.orderType,
    required this.tableOrCustomer,
    required this.serverName,
    required this.enteredAt,
    required this.items,
    this.specialInstructions,
    this.customerArrivalNote,
    this.status = KdsTicketStatus.cooking,
    this.urgencyOverride,
    this.fixedElapsedSeconds,
  });

  int getElapsedSeconds([DateTime? currentTime]) {
    if (fixedElapsedSeconds != null) return fixedElapsedSeconds!;
    final now = currentTime ?? DateTime.now();
    final diff = now.difference(enteredAt).inSeconds;
    return diff >= 0 ? diff : 0;
  }

  String formatElapsed([DateTime? currentTime]) {
    final totalSeconds = getElapsedSeconds(currentTime);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  KdsUrgency calculateUrgency([DateTime? currentTime]) {
    if (urgencyOverride != null) return urgencyOverride!;
    final totalSeconds = getElapsedSeconds(currentTime);
    if (totalSeconds > 15 * 60) {
      return KdsUrgency.overdue;
    } else if (totalSeconds >= 5 * 60) {
      return KdsUrgency.warning;
    } else if (totalSeconds >= 60) {
      return KdsUrgency.fresh;
    } else {
      return KdsUrgency.newOrder;
    }
  }

  bool get isAllItemsCompleted => items.isNotEmpty && items.every((item) => item.isCompleted);

  bool hasStation(KdsStation station) {
    if (station == KdsStation.all) return true;
    return items.any((item) => item.station == station);
  }

  KdsTicket copyWith({
    String? id,
    String? ticketNumber,
    String? orderType,
    String? tableOrCustomer,
    String? serverName,
    DateTime? enteredAt,
    List<KdsTicketItem>? items,
    String? specialInstructions,
    String? customerArrivalNote,
    KdsTicketStatus? status,
    KdsUrgency? urgencyOverride,
    int? fixedElapsedSeconds,
  }) {
    return KdsTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      orderType: orderType ?? this.orderType,
      tableOrCustomer: tableOrCustomer ?? this.tableOrCustomer,
      serverName: serverName ?? this.serverName,
      enteredAt: enteredAt ?? this.enteredAt,
      items: items ?? this.items,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      customerArrivalNote: customerArrivalNote ?? this.customerArrivalNote,
      status: status ?? this.status,
      urgencyOverride: urgencyOverride ?? this.urgencyOverride,
      fixedElapsedSeconds: fixedElapsedSeconds ?? this.fixedElapsedSeconds,
    );
  }
}
