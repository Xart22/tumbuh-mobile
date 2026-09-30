import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            );

  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserRole = 'user_role';
  static const String _keyDeviceId = 'device_id';
  static const String _keyActiveOutletId = 'active_outlet_id';
  static const String _keyActiveShiftId = 'active_shift_id';
  static const String _keyOfflinePinHash = 'offline_pin_hash';

  // --- Auth Token ---
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // --- Refresh Token ---
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // --- Role ---
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  // --- Device ID ---
  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: _keyDeviceId);
  }

  // --- Active Outlet & Shift ---
  Future<void> saveActiveOutletId(String outletId) async {
    await _storage.write(key: _keyActiveOutletId, value: outletId);
  }

  Future<String?> getActiveOutletId() async {
    return await _storage.read(key: _keyActiveOutletId);
  }

  Future<void> saveActiveShiftId(String shiftId) async {
    await _storage.write(key: _keyActiveShiftId, value: shiftId);
  }

  Future<String?> getActiveShiftId() async {
    return await _storage.read(key: _keyActiveShiftId);
  }

  Future<void> clearShift() async {
    await _storage.delete(key: _keyActiveShiftId);
  }

  // --- Offline PIN Hash ---
  Future<void> saveOfflinePinHash(String hash) async {
    await _storage.write(key: _keyOfflinePinHash, value: hash);
  }

  Future<String?> getOfflinePinHash() async {
    return await _storage.read(key: _keyOfflinePinHash);
  }

  /// Global logout: clears all credentials and shift data while keeping device binding intact
  Future<void> clearAuth() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserRole);
    await _storage.delete(key: _keyActiveShiftId);
  }
}
