import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import 'auth_session.dart';

/// Central HTTP client for the ORIZZONTE backend.
///
/// All requests carry the JWT from [AuthSession] when available. Errors are
/// normalized into [ApiException]. A single 401 retry is attempted through
/// [onUnauthorized] (wired by AuthService) so expired access tokens refresh
/// transparently.
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  /// Set by AuthService: return true when a fresh access token was obtained.
  static Future<bool> Function()? onUnauthorized;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = AuthSession.instance.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  dynamic _decode(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  ApiException _fromResponse(http.Response r) {
    final body = _decode(r.body);
    var message = 'Request failed (${r.statusCode})';
    String? code;
    Map<String, dynamic>? fieldErrors;

    if (body is Map) {
      final m = body.cast<dynamic, dynamic>();
      if (m['code'] is String) code = m['code'] as String;
      if (m['detail'] is String && (m['detail'] as String).isNotEmpty) {
        message = m['detail'] as String;
      } else if (m['message'] is String && (m['message'] as String).isNotEmpty) {
        message = m['message'] as String;
      }
      final fe = <String, dynamic>{};
      for (final entry in m.entries) {
        final k = entry.key.toString();
        if (k == 'detail' || k == 'code' || k == 'message' ||
            k == 'task_id' || k == 'status') {
          continue;
        }
        fe[k] = entry.value;
      }
      if (fe.isNotEmpty) fieldErrors = fe;
    }

    if (r.statusCode == 401 && code == null) {
      message = 'Unauthorized. Please sign in again.';
    } else if (r.statusCode == 403 && code == null) {
      message = 'You do not have permission to do that.';
    } else if (r.statusCode == 429) {
      message = 'Too many requests. Please wait a moment and retry.';
    } else if (r.statusCode >= 500) {
      message = 'Server error (${r.statusCode}). Please try again later.';
    }

    return ApiException(message,
        statusCode: r.statusCode, code: code, fieldErrors: fieldErrors);
  }

  Future<T> _sendRequest<T>(
    Future<T> Function() request, {
    bool retryOn401 = true,
  }) async {
    T response = await request();
    final status = switch (response) {
      http.Response(:final statusCode) => statusCode,
      http.StreamedResponse(:final statusCode) => statusCode,
      _ => 0,
    };
    if (status == 401 && retryOn401) {
      final refresh = onUnauthorized;
      if (refresh != null && await refresh()) {
        response = await request();
      }
    }
    return response;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool retryOn401 = true,
  }) =>
      _sendRequest(request, retryOn401: retryOn401);

  T _ok<T>(http.Response r, T Function(dynamic body) parse) {
    final body = _decode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return parse(body);
    }
    throw _fromResponse(r);
  }

  Future<T> _get<T>(String path, T Function(dynamic) parse) async {
    final r = await _send(() => _client.get(_uri(path), headers: _headers(json: false)));
    return _ok(r, parse);
  }

  Future<T> _post<T>(String path, Map<String, dynamic> body,
      T Function(dynamic) parse) async {
    final payload = jsonEncode(body);
    final r = await _send(() =>
        _client.post(_uri(path), headers: _headers(), body: payload));
    return _ok(r, parse);
  }

  Future<T> _patch<T>(String path, Map<String, dynamic> body,
      T Function(dynamic) parse) async {
    final payload = jsonEncode(body);
    final r = await _send(() =>
        _client.patch(_uri(path), headers: _headers(), body: payload));
    return _ok(r, parse);
  }

  Future<void> _void(Future<http.Response> Function() request) async {
    final r = await _send(request);
    _ok(r, (_) => null);
  }

  Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map) return body.cast<String, dynamic>();
    throw const ApiException('Unexpected response from server.');
  }

  List<dynamic> _asList(dynamic body) {
    if (body is List) return body;
    if (body is Map && body['results'] is List) {
      return (body['results'] as List);
    }
    return const [];
  }

  // ------------------------------------------------------------------
  // Auth  (/api/signup/, /api/token/, /api/token/refresh/, /api/logout/)
  // ------------------------------------------------------------------
  Future<AuthResponse> login(String email, String password) async {
    final r = await _client.post(
      _uri('/api/token/'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _ok(r, (b) => AuthResponse.fromJson(_asMap(b)));
  }

  Future<AuthResponse> signup(String email, String password, String role) async {
    final r = await _client.post(
      _uri('/api/signup/'),
      headers: _headers(),
      body: jsonEncode({
        'username': email.split('@').first,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    // Signup returns {"message", "user"} — no tokens; caller logs in next.
    return _ok(r, (b) {
      final m = _asMap(b);
      final user = m['user'] is Map
          ? ApiUser.fromJson((m['user'] as Map).cast<String, dynamic>())
          : ApiUser(id: 0, username: '', email: email, role: role);
      return AuthResponse(user: user, accessToken: '', refreshToken: '');
    });
  }

  Future<Map<String, dynamic>> refreshAccessToken(String refresh) async {
    final r = await _client.post(
      _uri('/api/token/refresh/'),
      headers: _headers(),
      body: jsonEncode({'refresh': refresh}),
    );
    return _ok(r, _asMap);
  }

  Future<void> logout(String refreshToken) async {
    await _void(() => _client.post(
          _uri('/api/logout/'),
          headers: _headers(),
          body: jsonEncode({'refresh': refreshToken}),
        ));
  }

  Future<Map<String, dynamic>> getMe() async {
    return _get('/api/users/me/', _asMap);
  }

  Future<void> resendVerification(String email) async {
    await _post('/api/resend-verification/', {'email': email}, (_) => null);
  }

  Future<void> verifyEmail(String uid, String token) async {
    final query = Uri(queryParameters: {'uid': uid, 'token': token}).query;
    await _get('/api/verify-email/?$query', (_) => null);
  }

  // ------------------------------------------------------------------
  // Driver profile & documents
  // ------------------------------------------------------------------
  Future<DriverProfile> getDriverProfile() async {
    return _get('/api/drivers/me/profile/',
        (b) => DriverProfile.fromJson(_asMap(b)));
  }

  Future<DriverProfile> updateDriverProfile(Map<String, dynamic> data) async {
    const allowed = {
      'full_name', 'phone', 'date_of_birth', 'national_id_number',
      'driving_license_number', 'driving_license_expiry', 'vehicle_plate',
    };
    final payload = <String, dynamic>{
      for (final entry in data.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
    return _patch('/api/drivers/me/profile/', payload,
        (b) => DriverProfile.fromJson(_asMap(b)));
  }

  Future<DriverProfile> submitDriverProfile() async {
    return _post('/api/drivers/me/submit/', {},
        (b) => DriverProfile.fromJson(_asMap(b)));
  }

  /// Backwards-compatible alias.
  Future<DriverProfile> submitProfile() => submitDriverProfile();

  static const Duration _uploadTimeout = Duration(seconds: 30);

  /// multipart/form-data uploads must never declare `Content-Type:
  /// application/json` — [http.MultipartRequest] adds the correct boundary
  /// itself. [_headers(json: false)] already only sends Accept + Authorization.
  ///
  /// On Flutter Web `MultipartFile.fromBytes` REQUIRES a non-empty filename;
  /// `XFile.name` can be empty or extension-less for camera/blob picks, so a
  /// safe fallback is always provided.
  String _uploadFilename(String type, String original) {
    final cleaned = original.trim().replaceAll(RegExp(r'[^\w.\-]'), '_');
    final dot = cleaned.lastIndexOf('.');
    if (dot > 0 && dot < cleaned.length - 1) return cleaned;
    final safeType = type.replaceAll(RegExp(r'[^\w\-]'), '_');
    return '${safeType.isEmpty ? 'document' : safeType}.jpg';
  }

  Future<http.Response> _sendMultipart({
    required String path,
    required Map<String, String> fields,
    required String type,
    required List<int> fileBytes,
    required String originalFilename,
  }) async {
    if (fileBytes.isEmpty) {
      throw const ApiException('The selected file is empty. Please choose another image.');
    }
    final filename = _uploadFilename(type, originalFilename);

    // Rebuild the request on every attempt so a 401 refresh supplies the new
    // token instead of replaying stale headers.
    Future<http.StreamedResponse> send() {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(
          'file', // backend field name: DocumentUploadSerializer.file
          fileBytes,
          filename: filename,
        ));
      return _client.send(request).timeout(_uploadTimeout);
    }

    try {
      final streamed = await _sendRequest(send);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 400) {
        // Makes the exact backend validation error visible instead of failing
        // silently behind a generic UI message.
        debugPrint('[ApiService] POST $path failed '
            '(${response.statusCode}): ${response.body}');
      }
      return response;
    } on TimeoutException {
      throw const ApiException(
        'Upload timed out. Check your connection and try again.',
      );
    }
  }

  Future<DriverProfile> uploadDocument(
      String type, List<int> fileBytes, String filename) async {
    final response = await _sendMultipart(
      path: '/api/drivers/me/documents/',
      fields: {'type': type},
      type: type,
      fileBytes: fileBytes,
      originalFilename: filename,
    );
    return _ok(response, (b) => DriverProfile.fromJson(_asMap(b)));
  }

  /// Downloads a document (JWT protected) as raw bytes.
  Future<List<int>> getDocumentBytes(int driverId, String type) async {
    final r = await _send(() => _client.get(
          _uri('/api/drivers/$driverId/documents/$type/'),
          headers: _headers(json: false),
        ));
    if (r.statusCode >= 200 && r.statusCode < 300) return r.bodyBytes;
    throw _fromResponse(r);
  }

  // ------------------------------------------------------------------
  // Verification (async)
  // ------------------------------------------------------------------
  Future<String> checkDocument(
      String slot, List<int> fileBytes, String filename) async {
    final response = await _sendMultipart(
      path: '/api/verification/check/',
      fields: {'slot': slot},
      type: slot,
      fileBytes: fileBytes,
      originalFilename: filename,
    );
    return _ok(response, (b) => _asMap(b)['task_id']?.toString() ?? '');
  }

  Future<Map<String, dynamic>> getVerificationStatus(String taskId) async {
    return _get('/api/verification/status/$taskId/', _asMap);
  }

  // ------------------------------------------------------------------
  // Missions — client
  // ------------------------------------------------------------------
  Future<EstimateResult> estimateMission(Map<String, dynamic> body) async {
    return _post('/api/missions/estimate/', body,
        (b) => EstimateResult.fromJson(_asMap(b)));
  }

  /// Backwards-compatible alias.
  Future<EstimateResult> estimatePrice(Map<String, dynamic> body) =>
      estimateMission(body);

  Future<Mission> confirmMission(Map<String, dynamic> body) async {
    return _post('/api/missions/confirm/', body,
        (b) => Mission.fromJson(_asMap(b)));
  }

  // ------------------------------------------------------------------
  // Missions — client
  // ------------------------------------------------------------------
  /// Missions created by the signed-in client (paginated responses are
  /// unwrapped by [_asList]).
  Future<List<Mission>> getClientMissions() async {
    return _get('/api/missions/client/my/',
        (b) => _asList(b).map((e) => Mission.fromJson(_asMap(e))).toList());
  }

  // ------------------------------------------------------------------
  // Missions — driver
  // ------------------------------------------------------------------
  Future<List<Mission>> getAvailableMissions() async {
    return _get('/api/missions/available/',
        (b) => _asList(b).map((e) => Mission.fromJson(_asMap(e))).toList());
  }

  Future<List<Mission>> getMyMissions() async {
    return _get('/api/missions/my/',
        (b) => _asList(b).map((e) => Mission.fromJson(_asMap(e))).toList());
  }

  Future<Mission> acceptMission(int id) async {
    return _post('/api/missions/$id/accept/', {},
        (b) => Mission.fromJson(_asMap(b)));
  }

  Future<Mission> startMission(int id) async {
    return _post('/api/missions/$id/start/', {},
        (b) => Mission.fromJson(_asMap(b)));
  }

  Future<Mission> completeMission(int id) async {
    return _post('/api/missions/$id/complete/', {},
        (b) => Mission.fromJson(_asMap(b)));
  }

  // ------------------------------------------------------------------
  // Missions — boss
  // ------------------------------------------------------------------
  Future<List<Mission>> getAllMissions() async {
    return _get('/api/missions/all/',
        (b) => _asList(b).map((e) => Mission.fromJson(_asMap(e))).toList());
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    return _get('/api/missions/dashboard/', _asMap);
  }

  /// Backwards-compatible alias.
  Future<Map<String, dynamic>> getDashboard() => getDashboardStats();

  Future<Mission> assignMission(int missionId, int employeeId) async {
    return _post('/api/missions/$missionId/assign/',
        {'employee_id': employeeId}, (b) => Mission.fromJson(_asMap(b)));
  }

  Future<Mission> cancelMission(int missionId) async {
    return _post('/api/missions/$missionId/cancel/', {},
        (b) => Mission.fromJson(_asMap(b)));
  }

  Future<void> deleteMission(int missionId) async {
    await _void(() =>
        _client.delete(_uri('/api/missions/$missionId/delete/'), headers: _headers()));
  }

  // ------------------------------------------------------------------
  // Negotiation
  // ------------------------------------------------------------------
  Future<Negotiation> getNegotiation(int missionId) async {
    return _get('/api/missions/$missionId/negotiation/',
        (b) => Negotiation.fromJson(_asMap(b)));
  }

  static final Random _random = Random();

  /// Generates a stable idempotency key when the caller doesn't supply one.
  static String newIdempotencyKey() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';

  Future<Negotiation> makeOffer(
    int missionId,
    int amount, {
    String? idempotencyKey,
  }) async {
    final key = (idempotencyKey == null || idempotencyKey.isEmpty)
        ? newIdempotencyKey()
        : idempotencyKey;
    return _post(
      '/api/missions/$missionId/negotiation/offer/',
      {'amount': amount, 'idempotency_key': key},
      (b) => Negotiation.fromJson(_asMap(b)),
    );
  }

  Future<Map<String, dynamic>> acceptNegotiation(int missionId) async {
    return _post('/api/missions/$missionId/negotiation/accept/', {},
        _asMap);
  }

  Future<Negotiation> declineNegotiation(int missionId) async {
    return _post('/api/missions/$missionId/negotiation/decline/', {},
        (b) => Negotiation.fromJson(_asMap(b)));
  }

  // ------------------------------------------------------------------
  // Boss drivers
  // ------------------------------------------------------------------
  Future<List<PendingDriver>> getPendingDrivers() async {
    return _get('/api/drivers/pending/',
        (b) => _asList(b).map((e) => PendingDriver.fromJson(_asMap(e))).toList());
  }

  Future<void> approveDriver(int driverId) async {
    await _post('/api/drivers/$driverId/approve/', {}, (_) => null);
  }

  Future<void> rejectDriver(int driverId, String reason) async {
    await _post('/api/drivers/$driverId/reject/', {'reason': reason}, (_) => null);
  }

  // ------------------------------------------------------------------
  // Pricing config
  // ------------------------------------------------------------------
  Future<PricingConfig> getPricingConfig() async {
    return _get('/api/pricing/config/', (b) => PricingConfig.fromJson(_asMap(b)));
  }

  Future<PricingConfig> updatePricingConfig(
      Map<String, dynamic> parameters, String password) async {
    return _post('/api/pricing/config/update/',
        {'password': password, 'parameters': parameters},
        (b) => PricingConfig.fromJson(_asMap(b)));
  }

  Future<Map<String, dynamic>> getPricingRules() async {
    return _get('/api/pricing/rules/', _asMap);
  }

  void dispose() => _client.close();
}
