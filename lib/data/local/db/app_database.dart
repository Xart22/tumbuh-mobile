import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Outbox events queue for offline-first transactional replay
class OutboxEvents extends Table {
  TextColumn get id => text()();
  TextColumn get endpoint => text()();
  TextColumn get method => text()(); // POST, PUT, PATCH, DELETE
  TextColumn get headersJson => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, syncing, completed, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache for menu categories
class CachedCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache for menu products
class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  IntColumn get price => integer()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get stockQuantity => real().withDefault(const Constant(0.0))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get optionsJson => text().nullable()(); // Variants & modifiers JSON
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache for customers
class CachedCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  IntColumn get stampsCount => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  OutboxEvents,
  CachedCategories,
  CachedProducts,
  CachedCustomers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'tumbuh_pos_db');
  }
}
