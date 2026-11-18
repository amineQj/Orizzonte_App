import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session.dart';

class PricingConfig {
  final int version;
  final bool calibrated;
  final Map<String, dynamic> parameters;

  const PricingConfig({
    required this.version,
    required this.calibrated,
    required this.parameters,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      version: (json['version'] as num?)?.toInt() ?? 0,
      calibrated: json['calibrated'] as bool? ?? false,
      parameters: (json['parameters'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
    );
  }
}

class PricingServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const PricingServiceException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

class PricingService {
  PricingService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = AuthSession.instance.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<PricingConfig> getPricingConfig() async {
    final response = await _client.get(
      _uri('/api/pricing/config/'),
      headers: _headers(),
    );
    final body = _decodeBody(response.body);
    if (response.statusCode == 200) {
      if (body is Map<String, dynamic>) {
        return PricingConfig.fromJson(body);
      }
      throw const PricingServiceException('Invalid response format');
    }
    throw _exceptionFromResponse(response.statusCode, body);
  }

  Future<PricingConfig> updatePricingConfig({
    required Map<String, dynamic> parameters,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/api/pricing/config/update/'),
      headers: _headers(),
      body: jsonEncode({
        'password': password,
        'parameters': parameters,
      }),
    );
    final body = _decodeBody(response.body);
    if (response.statusCode == 200) {
      if (body is Map<String, dynamic>) {
        return PricingConfig.fromJson(body);
      }
      throw const PricingServiceException('Invalid response format');
    }
    throw _exceptionFromResponse(response.statusCode, body);
  }

  dynamic _decodeBody(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  PricingServiceException _exceptionFromResponse(int status, dynamic body) {
    String? code;
    String message = 'Request failed ($status)';
    if (body is Map) {
      final m = body.cast<dynamic, dynamic>();
      if (m['code'] is String) code = m['code'] as String;
      if (m['detail'] is String) {
        message = m['detail'] as String;
      } else if (m['message'] is String) {
        message = m['message'] as String;
      } else if (m['error'] is String) {
        message = m['error'] as String;
      } else if (code == 'invalid_password') {
        message = 'Invalid password';
      }
    }
    if (status == 401) {
      message = message == 'Request failed (401)'
          ? 'Unauthorized. Please sign in again.'
          : message;
    } else if (status == 403 && code == 'invalid_password') {
      message = 'Invalid password';
    } else if (status == 400) {
      message = message == 'Request failed (400)'
          ? 'Validation error. Please check your inputs.'
          : message;
    }
    return PricingServiceException(message, statusCode: status, code: code);
  }

  void dispose() {
    _client.close();
  }
}
