import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/device/device_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/security/secure_storage_service.dart';
import '../local/outbox/outbox_dao.dart';
import '../models/shift_model.dart';

class ShiftRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;
  final DeviceService _deviceService;
  final OutboxDao _outboxDao;

  ShiftRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
    required DeviceService deviceService,
    required OutboxDao outboxDao,
  })  : _apiClient = apiClient,
        _storage = storage,
        _deviceService = deviceService,
        _outboxDao = outboxDao;

  /// Retrieves currently open shift for this outlet.
  /// Backend: `GET /v1/shifts/current` -> `{currentShift|null, recap}`.
  Future<ShiftModel?> getCurrentShift() async {
    final deviceId = await _deviceService.getOrCreateDeviceId();

    try {
      final response = await _apiClient.dio.get('/v1/shifts/current');
      final data = response.data as Map<String, dynamic>?;
      final current = data?['currentShift'];

      if (current == null) {
        await _storage.clearShift();
        return null;
      }

      final shift = ShiftModel.fromBackend(current as Map<String, dynamic>);
      await _storage.saveActiveShiftId(shift.id);
      return shift;
    } on DioException catch (e) {
      final api = apiExceptionFrom(e);
      if (api is NetworkOfflineException || api is NotFoundException) {
        // Fallback to locally tracked active shift if any
        final activeShiftId = await _storage.getActiveShiftId();
        if (activeShiftId != null) {
          return ShiftModel(
            id: activeShiftId,
            shiftNumber: 1,
            shiftName: 'Shift Berjalan (Offline)',
            cashierId: 'current_cashier',
            cashierName: 'Kasir Aktif',
            outletId: 'outlet_current',
            outletName: 'Outlet Utama',
            deviceId: deviceId,
            deviceName: 'Tablet Kasir',
            startTime: DateTime.now().subtract(const Duration(hours: 4)),
            initialFloat: 500000,
            cashSales: 0,
            status: 'open',
          );
        }
        return null;
      }
      if (api != null) throw api;
      rethrow;
    }
  }

  /// Opens a new cashier shift with an initial cash float
  Future<ShiftModel> openShift({
    required int initialFloat,
    required String cashierId,
    required String cashierName,
    String? shiftName,
  }) async {
    final deviceId = await _deviceService.getOrCreateDeviceId();
    final outletId = await _storage.getActiveOutletId() ?? 'outlet_default';
    final newShiftId = 'shift_${const Uuid().v4()}';
    final effectiveShiftName = shiftName ?? 'Shift 1 Pagi';

    // Backend OpenShiftDto: employeeId + optional shiftName/openingCash.
    final payload = {
      'employeeId': cashierId,
      'shiftName': effectiveShiftName,
      'openingCash': initialFloat,
    };

    try {
      final response = await _apiClient.dio.post(
        '/v1/shifts/open',
        data: payload,
      );

      final shift = ShiftModel.fromBackend(response.data as Map<String, dynamic>);
      await _storage.saveActiveShiftId(shift.id);
      return shift;
    } on DioException catch (e) {
      final api = apiExceptionFrom(e);
      if (api is NetworkOfflineException) {
        // Offline-first: enqueue into Outbox
        await _outboxDao.enqueue(
          endpoint: '/v1/shifts/open',
          method: 'POST',
          payload: payload,
        );

        final offlineShift = ShiftModel(
          id: newShiftId,
          shiftNumber: 1,
          shiftName: effectiveShiftName,
          cashierId: cashierId,
          cashierName: cashierName,
          outletId: outletId,
          outletName: 'Outlet Utama',
          deviceId: deviceId,
          deviceName: 'Tablet Kasir Utama',
          startTime: DateTime.now(),
          initialFloat: initialFloat,
          status: 'open',
        );

        await _storage.saveActiveShiftId(newShiftId);
        return offlineShift;
      }
      if (api != null) throw api;
      rethrow;
    }
  }

  /// Closes an active shift with physical cash count and reconciliation
  Future<ShiftModel> closeShift({
    required String shiftId,
    required int actualCash,
    required String handoverNotes,
    String? varianceReason,
    String? supervisorPin,
    Map<String, int>? denominationBreakdown,
  }) async {
    // Backend CloseShiftDto: closingCash only.
    final payload = {'closingCash': actualCash};

    try {
      final response = await _apiClient.dio.patch(
        '/v1/shifts/$shiftId/close',
        data: payload,
      );

      final shift = ShiftModel.fromBackend(response.data as Map<String, dynamic>);
      await _storage.clearShift();
      return shift;
    } on DioException catch (e) {
      final api = apiExceptionFrom(e);
      if (api is NetworkOfflineException) {
        // Enqueue into outbox
        await _outboxDao.enqueue(
          endpoint: '/v1/shifts/$shiftId/close',
          method: 'PATCH',
          payload: payload,
        );

        await _storage.clearShift();

        return ShiftModel(
          id: shiftId,
          shiftNumber: 1,
          shiftName: 'Shift 1 Pagi',
          cashierId: 'cashier',
          cashierName: 'Kasir',
          outletId: 'outlet',
          outletName: 'Outlet Utama',
          deviceId: 'dev',
          deviceName: 'Tablet Kasir',
          startTime: DateTime.now().subtract(const Duration(hours: 8)),
          endTime: DateTime.now(),
          initialFloat: 500000,
          actualCashCount: actualCash,
          handoverNotes: handoverNotes,
          varianceReason: varianceReason,
          status: 'closed',
        );
      }
      if (api != null) throw api;
      rethrow;
    }
  }
}
