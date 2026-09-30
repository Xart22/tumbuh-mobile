import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/data/local/db/app_database.dart';
import 'package:tumbuh_mobile/data/local/outbox/outbox_dao.dart';

void main() {
  late AppDatabase db;
  late OutboxDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = OutboxDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueue persists a follow-up chain for offline replay', () async {
    await dao.enqueue(
      endpoint: '/v1/orders',
      method: 'POST',
      payload: {'orderType': 'dine_in'},
      idempotencyKey: 'key-1',
      followUp: {
        'endpoint': '/v1/payments',
        'method': 'POST',
        'body': {'method': 'cash', 'amount': 10000},
      },
    );

    final pending = await dao.getPendingEvents();
    expect(pending, hasLength(1));
    expect(pending.first.status, 'pending');
    final followUp =
        jsonDecode(pending.first.followUpJson!) as Map<String, dynamic>;
    expect(followUp['endpoint'], '/v1/payments');
    expect(followUp['method'], 'POST');
  });

  test('follow-up is null when not provided', () async {
    await dao.enqueue(
      endpoint: '/v1/shifts/open',
      method: 'POST',
      payload: {},
    );
    final pending = await dao.getPendingEvents();
    expect(pending.first.followUpJson, isNull);
  });
}
