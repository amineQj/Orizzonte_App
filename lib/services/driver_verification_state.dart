/// Persisted document-verification decisions for the driver profile screen.
///
/// The backend stores one decision per document slot together with the
/// `documents_version` it was produced for. Re-reading the profile must
/// therefore restore those decisions, and a decision for an older version
/// must never be treated as passing.
class DriverVerificationDecision {
  final String slot;
  final String phase; // done | failed
  final String decision; // ACCEPT | MANUAL_REVIEW | REJECT | ''
  final String reasons;
  final String message;
  final int documentsVersion;

  const DriverVerificationDecision({
    required this.slot,
    required this.phase,
    this.decision = '',
    this.reasons = '',
    this.message = '',
    this.documentsVersion = -1,
  });

  factory DriverVerificationDecision.fromBackend(
    String slot,
    Map<String, dynamic> json,
  ) {
    final decision = (json['final_decision']?.toString() ?? '').toUpperCase();
    final reasons = (json['reason_codes'] as List?)
            ?.map((e) => e.toString())
            .join(', ') ??
        '';
    return DriverVerificationDecision(
      slot: slot,
      phase: decision.isEmpty ? 'failed' : 'done',
      decision: decision,
      reasons: reasons,
      message: (json['quality_status']?.toString() ?? ''),
      documentsVersion: _readInt(json['documents_version']),
    );
  }

  bool passedFor(int version) =>
      phase == 'done' &&
      (decision == 'ACCEPT' || decision == 'MANUAL_REVIEW') &&
      documentsVersion == version;

  bool get rejected => phase == 'done' && decision == 'REJECT';
  bool get failed => phase == 'failed';
}

/// Returns the stored decision for [slot] only when it belongs to the
/// profile's current [documentsVersion].
DriverVerificationDecision? readPersistedDecision(
  Map<String, dynamic> results,
  String slot,
  int documentsVersion,
) {
  final entry = results[slot];
  if (entry is! Map) return null;
  final map = entry.cast<String, dynamic>();
  final decision = DriverVerificationDecision.fromBackend(slot, map);
  return decision.documentsVersion == documentsVersion ? decision : null;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? -1;
}
