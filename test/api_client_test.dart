import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_mobile/core/network/api_client.dart';
import 'package:tumbuh_mobile/core/network/api_exceptions.dart';

void main() {
  group('ApiClient.unwrapEnvelope', () {
    test('returns inner data for backend envelope', () {
      final body = {
        'success': true,
        'data': {'items': [1, 2], 'total': 2},
        'meta': {'requestId': 'req_1'},
      };
      expect(ApiClient.unwrapEnvelope(body), {'items': [1, 2], 'total': 2});
    });

    test('passes through already-flat payloads', () {
      final body = {'accessToken': 'abc', 'user': {'id': 'u1'}};
      expect(ApiClient.unwrapEnvelope(body), same(body));
      expect(ApiClient.unwrapEnvelope('csv,text'), 'csv,text');
      expect(ApiClient.unwrapEnvelope(null), isNull);
    });
  });

  group('apiExceptionFrom', () {
    test('unwraps a DioException-wrapped domain error', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        error: const NetworkOfflineException(),
      );
      expect(apiExceptionFrom(dio), isA<NetworkOfflineException>());
      expect(
        apiExceptionFrom(const ValidationException(message: 'x')),
        isA<ValidationException>(),
      );
      expect(apiExceptionFrom(Exception('boom')), isNull);
    });
  });

  group('ApiClient.extractErrorMessage', () {
    test('reads nested backend error envelope', () {
      final body = {
        'success': false,
        'error': {'code': 'UNAUTHORIZED', 'message': 'PIN salah'},
      };
      expect(ApiClient.extractErrorMessage(body), 'PIN salah');
    });

    test('joins list messages and falls back to legacy shape', () {
      expect(
        ApiClient.extractErrorMessage({
          'error': {
            'message': ['name required', 'price invalid'],
          },
        }),
        'name required, price invalid',
      );
      expect(ApiClient.extractErrorMessage({'message': 'legacy'}), 'legacy');
      expect(ApiClient.extractErrorMessage(null), isNull);
    });
  });
}
