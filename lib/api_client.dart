import 'dart:convert';

import 'package:exchange_sentinel/models.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.token, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Uri uri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanBase = baseUrl.replaceFirst(RegExp(r'/$'), '');
    final parsed = Uri.parse('$cleanBase$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return parsed.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())));
    }
    return parsed;
  }

  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _request(String method, String path, [Map<String, dynamic>? body, Map<String, dynamic>? query]) async {
    final request = http.Request(method, uri(path, query))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await _client.send(request).timeout(const Duration(seconds: 15)));
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } on FormatException {
      decoded = <String, dynamic>{};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map<String, dynamic> ? decoded['detail']?.toString() : null;
      throw ApiException(detail ?? 'Request failed (${response.statusCode})', response.statusCode);
    }
    return decoded;
  }

  Future<Overview> overview() async =>
      Overview.fromJson(await _request('GET', '/api/v1/overview') as Map<String, dynamic>);

  Future<ProviderInfo> providerStatus() async =>
      ProviderInfo.fromJson(await _request('GET', '/api/v1/provider/status') as Map<String, dynamic>);

  Future<List<Deal>> deals({String? status, int limit = 200}) async {
    final query = <String, dynamic>{'limit': limit};
    if (status != null) query['status'] = status;
    final list = await _request('GET', '/api/v1/deals', null, query) as List;
    return list.map((item) => Deal.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AlertEvent>> notifications({bool pending = true}) async {
    final list = await _request('GET', '/api/v1/notifications', null, {'pending': pending}) as List;
    return list.map((item) => AlertEvent.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> acknowledge(String id) async => _request('POST', '/api/v1/notifications/$id/acknowledge');

  Future<void> dismiss(String id) async => _request('POST', '/api/v1/notifications/$id/dismiss');

  Future<Map<String, dynamic>> control(String action) async =>
      await _request('POST', '/api/v1/agent/$action') as Map<String, dynamic>;

  Future<Map<String, dynamic>> health() async =>
      await _request('GET', '/health') as Map<String, dynamic>;

  Future<Deal> action(
    String dealId,
    String action,
    String idempotencyKey, {
    String? reference,
    String? note,
    String? destination,
    bool verified = false,
  }) async {
    final result = await _request('POST', '/api/v1/deals/$dealId/actions', {
      'action': action,
      'idempotency_key': idempotencyKey,
      'manual_verification_confirmed': verified,
      if (reference != null) 'payment_reference': reference,
      if (note != null) 'note': note,
      if (destination != null) 'settlement_destination': destination,
    });
    return Deal.fromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> exportTranscript(String dealId) async =>
      await _request('POST', '/api/v1/deals/$dealId/export') as Map<String, dynamic>;

  void close() => _client.close();
}
