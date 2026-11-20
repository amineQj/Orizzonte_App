import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:orizzonte/models/api_models.dart';
import 'package:orizzonte/services/api_service.dart';
import 'package:orizzonte/services/document_verification_service.dart';

class _VerificationClient extends http.BaseClient {
  _VerificationClient(this.statuses);

  final List<Map<String, dynamic>> statuses;
  int statusCalls = 0;
  int uploadCalls = 0;
  int checkCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    if (path == '/api/drivers/me/documents/') {
      uploadCalls++;
      return _json({'user_id': 7, 'status': 'incomplete'});
    }
    if (path == '/api/verification/check/') {
      checkCalls++;
      return _json({'task_id': 'task-1'});
    }
    if (path.startsWith('/api/verification/status/')) {
      statusCalls++;
      final body = statuses.isEmpty
          ? {'task_id': 'task-1', 'status': 'pending'}
          : statuses.removeAt(0);
      return _json(body);
    }
    return _json({'detail': 'Unexpected path: $path'}, statusCode: 404);
  }

  http.StreamedResponse _json(Map<String, dynamic> body, {int statusCode = 200}) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(json.encode(body))),
      statusCode,
      headers: const {'content-type': 'application/json'},
      request: null,
    );
  }
}

void main() {
  const document = CapturedDocument(
    bytes: [1, 2, 3],
    filename: 'id.jpg',
  );

  group('DocumentVerificationService terminal states', () {
    test('failed task body from HTTP 200 surfaces the backend detail (M5)',
        () async {
      final client = _VerificationClient([
        {
          'task_id': 'task-1',
          'status': 'failed',
          'detail': 'OCR engine unavailable',
          'code': 'verification_processing_failed',
        },
      ]);
      final service = DocumentVerificationService(
        api: ApiService(client: client, baseUrl: 'http://test'),
        pollInterval: Duration.zero,
        maxPolls: 3,
      );

      await expectLater(
        service.uploadAndVerify(slot: 'selfie', document: document),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('OCR engine unavailable'),
        )),
      );
      expect(client.uploadCalls, 1);
      expect(client.checkCalls, 1);
      expect(client.statusCalls, 1);
    });

    test('REJECT is returned, not treated as a passing upload (C5)', () async {
      final client = _VerificationClient([
        {
          'task_id': 'task-1',
          'status': 'completed',
          'final_decision': 'REJECT',
          'quality_status': 'BLURRY',
          'reason_codes': ['glare', 'crop'],
        },
      ]);
      final service = DocumentVerificationService(
        api: ApiService(client: client, baseUrl: 'http://test'),
        pollInterval: Duration.zero,
        maxPolls: 3,
      );

      final result = await service.uploadAndVerify(
        slot: 'id_card_front',
        document: document,
      );
      expect(result.rejected, isTrue);
      expect(result.passed, isFalse);
      expect(result.reasonCodes, ['glare', 'crop']);
      expect(client.statusCalls, 1);
    });
  });
}
