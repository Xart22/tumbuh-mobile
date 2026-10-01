import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tumbuh_mobile/shared/formatters/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    DateFormatter.initJakarta();
  });

  test('formats timestamps in Asia/Jakarta (+7)', () {
    final utc = DateTime.utc(2026, 10, 1, 7, 30);
    expect(DateFormatter.formatTime(utc), '14:30');
    expect(DateFormatter.formatShortDate(utc), '01/10/2026');
  });
}
