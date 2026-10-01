import 'api_client.dart';

/// Pings the backend health endpoint (public) to show an online/offline badge.
class HealthService {
  final ApiClient apiClient;

  HealthService({required this.apiClient});

  Future<bool> check() async {
    try {
      final res = await apiClient.dio.get('/v1/health');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data['status'] == 'ok' || data['status'] == 'degraded';
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
