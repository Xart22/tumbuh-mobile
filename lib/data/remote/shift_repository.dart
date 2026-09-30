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

  /// Retrieves currently active shift for this bound device
  Future<ShiftModel?> getCurrentShift() async {
    final deviceId = await _deviceService.getOrCreateDeviceId();

    try {
      final response = await _apiClient.dio.get(
        '/v1/shifts/current',
        queryParameters: {'deviceId': deviceId},
      );

      if (response.data == null) {
        await _storage.clearShift();
        return null;
      }

      final shift = ShiftModel.fromJson(response.data as Map<String, dynamic>);
      await _storage.saveActiveShiftId(shift.id);
      return shift;
    } on ApiException catch (e) {
      if (e is NetworkOfflineException || e is NotFoundException) {
        // Fallback to locally tracked active shift if any
        final activeShiftId = await _storage.getActiveShiftId();
        if (activeShiftId != null) {
          // Return simulated offline shift snapshot
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

    final payload = {
      'id': newShiftId,
      'deviceId': deviceId,
      'outletId': outletId,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'shiftName': effectiveShiftName,
      'initialFloat': initialFloat,
      'startTime': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _apiClient.dio.post(
        '/v1/shifts/open',
        data: payload,
      );

      final shift = ShiftModel.fromJson(response.data as Map<String, dynamic>);
      await _storage.saveActiveShiftId(shift.id);
      return shift;
    } on ApiException catch (e) {
      if (e is NetworkOfflineException) {
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
    final payload = {
      'shiftId': shiftId,
      'actualCashCount': actualCash,
      'handoverNotes': handoverNotes,
      'varianceReason': varianceReason,
      'supervisorPin': supervisorPin,
      'denominations': denominationBreakdown,
      'endTime': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _apiClient.dio.post(
        '/v1/shifts/close',
        data: payload,
      );

      final shift = ShiftModel.fromJson(response.data as Map<String, dynamic>);
      await _storage.clearShift();
      return shift;
    } on ApiException catch (e) {
      if (e is NetworkOfflineException) {
        // Enqueue into outbox
        await _outboxDao.enqueue(
          endpoint: '/v1/shifts/close',
          method: 'POST',
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
      rethrow;
    }
  }
}
