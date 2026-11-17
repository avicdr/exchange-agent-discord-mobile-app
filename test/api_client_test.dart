import 'dart:convert';

import 'package:exchange_sentinel/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('providerStatus uses the existing authenticated provider API', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://backend.test/api/v1/provider/status');
      expect(request.headers['Authorization'], 'Bearer owner-token');
      return http.Response(
        jsonEncode({
          'status': 'SIMULATED',
          'reason': 'Safe local provider',
          'is_live': false,
          'is_simulated': true,
          'is_blocked': false,
        }),
        200,
      );
    });
    final api = ApiClient(baseUrl: 'http://backend.test/', token: 'owner-token', client: client);

    final provider = await api.providerStatus();

    expect(provider.status, 'SIMULATED');
    expect(provider.reason, 'Safe local provider');
    expect(provider.isSimulated, isTrue);
  });

  test('non-JSON API failures still report the HTTP status', () async {
    final client = MockClient((_) async => http.Response('Bad gateway', 502));
    final api = ApiClient(baseUrl: 'http://backend.test', token: 'owner-token', client: client);

    expect(
      api.health(),
      throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 502)),
    );
  });
}
