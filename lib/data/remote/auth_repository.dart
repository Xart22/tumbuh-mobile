import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/device/device_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/security/secure_storage_service.dart';
import '../models/auth_user.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;
  final DeviceService _deviceService;
  final LocalAuthentication _localAuth;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
    required DeviceService deviceService,
    LocalAuthentication? localAuth,
  })  : _apiClient = apiClient,
        _storage = storage,
        _deviceService = deviceService,
        _localAuth = localAuth ?? LocalAuthentication();

  /// Logs in Cashier with 6-digit PIN and hardware Device ID binding
  Future<AuthUser> loginKasir({
    required String pin,
    required String cashierId,
    required String cashierName,
  }) async {
    final deviceId = await _deviceService.getOrCreateDeviceId();

    try {
      final response = await _apiClient.dio.post(
        '/v1/auth/login-kasir',
        data: {
          'pin': pin,
          'cashierId': cashierId,
          'deviceId': deviceId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>;
      final user = AuthUser.fromJson(userData);

      // Save credentials & offline verification hash
      await _storage.saveToken(token);
      if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
      await _storage.saveUserRole(user.role);
      if (user.outletId != null) await _storage.saveActiveOutletId(user.outletId!);

      // Cache salted PIN hash for emergency offline verification
      final pinHash = sha256.convert(utf8.encode('$deviceId:$pin')).toString();
      await _storage.saveOfflinePinHash(pinHash);

      return user;
    } on ApiException catch (e) {
      if (e is NetworkOfflineException) {
        // Offline verification check
        final cachedHash = await _storage.getOfflinePinHash();
        final inputHash = sha256.convert(utf8.encode('$deviceId:$pin')).toString();

        if (cachedHash != null && cachedHash == inputHash) {
          // Offline login successful
          final user = AuthUser(
            id: cashierId,
            name: cashierName,
            email: '',
            role: 'kasir',
            shiftTitle: 'Shift Berjalan (Offline)',
          );
          await _storage.saveUserRole(user.role);
          return user;
        } else {
          throw const ValidationException(
            message: 'Mode offline: PIN kasir tidak cocok dengan kredensial tersimpan di tablet ini.',
          );
        }
      }
      rethrow;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  /// Logs in Owner with Email and Password
  Future<AuthUser> loginOwner({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/v1/auth/login-owner',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final refreshToken = data['refreshToken'] as String?;
    final userData = data['user'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(userData);

    await _storage.saveToken(token);
    if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
    await _storage.saveUserRole(user.role);
    if (user.outletId != null) await _storage.saveActiveOutletId(user.outletId!);

    return user;
  }

  /// Checks if hardware biometric sensor is available on tablet
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Authenticates using device biometrics (fingerprint / face)
  Future<bool> authenticateBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk masuk ke terminal kasir Tumbuh POS',
      );
    } catch (_) {
      return false;
    }
  }

  /// Clears session and logs out
  Future<void> logout() async {
    await _storage.clearAuth();
  }
}
