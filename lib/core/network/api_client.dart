import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../security/secure_storage_service.dart';
import 'api_exceptions.dart';

typedef OnUnauthorizedCallback = void Function();

class ApiClient {
  final Dio dio;
  final SecureStorageService _storage;
  final OnUnauthorizedCallback? onUnauthorized;

  ApiClient({
    required SecureStorageService storage,
    this.onUnauthorized,
    String? baseUrl,
    Dio? customDio,
  })  : _storage = storage,
        dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.defaultBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                sendTimeout: AppConfig.sendTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Attach Bearer Token
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. Attach Active Outlet Header
          final outletId = await _storage.getActiveOutletId();
          if (outletId != null && outletId.isNotEmpty) {
            options.headers['X-Outlet-Id'] = outletId;
          }

          // 3. Attach Hardware Device ID
          final deviceId = await _storage.getDeviceId();
          if (deviceId != null && deviceId.isNotEmpty) {
            options.headers['X-Device-Id'] = deviceId;
          }

          // 4. Attach Idempotency-Key for mutating requests (POST, PUT, PATCH, DELETE)
          final isMutating = ['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method.toUpperCase());
          if (isMutating && !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = const Uuid().v4();
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // 401 Unauthorized -> Global session invalidation
          if (error.response?.statusCode == 401) {
            await _storage.clearAuth();
            onUnauthorized?.call();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: const UnauthorizedException(),
              ),
            );
          }

          // Convert DioException into our typed domain exceptions
          final mappedException = _mapDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mappedException,
            ),
          );
        },
      ),
    );
  }

  /// Safe GET with retry capability for idempotent endpoints
  Future<Response<T>> getWithRetry<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 800),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await dio.get<T>(path, queryParameters: queryParameters, options: options);
      } on DioException catch (e) {
        if (attempts > maxRetries || e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          rethrow;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  ApiException _mapDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String extractMessage() {
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          final msg = data['message'];
          if (msg is List) return msg.join(', ');
          return msg.toString();
        }
      }
      return error.message ?? 'Terjadi kesalahan jaringan.';
    }

    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(
          message: extractMessage(),
          statusCode: statusCode,
          errors: data is Map<String, dynamic> ? data : null,
        );
      case 401:
        return UnauthorizedException(message: extractMessage(), details: data);
      case 403:
        return ForbiddenException(message: extractMessage(), details: data);
      case 404:
        return NotFoundException(message: extractMessage(), details: data);
      case 409:
        return ConflictException(message: extractMessage(), details: data);
      case 500:
      case 502:
      case 503:
        return ServerException(message: extractMessage(), statusCode: statusCode, details: data);
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError) {
          return const NetworkOfflineException();
        }
        return ApiException(message: extractMessage(), statusCode: statusCode, details: data);
    }
  }
}
