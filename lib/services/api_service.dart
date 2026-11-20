import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import 'auth_session.dart';

/// Platform-aware backend base URL.
///
/// Set `API_BASE_URL` with `--dart-define` to override the development default.
/// Release builds must use HTTPS and fail fast otherwise.
class ApiConfig {
  const ApiConfig._();

  static const String _dartDefine = String.fromEnvironment('API_BASE_URL');

  static String get platformDefault {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get baseUrl {
    final raw = _dartDefine.trim().isEmpty ? platformDefault : _dartDefine.trim();
    final normalized = raw.replaceAll(RegExp(r'/+$'), '');
    if (kReleaseMode) {
      final uri = Uri.tryParse(normalized);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw StateError(
          'API_BASE_URL must be an https:// URL in release builds. '
          'Pass --dart-define=API_BASE_URL=https://your-backend.example.com',
        );
      }
    }
    return normalized;
  }

  static String get defaultBaseUrl => baseUrl;

  /// Fail fast during startup instead of on the first network call.
  static void validate() => baseUrl;
}

/// Central HTTP client for the ORIZZONTE backend.
///
/// Authenticated requests carry the JWT from [AuthSession]; auth endpoints
/// deliberately do not. Errors are normalized into [ApiException]. A single
/// 401 retry is attempted through [onUnauthorized] (wired once by
/// [AuthService.instance]) so expired access tokens refresh transparently.
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static String get defaultBaseUrl => ApiConfig.baseUrl;

  /// Set by AuthService: return true when a fresh access token was obtained.
  static Future<bool> Function()? onUnauthorized;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers({bool json = true, bool auth = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = AuthSession.instance.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Token, refresh, signup and logout endpoints must never send a stale
  /// Bearer token; the backend authenticates them by body/credentials.
  Map<String, String> _authHeaders({bool json = true}) =>
      _headers(json: json, auth: false);

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
      // Only DRF-style field validation keys belong in `fieldErrors`.
      // Structured payloads such as `missing`, `slot` and `reason_codes`
      // carry their own meaning and must not be misread as field errors.
      const nonFieldKeys = {
        'detail', 'code', 'message', 'task_id', 'status',
        'missing', 'slot', 'reason_codes', 'count', 'next', 'previous',
        'results',
      };
      final fe = <String, dynamic>{};
      for (final entry in m.entries) {
        final k = entry.key.toString();
        if (nonFieldKeys.contains(k)) continue;
        fe[k] = entry.value;
      }
      if (fe.isNotEmpty) fieldErrors = fe;
    }

    // Preserve the backend's exact error text whenever it supplied one.
    // Only fall back to a generic sentence when the body had no usable detail.
    final bool hasBackendDetail = message != 'Request failed (${r.statusCode})';
    if (!hasBackendDetail) {
      switch (r.statusCode) {
        case 401:
          message = 'Unauthorized. Please sign in again.';
          break;
        case 403:
          message = 'You do not have permission to do that.';
          break;
        case 404:
          message = 'Not found. Please refresh and retry.';
          break;
        case 409:
          message = 'This action conflicts with the current state. Please refresh and retry.';
          break;
        case 429:
          message = 'Too many requests. Please wait a moment and retry.';
          break;
        default:
          if (r.statusCode >= 500) {
            message = 'Server error (${r.statusCode}). Please try again later.';
          }
          break;
      }
    } else if (r.statusCode >= 500) {
      message = 'Server error (${r.statusCode}). $message';
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

  Future<void> _delete(String path) async {
    final r = await _send(() =>
        _client.delete(_uri(path), headers: _headers(json: false)));
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

  /// Follow DRF `next` links so every page of a paginated list is returned,
  /// not just the first 50 rows (D13, M1).
  Future<List<T>> _getPaginatedList<T>(
    String initialPath,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final items = <T>[];
    String? next = initialPath;
    while (next != null && next.isNotEmpty) {
      final r = await _send(
        () => _client.get(_requestUri(next!), headers: _headers(json: false)),
      );
      final body = _decode(r.body);
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw _fromResponse(r);
      }
      final page = _asList(body);
      items.addAll(page.map((e) => fromJson(_asMap(e))));
      if (body is Map && body['next'] != null) {
        next = body['next'].toString();
      } else {
        next = null;
      }
    }
    return items;
  }

  Uri _requestUri(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.parse(value);
    }
    return _uri(value);
  }

  // ------------------------------------------------------------------
  // Auth  (/api/signup/, /api/token/, /api/token/refresh/, /api/logout/)
  // ------------------------------------------------------------------
  Future<AuthResponse> login(String email, String password) async {
    final r = await _client.post(
      _uri('/api/token/'),
      headers: _authHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _ok(r, (b) => AuthResponse.fromJson(_asMap(b)));
  }

  Future<AuthResponse> signup(String email, String password, String role) async {
    final r = await _client.post(
      _uri('/api/signup/'),
      headers: _authHeaders(),
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
      headers: _authHeaders(),
      body: jsonEncode({'refresh': refresh}),
    );
    return _ok(r, _asMap);
  }

  Future<void> logout(String refreshToken) async {
    await _void(() => _client.post(
          _uri('/api/logout/'),
          headers: _authHeaders(),
          body: jsonEncode({'refresh': refreshToken}),
        ));
  }

  Future<Map<String, dynamic>> getMe() async {
    return _get('/api/users/me/', _asMap);
  }

  Future<void> resendVerification(String email) async {
    final r = await _client.post(
      _uri('/api/resend-verification/'),
      headers: _authHeaders(),
      body: jsonEncode({'email': email}),
    );
    _ok(r, (_) => null);
  }

  Future<void> verifyEmail(String uid, String token) async {
    final query = Uri(queryParameters: {'uid': uid, 'token': token}).query;
    final r = await _client.get(
      _uri('/api/verify-email/?$query'),
      headers: _authHeaders(json: false),
    );
    _ok(r, (_) => null);
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
      // `_ok()` below normalizes failures and preserves the backend detail;
      // logging the raw body here would leak document metadata to logs.
      return await http.Response.fromStream(streamed);
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
    return _getPaginatedList('/api/missions/client/my/',
        (e) => Mission.fromJson(e));
  }

  // ------------------------------------------------------------------
  // Missions — driver
  // ------------------------------------------------------------------
  Future<List<Mission>> getAvailableMissions() async {
    return _getPaginatedList('/api/missions/available/',
        (e) => Mission.fromJson(e));
  }

  Future<List<Mission>> getMyMissions() async {
    return _getPaginatedList('/api/missions/my/',
        (e) => Mission.fromJson(e));
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
    return _getPaginatedList('/api/missions/all/',
        (e) => Mission.fromJson(e));
  }

  /// The backend has no `GET /api/missions/<id>/` detail route, so a boss
  /// mission detail is resolved from the authoritative `/api/missions/all/`
  /// list. This keeps the screen live without adding a backend endpoint.
  Future<Mission?> getMissionById(int missionId) async {
    final missions = await getAllMissions();
    for (final m in missions) {
      if (m.id == missionId) return m;
    }
    return null;
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
    return _getPaginatedList('/api/drivers/pending/',
        (e) => PendingDriver.fromJson(e));
  }

  // ------------------------------------------------------------------
  // Boss — registered drivers (accounts employees)
  // ------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getEmployees() async {
    return _getPaginatedList('/api/users/employees/', (e) => e);
  }

  Future<Map<String, dynamic>> getEmployeeDetail(int id) async {
    return _get('/api/users/employees/$id/', _asMap);
  }

  Future<void> deleteEmployee(int id) async {
    await _delete('/api/users/employees/$id/');
  }

  // ------------------------------------------------------------------
  // Boss — driver detail + mission history
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> getBossDriverDetail(int id) async {
    return _get('/api/drivers/$id/', _asMap);
  }

  Future<List<Mission>> getDriverMissionHistory(int driverId) async {
    return _getPaginatedList('/api/missions/employee/$driverId/',
        (e) => Mission.fromJson(e));
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
