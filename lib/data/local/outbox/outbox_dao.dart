import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../db/app_database.dart';

class OutboxDao {
  final AppDatabase _db;

  OutboxDao(this._db);

  /// Enqueues an offline-first mutating event with an idempotent key
  Future<String> enqueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    Map<String, dynamic>? headers,
    String? idempotencyKey,
  }) async {
    final eventId = const Uuid().v4();
    final key = idempotencyKey ?? const Uuid().v4();

    await _db.into(_db.outboxEvents).insert(
          OutboxEventsCompanion.insert(
            id: eventId,
            endpoint: endpoint,
            method: method.toUpperCase(),
            payloadJson: jsonEncode(payload),
            headersJson: Value(headers != null ? jsonEncode(headers) : null),
            idempotencyKey: key,
            status: const Value('pending'),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return eventId;
  }

  /// Gets all pending or failed events ready for replay
  Future<List<OutboxEvent>> getPendingEvents({int limit = 50}) {
    return (_db.select(_db.outboxEvents)
          ..where((tbl) => tbl.status.isIn(['pending', 'failed']))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Updates status to syncing
  Future<void> markSyncing(String id) {
    return (_db.update(_db.outboxEvents)..where((tbl) => tbl.id.equals(id))).write(
      OutboxEventsCompanion(
        status: const Value('syncing'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates status to completed
  Future<void> markCompleted(String id) {
    return (_db.update(_db.outboxEvents)..where((tbl) => tbl.id.equals(id))).write(
      OutboxEventsCompanion(
        status: const Value('completed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates status to failed with error message & increments retry count
  Future<void> markFailed(String id, String errorMessage) async {
    final event = await (_db.select(_db.outboxEvents)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    final currentRetry = event?.retryCount ?? 0;

    await (_db.update(_db.outboxEvents)..where((tbl) => tbl.id.equals(id))).write(
      OutboxEventsCompanion(
        status: const Value('failed'),
        retryCount: Value(currentRetry + 1),
        lastError: Value(errorMessage),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Reactive stream of pending/failed count for UI status indicators
  Stream<int> watchPendingCount() {
    final query = _db.selectOnly(_db.outboxEvents)
      ..addColumns([_db.outboxEvents.id.count()])
      ..where(_db.outboxEvents.status.isIn(['pending', 'failed', 'syncing']));

    return query.map((row) => row.read(_db.outboxEvents.id.count()) ?? 0).watchSingle();
  }
}
