import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:orizzonte/models/api_models.dart';
import 'package:orizzonte/services/api_service.dart';

/// Captures multipart requests without a network connection.
class _RecordingClient extends http.BaseClient {
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(json.encode({'task_id': 'task-1'}))),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  group('ApiService multipart uploads', () {
    test('sends a non-empty filename and the backend field name "file"', () async {
      final recording = _RecordingClient();
      final api = ApiService(client: recording);

      await api.checkDocument('id_front', [1, 2, 3], 'front.jpg');

      final request = recording.request as http.MultipartRequest;
      expect(request.fields['slot'], 'id_front');
      expect(request.files, hasLength(1));
      expect(request.files.single.field, 'file');
      expect(request.files.single.filename, 'front.jpg');
      expect(request.headers['Content-Type'], isNot('application/json'));
    });

    test('falls back to a .jpg filename when XFile.name is empty', () async {
      final recording = _RecordingClient();
      final api = ApiService(client: recording);

      await api.checkDocument('selfie', [1, 2, 3], '');

      final request = recording.request as http.MultipartRequest;
      expect(request.files.single.filename, 'selfie.jpg');
      expect(request.files.single.filename, isNotEmpty);
    });

    test('rejects empty files before sending', () async {
      final recording = _RecordingClient();
      final api = ApiService(client: recording);

      expect(
        () => api.checkDocument('id_front', const [], 'front.jpg'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('empty'),
        )),
      );
      expect(recording.request, isNull);
    });
  });
}
