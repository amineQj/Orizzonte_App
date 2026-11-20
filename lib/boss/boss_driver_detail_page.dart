import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_language.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/api_state.dart';
import '../widgets/app_text_style.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height}) =>
    appPop(size: size, weight: weight, color: color, height: height);

const _amber = Color(0xFFF5A524);

/// The five document slots enforced by the backend's DOCUMENT_TYPES.
const _documentSlots = [
  ('selfie', 'Selfie', 'سيلفي', 'Selfie'),
  ('id_card_front', 'ID card front', 'بطاقة الهوية (الأمام)', 'CNI (recto)'),
  ('id_card_back', 'ID card back', 'بطاقة الهوية (الخلف)', 'CNI (verso)'),
  ('driving_license', 'Driving license', 'رخصة القيادة', 'Permis de conduire'),
  ('vehicle_registration', 'Vehicle registration', 'بطاقة المركبة', 'Carte grise'),
];

/// Personal fields the backend requires before it allows approval.
const _requiredBossInfo = [
  ('full_name', 'Full name', 'الاسم الكامل', 'Nom complet'),
  ('phone', 'Phone', 'الهاتف', 'Téléphone'),
  ('date_of_birth', 'Date of birth', 'تاريخ الميلاد', 'Date de naissance'),
  ('national_id_number', 'National ID', 'رقم الهوية', 'Numéro d’identité'),
  ('driving_license_number', 'License number', 'رقم الرخصة', 'Numéro de permis'),
  ('driving_license_expiry', 'License expiry', 'انتهاء الرخصة', 'Expiration du permis'),
  ('vehicle_plate', 'Vehicle plate', 'لوحة المركبة', 'Plaque'),
];

/// Boss-only detail view for a registered driver: profile + uploaded documents
/// + approval actions + mission history. Backed by GET /api/drivers/{id}/,
/// GET /api/drivers/{id}/documents/{type}/,
/// POST /api/drivers/{id}/approve|reject/ and
/// GET /api/missions/employee/{id}/.
class BossDriverDetailPage extends StatefulWidget {
  final int driverId;
  final String driverName;
  /// Injectable for widget tests; production uses the live API.
  final ApiService? api;

  const BossDriverDetailPage({
    super.key,
    required this.driverId,
    this.driverName = '',
    this.api,
  });

  @override
  State<BossDriverDetailPage> createState() => _BossDriverDetailPageState();
}

class _BossDriverDetailPageState extends State<BossDriverDetailPage> {
  late final ApiService _api;

  @override
  void initState() {
    _api = widget.api ?? ApiService();
    super.initState();
    appLanguage.addListener(_onLanguageChanged);
    _load();
  }

  Map<String, dynamic>? _detail;
  List<Mission> _missions = const [];
  bool _loading = true;
  String? _error;
  String? _historyError;

  // Document viewer state — images are fetched from the private, JWT-protected
  // endpoint as raw bytes; there is no public URL to pass to Image.network.
  final Map<String, Uint8List> _documentBytes = {};
  final Set<String> _loadingDocuments = {};
  final Map<String, String> _documentErrors = {};
  bool _documentsLoaded = false;

  bool _acting = false;

  String _tr(String en, String ar, String fr) {
    final lang = appLanguage.lang;
    if (lang == 'AR') return ar;
    if (lang == 'FR') return fr;
    return en;
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.getBossDriverDetail(widget.driverId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      // Document previews are the primary purpose of this screen. They must
      // load even when the optional mission-history endpoint fails.
      await _loadDocuments(detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
    // Non-blocking: the boss can still inspect documents and decide even if
    // the historical-missions endpoint is unavailable.
    _loadMissionHistory();
  }

  Future<void> _loadMissionHistory() async {
    try {
      final missions = await _api.getDriverMissionHistory(widget.driverId);
      if (mounted) {
        setState(() {
          _missions = missions;
          _historyError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _historyError = apiErrorMessage(e));
    }
  }

  /// Fetches every uploaded document so the boss can inspect them BEFORE
  /// deciding on approval. A single failing document does not hide the others.
  Future<void> _loadDocuments(Map<String, dynamic> detail) async {
    final docs = detail['documents'];
    if (docs is! Map) return;
    final uploaded = <String>[];
    for (final slot in _documentSlots) {
      final entry = docs[slot.$1];
      if (entry is Map && entry['uploaded'] == true) uploaded.add(slot.$1);
    }
    if (!mounted) return;
    setState(() {
      _loadingDocuments
        ..clear()
        ..addAll(uploaded);
      _documentErrors.clear();
      _documentsLoaded = true;
    });
    await Future.wait(uploaded.map(_fetchDocument));
    if (mounted) {
      setState(() {
        _loadingDocuments.clear();
      });
    }
  }

  Future<void> _fetchDocument(String slot) async {
    try {
      final bytes = await _api.getDocumentBytes(widget.driverId, slot);
      if (!mounted) return;
      setState(() {
        _documentBytes[slot] = Uint8List.fromList(bytes);
        _loadingDocuments.remove(slot);
        _documentErrors.remove(slot);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDocuments.remove(slot);
        _documentErrors[slot] = apiErrorMessage(e);
      });
    }
  }

  /// The backend refuses approval with `invalid_profile_transition` unless the
  /// profile has been submitted (`pending_review`) with all five documents and
  /// every required personal field. Mirror that guard in the UI.
  bool get _canApprove {
    final detail = _detail;
    if (detail == null || !_documentsLoaded) return false;
    final status = (detail['status'] ?? detail['profile_status'] ?? '').toString();
    if (status != 'pending_review') return false;
    return _missingInfoItems.isEmpty && _missingDocumentItems.isEmpty;
  }

  /// Normalise backend keys (`id_card_back`) to the labels shown in the UI.
  List<String> _missingLabels(dynamic raw, {required bool document}) {
    if (raw is! List) return const <String>[];
    return raw.map((e) {
      final key = e.toString().trim();
      if (document) {
        for (final slot in _documentSlots) {
          if (slot.$1 == key) return _tr(slot.$2, slot.$3, slot.$4);
        }
      } else {
        for (final field in _requiredBossInfo) {
          if (field.$1 == key) return _tr(field.$2, field.$3, field.$4);
        }
      }
      return key
          .replaceAll('_', ' ')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }).toList();
  }

  /// `/api/drivers/{id}/` currently omits the `missing` map, so derive it from
  /// the profile fields and document flags. If a future backend response does
  /// include `missing`, prefer that authoritative payload.
  List<String> get _missingInfoItems {
    final detail = _detail;
    if (detail == null) return const <String>[];
    final raw = detail['missing'];
    if (raw is Map && raw['info'] is List) {
      return _missingLabels(raw['info'], document: false);
    }
    return _requiredBossInfo
        .where((field) {
          final value = detail[field.$1];
          return value == null || value.toString().trim().isEmpty;
        })
        .map((field) => _tr(field.$2, field.$3, field.$4))
        .toList();
  }

  List<String> get _missingDocumentItems {
    final detail = _detail;
    if (detail == null) return const <String>[];
    final raw = detail['missing'];
    if (raw is Map && raw['documents'] is List) {
      return _missingLabels(raw['documents'], document: true);
    }
    final docs = detail['documents'];
    return _documentSlots
        .where((slot) =>
            !(docs is Map && (docs[slot.$1] as Map?)?['uploaded'] == true))
        .map((slot) => _tr(slot.$2, slot.$3, slot.$4))
        .toList();
  }

  String get _missingMessage {
    final info = _missingInfoItems;
    final docs = _missingDocumentItems;
    final header = _tr(
      'Cannot approve: driver profile is incomplete.',
      'لا يمكن الموافقة: ملف السائق غير مكتمل.',
      'Impossible d’approuver : le profil du chauffeur est incomplet.',
    );
    if (info.isEmpty && docs.isEmpty) {
      return '$header\n${_tr(
        'All information and documents are complete. The profile may be waiting for review.',
        'كل المعلومات والمستندات مكتملة. قد يكون الملف في انتظار المراجعة.',
        'Toutes les informations et pièces sont complètes. Le profil attend peut-être une révision.',
      )}';
    }
    final lines = <String>[header];
    if (docs.isNotEmpty) {
      lines.add(
          '${_tr('Missing documents', 'المستندات المفقودة', 'Pièces manquantes')}: '
          '${docs.join(', ')}.');
    }
    if (info.isNotEmpty) {
      lines.add(
          '${_tr('Missing information', 'المعلومات المفقودة', 'Informations manquantes')}: '
          '${info.join(', ')}.');
    }
    return lines.join('\n');
  }

  Future<void> _approve() async {
    if (!_canApprove) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Approve driver?', 'الموافقة على السائق؟', 'Approuver le chauffeur ?'),
            style: _pop(size: 16, weight: FontWeight.w700)),
        content: Text(
          _tr('This marks the driver as approved and active.',
              'سيتم تعيين السائق كمعتمد ونشط.', 'Le chauffeur sera marqué approuvé et actif.'),
          style: _pop(size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Cancel', 'إلغاء', 'Annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tr('Approve', 'موافقة', 'Approuver'),
                style: const TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _acting = true);
    try {
      await _api.approveDriver(widget.driverId);
      if (messenger != null) {
        showSuccessWithMessenger(
            messenger,
            _tr('Driver approved.', 'تمت الموافقة على السائق.', 'Chauffeur approuvé.'));
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (messenger != null) showApiErrorWithMessenger(messenger, e);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Reject driver', 'رفض السائق', 'Refuser le chauffeur'),
            style: _pop(size: 16, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('Explain the reason. The driver will see it.',
                  'اشرح السبب. سيراه السائق.', 'Expliquez le motif. Le chauffeur le verra.'),
              style: _pop(size: 12, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: _tr('Reason', 'السبب', 'Motif'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _amber, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel', 'إلغاء', 'Annuler')),
          ),
          TextButton(
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: Text(_tr('Reject', 'رفض', 'Refuser'),
                style: const TextStyle(color: Color(0xFFE0533D))),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.isEmpty) return;
    setState(() => _acting = true);
    try {
      await _api.rejectDriver(widget.driverId, reason);
      if (messenger != null) {
        showSuccessWithMessenger(
            messenger,
            _tr('Driver rejected.', 'تم رفض السائق.', 'Chauffeur refusé.'));
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (messenger != null) showApiErrorWithMessenger(messenger, e);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _remove() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Remove driver?', 'حذف السائق؟', 'Supprimer le chauffeur ?'),
            style: _pop(size: 16, weight: FontWeight.w700)),
        content: Text(
            _tr('This removes the driver from the platform.',
                'سيتم حذف السائق من المنصة.', 'Cela supprime le chauffeur de la plateforme.'),
            style: _pop(size: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Cancel', 'إلغاء', 'Annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tr('Remove', 'حذف', 'Supprimer'),
                style: const TextStyle(color: Color(0xFFE0533D))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await _api.deleteEmployee(widget.driverId);
      if (messenger != null) {
        showSuccessWithMessenger(messenger,
            _tr('Driver removed.', 'تم حذف السائق.', 'Chauffeur supprimé.'));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (messenger != null) showApiErrorWithMessenger(messenger, e);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _openDocument(String slot, Uint8List bytes) {
    final label = _documentSlots.firstWhere(
      (s) => s.$1 == slot,
      orElse: () => (slot, slot, slot, slot),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _tr(label.$2, label.$3, label.$4),
              style: _pop(size: 15, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _tr('This image could not be displayed.',
                        'تعذر عرض هذه الصورة.', 'Cette image ne peut pas être affichée.'),
                    style: _pop(size: 13, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_detail?['full_name'] ?? _detail?['username'] ?? widget.driverName).toString();
    final status = (_detail?['status'] ?? _detail?['profile_status'] ?? '').toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name.isEmpty ? _tr('Driver', 'سائق', 'Chauffeur') : name,
            style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
        actions: [
          IconButton(
            tooltip: _tr('Refresh documents', 'تحديث المستندات', 'Actualiser les documents'),
            icon: const Icon(Icons.refresh, color: Color(0xFFF5A524)),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: _tr('Remove driver', 'حذف السائق', 'Supprimer le chauffeur'),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE0533D)),
            onPressed: _acting ? null : _remove,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: _pop(size: 13)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _load,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_tr('Retry', 'إعادة المحاولة', 'Réessayer'),
                                style: _pop(size: 13, weight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _amber,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildProfileCard(status),
                      const SizedBox(height: 16),
                      _buildDocumentsSection(),
                      const SizedBox(height: 16),
                      _buildDecisionSection(status),
                      const SizedBox(height: 16),
                      _buildMissionHistory(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard(String status) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr('Profile', 'الملف', 'Profil'),
                style: _pop(size: 14, weight: FontWeight.w800, color: const Color(0xFF111111))),
            const SizedBox(height: 8),
            _row('ID', widget.driverId.toString()),
            _row(_tr('Phone', 'الهاتف', 'Téléphone'), (_detail?['phone'] ?? '').toString()),
            _row(_tr('Status', 'الحالة', 'Statut'), status),
            _row(_tr('Plate', 'اللوحة', 'Plaque'), (_detail?['vehicle_plate'] ?? '').toString()),
            if (status == 'rejected' &&
                (_detail?['rejection_reason'] ?? '').toString().isNotEmpty)
              _row(_tr('Reason', 'السبب', 'Motif'),
                  (_detail?['rejection_reason'] ?? '').toString()),
          ],
        ),
      );

  Widget _buildDocumentsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_tr('Documents', 'المستندات', 'Documents'),
                  style: _pop(size: 14, weight: FontWeight.w800,
                      color: const Color(0xFF111111))),
              const SizedBox(width: 8),
              if (!_documentsLoaded)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _tr('Inspect all documents before approving.',
                'افحص كل المستندات قبل الموافقة.',
                'Inspectez tous les documents avant d\'approuver.'),
            style: _pop(size: 11, color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 10),
          ..._documentSlots.map(_buildDocumentTile),
        ],
      );

  Widget _buildDocumentTile((String, String, String, String) slot) {
    final bytes = _documentBytes[slot.$1];
    final loading = _loadingDocuments.contains(slot.$1);
    final error = _documentErrors[slot.$1];
    final uploaded = bytes != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  uploaded ? Icons.check_circle : Icons.description_outlined,
                  size: 18,
                  color: uploaded ? const Color(0xFF4CAF50) : const Color(0xFFBBBBBB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tr(slot.$2, slot.$3, slot.$4),
                    style: _pop(size: 12, weight: FontWeight.w600,
                        color: const Color(0xFF333333)),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
                  )
                else if (uploaded)
                  GestureDetector(
                    onTap: () => _openDocument(slot.$1, bytes),
                    child: Text(
                      _tr('View', 'عرض', 'Voir'),
                      style: _pop(size: 12, weight: FontWeight.w700, color: _amber),
                    ),
                  )
                else
                  Text(
                    _tr('Not uploaded', 'لم يُرفع', 'Non téléversé'),
                    style: _pop(size: 11, color: const Color(0xFFAAAAAA)),
                  ),
              ],
            ),
            if (uploaded) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openDocument(slot.$1, bytes),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    bytes,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 120,
                      color: const Color(0xFFF5F5F5),
                      child: Center(
                        child: Text(
                          _tr('Preview unavailable', 'المعاينة غير متاحة', 'Aperçu indisponible'),
                          style: _pop(size: 11, color: const Color(0xFF999999)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(error,
                        style: _pop(size: 10, color: const Color(0xFFE0533D))),
                  ),
                  GestureDetector(
                    onTap: () => _fetchDocument(slot.$1),
                    child: Text(_tr('Retry', 'إعادة', 'Réessayer'),
                        style: _pop(size: 10, weight: FontWeight.w700,
                            color: const Color(0xFFE0533D))),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionSection(String status) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_tr('Decision', 'القرار', 'Décision'),
                style: _pop(size: 14, weight: FontWeight.w800,
                    color: const Color(0xFF111111))),
            const SizedBox(height: 6),
            Text(
              _tr('Current status', 'الحالة الحالية', 'Statut actuel'),
                  style: _pop(size: 11, color: const Color(0xFF999999)),
            ),
            Text(status,
                style: _pop(size: 13, weight: FontWeight.w700, color: _amber)),
            const SizedBox(height: 10),
            if (!_canApprove && status == 'incomplete')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE0533D).withValues(alpha: 0.35)),
                ),
                child: Text(
                  _missingMessage,
                  style: _pop(size: 11, color: const Color(0xFFC0392B)),
                ),
              )
            else if (status != 'pending_review' && status != 'incomplete')
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _tr('Approval is only available while the profile is pending review.',
                      'الموافقة متاحة فقط عندما يكون الملف قيد المراجعة.',
                      'L’approbation est possible uniquement si le profil est en révision.'),
                  style: _pop(size: 11, color: const Color(0xFF999999)),
                ),
              ),
            const SizedBox(height: 14),
            if (_acting)
              const Center(
                child: CircularProgressIndicator(color: _amber),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _canApprove ? _approve : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _canApprove
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFCCCCCC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tr('Approve', 'موافقة', 'Approuver'),
                          textAlign: TextAlign.center,
                          style: _pop(size: 12, weight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: status == 'rejected' ? null : _reject,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: status == 'rejected'
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFFE0533D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tr('Reject', 'رفض', 'Refuser'),
                          textAlign: TextAlign.center,
                          style: _pop(size: 12, weight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _buildMissionHistory() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_tr('Mission history', 'سجل المهام', 'Historique des missions'),
              style: _pop(size: 14, weight: FontWeight.w800,
                  color: const Color(0xFF111111))),
          const SizedBox(height: 8),
          if (_historyError != null)
            _card(
              child: Column(
                children: [
                  Text(_historyError!, style: _pop(size: 12, color: const Color(0xFFE0533D))),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadMissionHistory,
                    child: Text(_tr('Retry', 'إعادة', 'Réessayer')),
                  ),
                ],
              ),
            )
          else if (_missions.isEmpty)
            _card(
              child: Center(
                child: Text(
                  _tr('No missions', 'لا توجد مهام', 'Aucune mission'),
                  style: _pop(size: 13, color: const Color(0xFF999999)),
                ),
              ),
            )
          else
            ..._missions.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${m.id}  ${m.shipmentType}',
                                style: _pop(size: 12, weight: FontWeight.w700,
                                    color: const Color(0xFF111111))),
                            Text('${m.shipmentType} • ${m.distance.toStringAsFixed(0)} km',
                                style: _pop(size: 11, color: const Color(0xFF666666))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3DC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(m.status,
                            style: _pop(size: 10, weight: FontWeight.w700,
                                color: const Color(0xFFB87600))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: child,
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label, style: _pop(size: 12, color: const Color(0xFF999999))),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: _pop(size: 12, weight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
