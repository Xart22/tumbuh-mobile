import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _shortDateTimeFormat = DateFormat('HH:mm • dd/MM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');


  /// Formats date and time: "01 Okt 2026, 14:30"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  /// Formats short date and time for receipts: "14:18 • 12/05"
  static String formatShortDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _shortDateTimeFormat.format(dateTime.toLocal());
  }


  /// Formats date: "01 Oktober 2026"
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateFormat.format(dateTime.toLocal());
  }

  /// Formats short date: "01/10/2026"
  static String formatShortDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _shortDateFormat.format(dateTime.toLocal());
  }

  /// Formats time only: "14:30"
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Formats duration for kitchen display elapsed timer (e.g., "08:42")
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
