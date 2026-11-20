import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orizzonte/models/api_models.dart';
import 'package:orizzonte/services/api_service.dart';
import 'package:orizzonte/services/auth_session.dart';

/// Returns a canned response and records the last requested URL.
class _RecordingClient extends http.BaseClient {
  final int statusCode;
  final Map<String, dynamic> body;
  final List<int>? rawBody;
  Uri? lastUrl;
  Map<String, String>? lastHeaders;

  _RecordingClient({required this.statusCode, required this.body, this.rawBody});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    lastHeaders = request.headers;
    final bytes = rawBody ?? utf8.encode(json.encode(body));
    return http.StreamedResponse(
      Stream.value(bytes),
      statusCode,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exact backend error messages', () {
    test('apiErrorMessage appends the backend machine code', () {
      final error = ApiException(
        'Your driver profile must be approved before accepting a mission.',
        statusCode: 403,
        code: 'driver_not_approved',
      );

      expect(
        apiErrorMessage(error),
        contains('driver_not_approved'),
      );
      expect(
        apiErrorMessage(error),
        contains('must be approved'),
      );
    });

    test('a 403 with a real backend detail is not replaced by a generic text',
        () async {
      final client = _RecordingClient(
        statusCode: 403,
        body: {
          'detail': 'Your driver profile must be approved.',
          'code': 'driver_not_approved',
        },
      );
      final api = ApiService(client: client);

      expect(
        () => api.acceptMission(7),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message',
                  'Your driver profile must be approved.')
              .having((e) => e.code, 'code', 'driver_not_approved'),
        ),
      );
    });

    test('a 409 conflict keeps the exact backend detail', () async {
      final client = _RecordingClient(
        statusCode: 409,
        body: {'detail': 'Mission already accepted by another driver.'},
      );
      final api = ApiService(client: client);

      expect(
        () => api.acceptMission(9),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Mission already accepted by another driver.',
          ),
        ),
      );
    });

    test('a 409 without a detail gets a user-friendly retry hint', () async {
      final client = _RecordingClient(statusCode: 409, body: {});
      final api = ApiService(client: client);

      expect(
        () => api.acceptMission(9),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('refresh and retry'),
          ),
        ),
      );
    });
  });

  group('Boss detail API paths', () {
    test('getMissionById reads the /api/missions/all/ list', () async {
      final client = _RecordingClient(
        statusCode: 200,
        body: {
          'results': [
            {
              'id': 1,
              'status': 'pending',
              'client': {'full_name': 'Alice', 'email': 'alice@example.com'},
            },
            {
              'id': 42,
              'status': 'accepted',
              'client': {'full_name': 'Bob', 'email': 'bob@example.com'},
              'assigned_employee': {'id': 5, 'full_name': 'Driver One'},
            },
          ],
        },
      );
      final api = ApiService(client: client);

      final mission = await api.getMissionById(42);

      expect(client.lastUrl.toString(), contains('/api/missions/all/'));
      expect(mission, isNotNull);
      expect(mission!.id, 42);
      expect(mission.client?['full_name'], 'Bob');
      expect(mission.assignedEmployee?['full_name'], 'Driver One');
    });

    test('getDocumentBytes uses the private document endpoint', () async {
      final client = _RecordingClient(
        statusCode: 200,
        body: {},
        rawBody: [1, 2, 3, 4],
      );
      final api = ApiService(client: client);

      final bytes = await api.getDocumentBytes(12, 'driving_license');

      expect(bytes, [1, 2, 3, 4]);
      expect(
        client.lastUrl.toString(),
        contains('/api/drivers/12/documents/driving_license/'),
      );
    });
  });

  group('Foundation configuration', () {
    test('debug base URL uses a local backend', () {
      expect(ApiConfig.baseUrl, anyOf(
        'http://10.0.2.2:8000',
        'http://127.0.0.1:8000',
      ));
    });

    test('auth endpoints never send a Bearer token', () async {
      SharedPreferences.setMockInitialValues({});
      await AuthSession.instance.setSession(
        token: 'stale-access-token',
        role: 'client',
        userId: '1',
      );
      addTearDown(() => AuthSession.instance.clear());

      final client = _RecordingClient(
        statusCode: 200,
        body: {'access': 'fresh-access-token'},
      );
      final api = ApiService(client: client);

      await api.refreshAccessToken('refresh-token');

      expect(client.lastHeaders?['Authorization'], isNull);
    });

    test('structured error keys are not treated as field errors', () async {
      final client = _RecordingClient(
        statusCode: 409,
        body: {
          'detail': 'Verification is required.',
          'code': 'verification_required',
          'slot': 'selfie',
          'reason_codes': ['BLURRY'],
        },
      );
      final api = ApiService(client: client);

      expect(
        () => api.submitDriverProfile(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'verification_required')
              .having((e) => e.fieldErrors, 'fieldErrors', isNull),
        ),
      );
    });
  });
}
