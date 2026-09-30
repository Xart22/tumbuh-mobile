import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../outbox/outbox_dao.dart';

enum SyncStatus {
  idle,
  syncing,
  offline,
  error,
}

class SyncEngine {
  final OutboxDao _outboxDao;
  final ApiClient _apiClient;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncEngine({
    required OutboxDao outboxDao,
    required ApiClient apiClient,
    Connectivity? connectivity,
  })  : _outboxDao = outboxDao,
        _apiClient = apiClient,
        _connectivity = connectivity ?? Connectivity();

  void init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncPendingEvents();
      } else {
        _statusController.add(SyncStatus.offline);
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }

  /// Triggers processing of queued outbox events
  Future<void> syncPendingEvents() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final pendingEvents = await _outboxDao.getPendingEvents();
      if (pendingEvents.isEmpty) {
        _statusController.add(SyncStatus.idle);
        _isSyncing = false;
        return;
      }

      for (final event in pendingEvents) {
        await _outboxDao.markSyncing(event.id);

        try {
          final payload = jsonDecode(event.payloadJson);
          Map<String, dynamic>? customHeaders;
          if (event.headersJson != null) {
            customHeaders = Map<String, dynamic>.from(jsonDecode(event.headersJson!));
          }

          final options = Options(
            method: event.method,
            headers: {
              ...?customHeaders,
              'Idempotency-Key': event.idempotencyKey,
            },
          );

          await _apiClient.dio.request(
            event.endpoint,
            data: payload,
            options: options,
          );

          // Success: mark event as completed
          await _outboxDao.markCompleted(event.id);
        } on DioException catch (dioError) {
          final statusCode = dioError.response?.statusCode;
          // If server returned 409 Conflict, it means it was already processed before -> treat as completed
          if (statusCode == 409) {
            await _outboxDao.markCompleted(event.id);
          } else {
            await _outboxDao.markFailed(
              event.id,
              dioError.message ?? 'HTTP Error $statusCode',
            );
            // Break loop if offline to avoid hammering
            if (dioError.type == DioExceptionType.connectionError ||
                dioError.type == DioExceptionType.connectionTimeout) {
              _statusController.add(SyncStatus.offline);
              break;
            }
          }
        } catch (e) {
          await _outboxDao.markFailed(event.id, e.toString());
        }
      }

      _statusController.add(SyncStatus.idle);
    } catch (_) {
      _statusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }
}
