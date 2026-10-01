import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _shortDateTimeFormat = DateFormat('HH:mm • dd/MM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static tz.Location? _jakarta;

  /// Forces date/time display to Asia/Jakarta regardless of the device time
  /// zone. Call once at startup; without it, falls back to the device zone.
  static void initJakarta() {
    tzdata.initializeTimeZones();
    _jakarta = tz.getLocation('Asia/Jakarta');
  }

  static DateTime _inZone(DateTime dateTime) {
    final jakarta = _jakarta;
    if (jakarta == null) return dateTime.toLocal();
    return tz.TZDateTime.from(dateTime, jakarta);
  }

  /// Formats date and time: "01 Okt 2026, 14:30"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(_inZone(dateTime));
  }

  /// Formats short date and time for receipts: "14:18 • 12/05"
  static String formatShortDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _shortDateTimeFormat.format(_inZone(dateTime));
  }


  /// Formats date: "01 Oktober 2026"
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateFormat.format(_inZone(dateTime));
  }

  /// Formats short date: "01/10/2026"
  static String formatShortDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _shortDateFormat.format(_inZone(dateTime));
  }

  /// Formats time only: "14:30"
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _timeFormat.format(_inZone(dateTime));
  }

  /// Formats duration for kitchen display elapsed timer (e.g., "08:42")
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
