import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/device/device_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/security/secure_storage_service.dart';
import '../models/auth_user.dart';
import '../models/outlet_pricing.dart';
import '../models/outlet_summary.dart';

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

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : Map<String, dynamic>.from(value as Map);

  /// Logs in Cashier with 6-digit PIN against the active outlet.
  /// Backend: `POST /v1/auth/login-kasir` body `{outletId, pin}`.
  Future<AuthUser> loginKasir({
    required String pin,
    String? outletId,
    String? cashierName,
  }) async {
    final activeOutletId = outletId ?? await _storage.getActiveOutletId();
    if (activeOutletId == null || activeOutletId.isEmpty) {
      throw const ValidationException(
        message: 'Outlet belum diatur di tablet ini. Jalankan Setup Outlet (Owner) dulu.',
      );
    }

    final deviceId = await _deviceService.getOrCreateDeviceId();

    try {
      final response = await _apiClient.dio.post(
        '/v1/auth/login-kasir',
        data: {
          'outletId': activeOutletId,
          'pin': pin,
        },
      );

      final data = _asMap(response.data);
      final token = data['accessToken'] as String;
      final parsed = AuthUser.fromJson(_asMap(data['user']));
      final user = AuthUser(
        id: parsed.id,
        name: parsed.name,
        email: parsed.email,
        role: parsed.role,
        outletId: activeOutletId,
      );

      await _storage.saveToken(token);
      await _storage.saveUserRole(user.role);
      await _storage.saveActiveOutletId(activeOutletId);

      // Cache salted PIN hash for emergency offline verification
      final pinHash = sha256.convert(utf8.encode('$deviceId:$activeOutletId:$pin')).toString();
      await _storage.saveOfflinePinHash(pinHash);

      return user;
    } on ApiException catch (e) {
      if (e is NetworkOfflineException) {
        // Offline verification check
        final cachedHash = await _storage.getOfflinePinHash();
        final inputHash = sha256.convert(utf8.encode('$deviceId:$activeOutletId:$pin')).toString();

        if (cachedHash != null && cachedHash == inputHash) {
          final user = AuthUser(
            id: 'offline',
            name: cashierName ?? 'Kasir (Offline)',
            email: '',
            role: 'kasir',
            outletId: activeOutletId,
            shiftTitle: 'Shift Berjalan (Offline)',
          );
          await _storage.saveUserRole(user.role);
          return user;
        }
        throw const ValidationException(
          message: 'Mode offline: PIN kasir tidak cocok dengan kredensial tersimpan di tablet ini.',
        );
      }
      rethrow;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  /// Logs in Owner with Email and Password.
  /// Backend: `POST /v1/auth/login` body `{email, password, tenantSlug?}`.
  Future<AuthUser> loginOwner({
    required String email,
    required String password,
    String? tenantSlug,
  }) async {
    final response = await _apiClient.dio.post(
      '/v1/auth/login',
      data: {
        'email': email,
        'password': password,
        if (tenantSlug != null && tenantSlug.trim().isNotEmpty)
          'tenantSlug': tenantSlug.trim(),
      },
    );

    final data = _asMap(response.data);
    if (data['requiresWorkspace'] == true) {
      throw const ValidationException(
        message: 'Email ini terdaftar di beberapa workspace. Isi kolom Workspace (slug) lalu coba lagi.',
      );
    }

    final token = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String?;
    await _storage.saveToken(token);
    if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
    await _storage.saveUserRole('owner');

    return AuthUser.fromJson(_asMap(data['user']));
  }

  /// Lists outlets in the owner's tenant. Backend: `GET /v1/outlets`.
  Future<List<OutletSummary>> fetchOutlets() async {
    final response = await _apiClient.dio.get('/v1/outlets');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => OutletSummary.fromJson(_asMap(item)))
        .toList();
  }

  /// Fetches and caches outlet pricing rules. Backend: `GET /v1/outlets/:id`.
  Future<OutletPricing> fetchOutletPricing(String outletId) async {
    final response = await _apiClient.dio.get('/v1/outlets/$outletId');
    final pricing = OutletPricing.fromOutletJson(_asMap(response.data));
    await _storage.saveOutletPricing(jsonEncode(pricing.toJson()));
    return pricing;
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
