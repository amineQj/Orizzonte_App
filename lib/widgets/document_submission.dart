import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/document_verification_service.dart';
import 'api_state.dart';
import 'app_text_style.dart';

const _amber = Color(0xFFF5A524);

/// Uploads, verifies and reports one or more captured driver documents.
///
/// Returns `true` only when every document reached ACCEPT / MANUAL_REVIEW.
/// On REJECT the dialog explains the reason codes and leaves the user on the
/// capture screen so they can retake the photo; the document is never treated
/// as valid in that case.
Future<bool> submitCapturedDocuments({
  required BuildContext context,
  required Map<String, CapturedDocument> documents,
  required void Function(String phase) onProgress,
  ApiService? api,
}) async {
  final service = DocumentVerificationService(api: api);
  final results = <DocumentVerificationResult>[];

  for (final entry in documents.entries) {
    final slot = entry.key;
    try {
      final result = await service.uploadAndVerify(
        slot: slot,
        document: entry.value,
        onProgress: (phase) => onProgress('$slot: $phase'),
      );
      results.add(result);
    } catch (e) {
      results.add(DocumentVerificationResult(
        slot: slot,
        decision: 'ERROR',
        qualityStatus: apiErrorMessage(e),
      ));
    }
  }

  if (!context.mounted) return false;

  final failed = results.where((r) => !r.passed).toList();
  final title = failed.isEmpty
      ? 'Verification complete'
      : 'Document needs attention';
  final description = failed.isEmpty
      ? 'Your documents passed the quality check.'
      : 'Retake the rejected document(s) and try again.';

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            failed.isEmpty ? Icons.check_circle : Icons.error_outline,
            color: failed.isEmpty ? const Color(0xFF4CAF50) : const Color(0xFFE0533D),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: appPop(size: 16, weight: FontWeight.w700,
                  color: const Color(0xFF111111)),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: appPop(size: 12, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 14),
            ...results.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r.passed
                          ? const Color(0xFFF1F9F2)
                          : const Color(0xFFFFF1EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: r.passed
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                            : const Color(0xFFE0533D).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_slotLabel(r.slot)} — ${_decisionLabel(r.decision)}',
                          style: appPop(
                            size: 13,
                            weight: FontWeight.w700,
                            color: r.passed
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC0392B),
                          ),
                        ),
                        if (r.reasonCodes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Reasons: ${r.reasonCodes.join(', ')}',
                              style: appPop(
                                  size: 11, color: const Color(0xFF666666)),
                            ),
                          ),
                        if (!r.passed && r.qualityStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              r.qualityStatus,
                              style: appPop(
                                  size: 11, color: const Color(0xFF999999)),
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            failed.isEmpty ? 'Done' : 'Retake',
            style: appPop(
                size: 13, weight: FontWeight.w700, color: _amber),
          ),
        ),
      ],
    ),
  );

  if (!context.mounted) return false;
  if (failed.isNotEmpty) {
    showApiError(context, 'Verification failed for: ${failed.map((r) => _slotLabel(r.slot)).join(', ')}');
  }
  return failed.isEmpty;
}

String _slotLabel(String slot) {
  switch (slot) {
    case 'selfie':
      return 'Selfie';
    case 'id_card_front':
      return 'ID card (front)';
    case 'id_card_back':
      return 'ID card (back)';
    case 'driving_license':
      return 'Driving license';
    case 'vehicle_registration':
      return 'Vehicle registration';
    default:
      return slot;
  }
}

String _decisionLabel(String decision) {
  switch (decision) {
    case 'ACCEPT':
      return 'ACCEPTED';
    case 'MANUAL_REVIEW':
      return 'MANUAL REVIEW';
    case 'REJECT':
      return 'REJECTED — please retake';
    default:
      return decision;
  }
}
