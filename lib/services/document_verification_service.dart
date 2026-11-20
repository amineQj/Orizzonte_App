import '../models/api_models.dart';
import 'api_service.dart';

/// One photo captured by the verification flow.
class CapturedDocument {
  final List<int> bytes;
  final String filename;

  const CapturedDocument({required this.bytes, required this.filename});
}

/// Outcome of the backend quality gate for a single document slot.
class DocumentVerificationResult {
  final String slot;
  final String decision; // ACCEPT | MANUAL_REVIEW | REJECT
  final String qualityStatus;
  final List<String> reasonCodes;

  const DocumentVerificationResult({
    required this.slot,
    required this.decision,
    required this.qualityStatus,
    this.reasonCodes = const [],
  });

  bool get passed => decision == 'ACCEPT' || decision == 'MANUAL_REVIEW';
  bool get rejected => decision == 'REJECT';

  @override
  String toString() =>
      '$slot: $decision (${reasonCodes.join(', ')}${qualityStatus.isNotEmpty ? ' — $qualityStatus' : ''})';
}

/// Real API pipeline used by every driver verification screen.
///
/// 1. `POST /api/drivers/me/documents/` stores the photo.
/// 2. `POST /api/verification/check/` queues the quality gate with the SAME
///    bytes (multipart fields `slot` + `file`).
/// 3. `GET /api/verification/status/<task_id>/` is polled every 2 seconds
///    until the backend returns a terminal `completed` / `failed` status.
class DocumentVerificationService {
  DocumentVerificationService({
    ApiService? api,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 90,
  }) : api = api ?? ApiService();

  final ApiService api;

  /// Poll cadence and cap. Injectable for tests; production uses 2s × 90.
  /// The first status check happens immediately; only retries wait.
  final Duration pollInterval;
  final int maxPolls;

  Future<DocumentVerificationResult> uploadAndVerify({
    required String slot,
    required CapturedDocument document,
    void Function(String phase)? onProgress,
  }) async {
    if (document.bytes.isEmpty) {
      throw const ApiException('The selected image is empty. Please retake it.');
    }

    onProgress?.call('uploading');
    await api.uploadDocument(slot, document.bytes, document.filename);

    onProgress?.call('checking');
    final taskId = await api.checkDocument(slot, document.bytes, document.filename);
    if (taskId.isEmpty) {
      throw const ApiException(
        'The verification service did not return a task id. Please retry.',
      );
    }

    for (var i = 0; i < maxPolls; i++) {
      if (i > 0 && pollInterval > Duration.zero) {
        await Future.delayed(pollInterval);
      }
      final status = await api.getVerificationStatus(taskId);
      final state = status['status']?.toString();

      if (state == 'completed') {
        final decision = status['final_decision']?.toString() ?? '';
        final reasons = (status['reason_codes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        onProgress?.call('done');
        return DocumentVerificationResult(
          slot: slot,
          decision: decision,
          qualityStatus: status['quality_status']?.toString() ?? '',
          reasonCodes: reasons,
        );
      }

      if (state == 'failed') {
        final message = status['detail']?.toString() ??
            status['code']?.toString() ??
            'Verification failed.';
        throw ApiException(message, code: status['code']?.toString());
      }

      onProgress?.call('waiting');
    }

    throw const ApiException(
      'Verification timed out. Please retry this document.',
    );
  }
}
