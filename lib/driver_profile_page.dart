import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'app_language.dart';
import 'models/api_models.dart';
import 'notification/mission_notifications_page.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/driver_verification_state.dart';
import 'widgets/api_state.dart';

TextStyle _pop({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

const _amber = Color(0xFFF5A524);

const _slots = [
  ('selfie', 'Selfie', 'سيلفي', 'Selfie'),
  ('id_card_front', 'ID card (front)', 'بطاقة الهوية (الأمام)', 'CNI (recto)'),
  ('id_card_back', 'ID card (back)', 'بطاقة الهوية (الخلف)', 'CNI (verso)'),
  ('driving_license', 'Driving license', 'رخصة القيادة', 'Permis de conduire'),
  ('vehicle_registration', 'Vehicle registration', 'بطاقة المركبة', 'Carte grise'),
];

/// Personal fields the backend lists under `missing.info` on its profile API.
const _requiredInfo = [
  ('full_name', 'Full name', 'الاسم الكامل', 'Nom complet'),
  ('phone', 'Phone number', 'رقم الهاتف', 'Numéro de téléphone'),
  ('date_of_birth', 'Date of birth', 'تاريخ الميلاد', 'Date de naissance'),
  ('national_id_number', 'National ID number', 'رقم الهوية الوطنية', 'Numéro d’identité'),
  ('driving_license_number', 'Driving license number', 'رقم رخصة القيادة', 'Numéro de permis'),
  ('driving_license_expiry', 'Driving license expiry', 'تاريخ انتهاء الرخصة', 'Expiration du permis'),
  ('vehicle_plate', 'Vehicle plate', 'لوحة المركبة', 'Plaque d’immatriculation'),
];

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final ApiService _api = ApiService();
  DriverProfile? _profile;
  bool _loading = true;
  String? _error;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    _load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.getDriverProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _submitForReview() async {
    if (_hasMissing) {
      showApiError(context, _missingSummary);
      return;
    }
    if (!_decisionsComplete) {
      showApiError(
        context,
        _t('All documents need a passing quality check.',
            'جميع المستندات تحتاج فحص جودة ناجحاً.',
            'Tous les documents doivent passer le contrôle qualité.'),
      );
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _loading = true);
    try {
      final updated = await _api.submitDriverProfile();
      await _load();
      if (messenger != null) {
        showSuccessWithMessenger(
            messenger,
            _t('Submitted for review.', 'تم الإرسال للمراجعة.', 'Soumis pour révision.'));
      }
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (messenger != null) showApiErrorWithMessenger(messenger, e);
    }
  }

  int get _statusLevel {
    switch (_profile?.status) {
      case 'approved':
        return 2;
      case 'pending_review':
        return 1;
      default:
        return 0;
    }
  }

  /// Backend-authoritative missing lists, with a local fallback for older
  /// payloads that do not include the `missing` map.
  List<String> get _missingDocuments {
    final profile = _profile;
    if (profile == null) return const [];
    final raw = profile.missing['documents'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return _slots
        .where((s) =>
            (profile.documents[s.$1] as Map?)?['uploaded'] != true)
        .map((s) => s.$1)
        .toList();
  }

  List<String> get _missingInfo {
    final profile = _profile;
    if (profile == null) return const [];
    final raw = profile.missing['info'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return _requiredInfo
        .where((f) =>
            profile.raw[f.$1] == null ||
            profile.raw[f.$1].toString().trim().isEmpty)
        .map((f) => f.$1)
        .toList();
  }

  bool get _hasMissing =>
      _missingDocuments.isNotEmpty || _missingInfo.isNotEmpty;

  /// The profile-level submit button must mirror the verification page gate:
  /// every slot needs a persisted ACCEPT/MANUAL_REVIEW for the CURRENT
  /// documents version, not just a non-empty `missing` list (C5).
  bool get _decisionsComplete {
    final profile = _profile;
    if (profile == null) return false;
    return _slots.every((slot) {
      final decision = readPersistedDecision(
        profile.verificationResults,
        slot.$1,
        profile.documentsVersion,
      );
      return decision?.passedFor(profile.documentsVersion) == true;
    });
  }

  bool get _canSubmitProfile => !_hasMissing && _decisionsComplete;

  String get _missingSummary {
    final groups = <String>[];
    if (_missingInfo.isNotEmpty) {
      final labels = _missingInfo.map((key) {
        for (final f in _requiredInfo) {
          if (f.$1 == key) return _t(f.$2, f.$3, f.$4);
        }
        return key.replaceAll('_', ' ');
      }).join(', ');
      groups.add('${_t('Missing information', 'المعلومات المفقودة', 'Informations manquantes')}: $labels');
    }
    if (_missingDocuments.isNotEmpty) {
      final labels = _missingDocuments.map((key) {
        for (final s in _slots) {
          if (s.$1 == key) return _t(s.$2, s.$3, s.$4);
        }
        return key.replaceAll('_', ' ');
      }).join(', ');
      groups.add('${_t('Missing documents', 'المستندات المفقودة', 'Pièces manquantes')}: $labels');
    }
    return groups.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: ApiLoadingView(message: 'Loading profile...'),
      );
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: ApiErrorView(
          message: _error ?? 'Profile unavailable.',
          onRetry: _load,
        ),
      );
    }

    final profile = _profile!;
    final level = _statusLevel;
    final initials = profile.fullName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(
            initials.isEmpty ? 'DR' : initials,
            profile.fullName.isEmpty ? 'Driver' : profile.fullName,
            level,
          ),
          const SizedBox(height: 20),
          if (_hasMissing) ...[
            _buildCompletionBanner(),
            const SizedBox(height: 12),
          ],
          _buildChecklistCard(),
          const SizedBox(height: 20),
          if (profile.status == 'incomplete') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmitProfile ? _submitForReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmitProfile ? _amber : const Color(0xFFCCCCCC),
                  disabledBackgroundColor: const Color(0xFFCCCCCC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _t('Submit for review', 'إرسال للمراجعة', 'Soumettre pour révision'),
                  style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            if (_hasMissing) ...[
              const SizedBox(height: 8),
              Text(
                _missingSummary,
                style: _pop(size: 11, color: const Color(0xFF999999)),
              ),
            ],
            const SizedBox(height: 20),
          ],
          _buildMenuButton(
            icon: Icons.person_outline,
            label: _t('Personal Information', 'المعلومات الشخصية', 'Informations personnelles'),
            subtitle: _t('View and edit your profile and documents',
                'عرض وتعديل ملفك ومستنداتك', 'Voir et modifier votre profil et documents'),
            color: _amber,
            onTap: () => _showPersonalInfoPage(profile),
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            icon: Icons.verified_user_outlined,
            label: _t('Account Verification', 'تحقق الحساب', 'Vérification du compte'),
            subtitle: _statusSubtitle(level, profile),
            color: level == 2
                ? const Color(0xFF4CAF50)
                : level == 1
                    ? const Color(0xFF2196F3)
                    : _amber,
            onTap: () => _showVerificationPage(profile),
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            icon: Icons.language,
            label: _t('Language', 'اللغة', 'Langue'),
            subtitle: _lang == 'AR' ? 'العربية' : _lang == 'FR' ? 'Français' : 'English',
            color: const Color(0xFF2196F3),
            onTap: () => _showLanguageDialog(),
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            icon: Icons.notifications_none,
            label: _t('Mission Notifications', 'إشعارات المهام', 'Notifications de mission'),
            subtitle: _t('Manage push notifications for new missions',
                'إدارة إشعارات المهام الجديدة', 'Gérez les notifications des nouvelles missions'),
            color: _amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MissionNotificationsPage()),
            ),
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
    return _isArabic
        ? Directionality(textDirection: TextDirection.rtl, child: content)
        : content;
  }

  String _statusSubtitle(int level, DriverProfile profile) {
    if (level == 2) return _t('Verified', 'موثق', 'Vérifié');
    if (level == 1) return _t('Documents under review', 'المستندات قيد المراجعة', 'Documents en révision');
    if (profile.status == 'rejected') {
      return '${_t('Rejected', 'مرفوض', 'Refusé')}: ${profile.rejectionReason ?? ''}';
    }
    return _t('Not verified yet', 'لم يتم التحقق بعد', 'Non vérifié');
  }

  // ------------------------------------------------------------------
  // Completion checklist — makes the backend `missing` payload explicit so
  // the driver knows exactly why the boss cannot approve the profile.
  // ------------------------------------------------------------------
  Widget _buildCompletionBanner() {
    final docs = _missingDocuments.length;
    final info = _missingInfo.length;
    return GestureDetector(
      onTap: _showChecklistSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4DE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _amber.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE08A00), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Complete your profile',
                        'أكمل ملفك الشخصي', 'Complétez votre profil'),
                    style: _pop(size: 15, weight: FontWeight.w700,
                        color: const Color(0xFF7A4A00)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t('Missing: $docs document(s) and $info field(s). The boss cannot approve an incomplete profile.',
                        'الناقص: $docs مستند و$info حقل. لا يمكن للمدير الموافقة على ملف غير مكتمل.',
                        'Manquants : $docs document(s) et $info champ(s). Le responsable ne peut pas approuver un profil incomplet.'),
                    style: _pop(size: 11, color: const Color(0xFF8B6B33)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFE08A00)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Approval checklist', 'قائمة التحقق للموافقة', 'Liste de contrôle'),
            style: _pop(size: 14, weight: FontWeight.w700,
                color: const Color(0xFF111111)),
          ),
          const SizedBox(height: 10),
          _checklistSectionTitle(_t('Documents', 'المستندات', 'Documents')),
          ..._slots.map((s) => _checklistRow(s.$1, s.$2, s.$3, s.$4,
              !_missingDocuments.contains(s.$1))),
          const SizedBox(height: 12),
          _checklistSectionTitle(
              _t('Personal information', 'المعلومات الشخصية', 'Informations personnelles')),
          ..._requiredInfo.map((f) => _checklistRow(f.$1, f.$2, f.$3, f.$4,
              !_missingInfo.contains(f.$1))),
        ],
      ),
    );
  }

  Widget _checklistSectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: _pop(size: 11, weight: FontWeight.w700,
              color: const Color(0xFF999999)),
        ),
      );

  Widget _checklistRow(String key, String en, String ar, String fr, bool ok) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(ok ? '✅' : '❌', style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _t(en, ar, fr),
                style: _pop(
                  size: 12,
                  color: ok ? const Color(0xFF333333) : const Color(0xFFC0392B),
                  weight: ok ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
            if (!ok)
              Text(
                _t('Missing', 'ناقص', 'Manquant'),
                style: _pop(size: 10, color: const Color(0xFFC0392B)),
              ),
          ],
        ),
      );

  void _showChecklistSheet() {
    final profile = _profile;
    if (profile == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t('Complete your profile', 'أكمل ملفك الشخصي', 'Complétez votre profil'),
                style: _pop(size: 17, weight: FontWeight.w700,
                    color: const Color(0xFF111111)),
              ),
              const SizedBox(height: 4),
              Text(
                _t('All items below are required before the boss can approve you.',
                    'كل العناصر أدناه مطلوبة قبل أن يتمكن المدير من الموافقة عليك.',
                    'Tous les éléments ci-dessous sont requis avant approbation.'),
                style: _pop(size: 12, color: const Color(0xFF888888)),
              ),
              const SizedBox(height: 18),
              ..._slots.map((s) => _checklistRow(s.$1, s.$2, s.$3, s.$4,
                  !_missingDocuments.contains(s.$1))),
              const SizedBox(height: 12),
              ..._requiredInfo.map((f) => _checklistRow(f.$1, f.$2, f.$3, f.$4,
                  !_missingInfo.contains(f.$1))),
              const SizedBox(height: 20),
              if (_missingInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showPersonalInfoPage(profile);
                    },
                    child: Text(
                      _t('Edit personal information', 'تعديل المعلومات الشخصية',
                          'Modifier les informations'),
                    ),
                  ),
                ),
              if (_missingDocuments.isNotEmpty)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showVerificationPage(profile);
                  },
                  child: Text(_t('Upload documents', 'رفع المستندات', 'Téléverser les documents')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String initials, String name, int level) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _amber,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _amber.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(initials,
                  style: _pop(size: 24, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              style: _pop(size: 18, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  level == 2
                      ? Icons.verified
                      : level == 1
                          ? Icons.hourglass_top
                          : Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  level == 2
                      ? _t('Verified', 'موثق', 'Vérifié')
                      : level == 1
                          ? _t('Under Review', 'قيد المراجعة', 'En révision')
                          : _t('Not Verified', 'غير موثق', 'Non vérifié'),
                  style: _pop(size: 11, weight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _pop(size: 14, weight: FontWeight.w600, color: const Color(0xFF111111))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _pop(size: 11, color: const Color(0xFF999999))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          await AuthService().logout();
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_t('Logout', 'تسجيل الخروج', 'Déconnexion'),
              style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFFE0533D))),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['EN', 'AR', 'FR']
              .map(
                (l) => ListTile(
                  title: Text(l == 'EN' ? 'English' : l == 'AR' ? 'العربية' : 'Français'),
                  trailing: _lang == l ? const Icon(Icons.check, color: _amber) : null,
                  onTap: () {
                    appLanguage.setLang(l);
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showPersonalInfoPage(DriverProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalInfoPage(
          profile: profile,
          t: _t,
          onSaved: (p) {
            setState(() => _profile = p);
          },
        ),
      ),
    );
  }

  void _showVerificationPage(DriverProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VerificationStatusPage(
          profile: profile,
          t: _t,
          onSaved: (updated) {
            if (mounted) setState(() => _profile = updated);
          },
        ),
      ),
    );
  }
}

class PersonalInfoPage extends StatefulWidget {
  final DriverProfile profile;
  final String Function(String, String, String) t;
  final void Function(DriverProfile) onSaved;
  const PersonalInfoPage({
    super.key,
    required this.profile,
    required this.t,
    required this.onSaved,
  });

  @override
  State<PersonalInfoPage> createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  final ApiService _api = ApiService();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _nationalId = TextEditingController();
  final _license = TextEditingController();
  final _licenseExpiry = TextEditingController();
  final _plate = TextEditingController();
  bool _saving = false;
  String? _message;

  String Function(String, String, String) get t => widget.t;

  @override
  void initState() {
    super.initState();
    final raw = widget.profile.raw;
    _fullName.text = _str(raw['full_name']);
    _phone.text = _str(raw['phone']);
    _dob.text = _isoDate(raw['date_of_birth']);
    _nationalId.text = _str(raw['national_id_number']);
    _license.text = _str(raw['driving_license_number']);
    _licenseExpiry.text = _isoDate(raw['driving_license_expiry']);
    _plate.text = _str(raw['vehicle_plate']);
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  /// Backend uses ISO 8601 dates (`YYYY-MM-DD`) for both date fields.
  static String _isoDate(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return _formatDate(v);
    final raw = v.toString().trim();
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : _formatDate(parsed);
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _dob.dispose();
    _nationalId.dispose();
    _license.dispose();
    _licenseExpiry.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _api.updateDriverProfile({
        'full_name': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'date_of_birth': _dob.text.trim().isEmpty ? null : _dob.text.trim(),
        'national_id_number': _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
        'driving_license_number': _license.text.trim().isEmpty ? null : _license.text.trim(),
        'driving_license_expiry': _licenseExpiry.text.trim().isEmpty ? null : _licenseExpiry.text.trim(),
        'vehicle_plate': _plate.text.trim(),
      });
      // Re-fetch so the checklist is driven by the server's authoritative
      // `missing` lists, not by a local guess.
      final fresh = await _api.getDriverProfile();
      if (!mounted) return;
      widget.onSaved(fresh);
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      if (messenger != null) {
        showSuccessWithMessenger(
            messenger, t('Saved successfully.', 'تم الحفظ بنجاح.', 'Enregistré.'));
      }
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('Personal Information', 'المعلومات الشخصية', 'Informations personnelles'),
            style: _pop(size: 17, weight: FontWeight.w700, color: const Color(0xFF111111))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(_fullName, t('Full Name', 'الاسم الكامل', 'Nom complet'), Icons.person_outline),
            const SizedBox(height: 10),
            _field(_phone, t('Phone', 'الهاتف', 'Téléphone'), Icons.phone_outlined),
            const SizedBox(height: 10),
            _dateField(
              _dob,
              t('Date of birth', 'تاريخ الميلاد', 'Date de naissance'),
              Icons.cake_outlined,
              isBirthday: true,
            ),
            const SizedBox(height: 10),
            _field(_nationalId, t('National ID number', 'رقم الهوية', 'Numéro CNI'), Icons.badge_outlined),
            const SizedBox(height: 10),
            _field(_license, t('Driving license number', 'رقم رخصة القيادة', 'Numéro permis'), Icons.credit_card_outlined),
            const SizedBox(height: 10),
            _dateField(
              _licenseExpiry,
              t('Driving license expiry', 'انتهاء الرخصة', 'Expiration du permis'),
              Icons.calendar_today_outlined,
              allowPast: true,
            ),
            const SizedBox(height: 10),
            _field(_plate, t('Vehicle plate', 'لوحة المركبة', 'Plaque véhicule'), Icons.local_shipping_outlined),
            const SizedBox(height: 18),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_message!, style: _pop(size: 13, color: const Color(0xFF4CAF50))),
              ),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _saving ? const Color(0xFFCCCCCC) : _amber,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _saving
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Text(t('Save changes', 'حفظ التغييرات', 'Enregistrer'),
                          textAlign: TextAlign.center,
                          style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isBirthday = false,
    bool allowPast = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final now = DateTime.now();
        final lastDate = isBirthday
            ? now
            : DateTime(now.year + 10, now.month, now.day);
        final firstDate = (isBirthday || allowPast) ? DateTime(1900) : now;
        final parsed = DateTime.tryParse(controller.text);
        DateTime initial;
        if (parsed != null) {
          initial = parsed.isBefore(firstDate)
              ? firstDate
              : (parsed.isAfter(lastDate) ? lastDate : parsed);
        } else if (isBirthday) {
          initial = DateTime(now.year - 25);
        } else if (allowPast) {
          initial = now;
        } else {
          initial = now;
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: label,
        );
        if (picked != null) {
          controller.text = _formatDate(picked);
          setState(() => _message = null);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        prefixIcon: Icon(icon, color: _amber),
        suffixIcon: const Icon(Icons.event, color: _amber),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _amber, width: 2)),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _amber),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _amber, width: 2)),
      ),
    );
  }
}

class _VerificationStatusPage extends StatefulWidget {
  final DriverProfile profile;
  final String Function(String, String, String) t;
  final void Function(DriverProfile profile)? onSaved;
  const _VerificationStatusPage({
    required this.profile,
    required this.t,
    this.onSaved,
  });

  @override
  State<_VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<_VerificationStatusPage> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  late DriverProfile _profile;
  bool _busy = false;
  String? _busySlot;
  String? _result;
  final Map<String, DriverVerificationDecision> _results = {};
  Timer? _pollTimer;
  Completer<void>? _pollCompleter;
  int _operationGeneration = 0;

  String Function(String, String, String) get t => widget.t;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _hydrateResults();
  }

  @override
  void dispose() {
    _operationGeneration++;
    _pollTimer?.cancel();
    if (_pollCompleter != null && !_pollCompleter!.isCompleted) {
      _pollCompleter!.complete();
    }
    super.dispose();
  }

  /// Restore persisted backend decisions for the current documents version.
  void _hydrateResults() {
    _results.clear();
    for (final slot in _slots) {
      final saved = readPersistedDecision(
        _profile.verificationResults,
        slot.$1,
        _profile.documentsVersion,
      );
      if (saved != null) _results[slot.$1] = saved;
    }
  }

  void _applyProfile(DriverProfile fresh) {
    _profile = fresh;
    _hydrateResults();
  }

  /// A rejected document is stored on the server but must not count as a
  /// completed upload (D9).
  bool _uploaded(String slot) {
    if ((_profile.documents[slot] as Map?)?['uploaded'] != true) return false;
    return _results[slot]?.rejected != true;
  }

  int get _uploadedCount =>
      _slots.where((s) => _uploaded(s.$1)).length;

  int get _passedCount => _slots
      .where((s) => _results[s.$1]?.passedFor(_profile.documentsVersion) == true)
      .length;

  /// Submission is only enabled when all five documents are stored on the
  /// backend AND every quality decision for THIS documents version is
  /// ACCEPT / MANUAL_REVIEW.
  bool get _canSubmit =>
      !_busy &&
      _uploadedCount == _slots.length &&
      _slots.every((s) =>
          _results[s.$1]?.passedFor(_profile.documentsVersion) == true);

  String get _submitHint {
    if (_uploadedCount < _slots.length) {
      return t('Upload all 5 documents to submit.',
          'ارفع المستندات الخمسة للإرسال.', 'Téléversez les 5 documents pour soumettre.');
    }
    final pending = _slots
        .where((s) =>
            _results[s.$1]?.passedFor(_profile.documentsVersion) != true)
        .length;
    if (pending > 0) {
      return t('$pending document(s) still need a passing quality check.',
          '$pending مستند(ات) ما زالت بحاجة لفحص جودة ناجح.',
          '$pending document(s) nécessitent encore un contrôle qualité réussi.');
    }
    return '';
  }

  /// First poll is immediate; later polls wait two seconds and are cancelled
  /// on dispose. No artificial delay before the first result (m12).
  Future<void> _waitForPoll(int attempt, int generation) async {
    if (attempt == 0) return;
    final completer = Completer<void>();
    _pollCompleter = completer;
    _pollTimer = Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    if (generation != _operationGeneration || !mounted) return;
  }

  void _setResult(String slot, DriverVerificationDecision result) {
    if (!mounted) return;
    final stored = result.documentsVersion < 0
        ? DriverVerificationDecision(
            slot: result.slot,
            phase: result.phase,
            decision: result.decision,
            reasons: result.reasons,
            message: result.message,
            documentsVersion: _profile.documentsVersion,
          )
        : result;
    setState(() {
      _results[slot] = stored;
      _result = _formatResult(stored);
    });
  }

  String _formatResult(DriverVerificationDecision r) {
    final label = switch (r.decision) {
      'ACCEPT' => t('ACCEPTED', 'مقبول', 'ACCEPTÉ'),
      'MANUAL_REVIEW' => t('MANUAL REVIEW', 'مراجعة يدوية', 'RÉVISION MANUELLE'),
      'REJECT' => t('REJECTED — please retake', 'مرفوض — أعد التصوير', 'REJETÉ — veuillez reprendre'),
      _ => r.decision,
    };
    final slotLabel = _slots.firstWhere(
      (s) => s.$1 == r.slot,
      orElse: () => (r.slot, r.slot, r.slot, r.slot),
    );
    final base = '${t(slotLabel.$2, slotLabel.$3, slotLabel.$4)}: $label';
    if (r.message.isNotEmpty) return '$base — ${r.message}';
    if (r.reasons.isEmpty) return base;
    return '$base — ${r.reasons}';
  }

  Future<void> _upload(String slot) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final generation = _operationGeneration;
    setState(() {
      _busy = true;
      _busySlot = slot;
      _results.remove(slot);
      _result = t('Selecting a photo...', 'جارٍ اختيار صورة...', 'Sélection d\'une photo...');
    });
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return; // cancelled: the finally block releases _busy
      final bytes = await x.readAsBytes();
      final updated = await _api.uploadDocument(slot, bytes, x.name);
      if (!mounted || generation != _operationGeneration) return;
      setState(() {
        _applyProfile(updated);
        _result = t('Uploaded. Running automatic check...',
            'تم الرفع. جاري الفحص التلقائي...',
            'Téléversé. Vérification automatique...');
      });
      // Same bytes are sent to the quality gate, exactly as the backend expects.
      await _check(slot, bytes, x.name, generation);
    } catch (e) {
      if (!mounted || generation != _operationGeneration) return;
      final message = apiErrorMessage(e);
      if (messenger != null) showApiErrorWithMessenger(messenger, message);
      _setResult(slot, DriverVerificationDecision(
        slot: slot,
        phase: 'failed',
        message: message,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _busySlot = null;
          _busy = false;
        });
      }
    }
  }

  Future<void> _check(
    String slot,
    List<int> bytes,
    String filename,
    int generation,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final taskId = await _api.checkDocument(slot, bytes, filename);
      if (taskId.isEmpty) {
        final message = t(
          'The verification service did not return a task id. Please retry.',
          'لم يُرجع معرّف مهمة للتحقق. أعد المحاولة.',
          'Le service de vérification n\'a pas renvoyé de tâche. Réessayez.',
        );
        if (!context.mounted) return;
        if (messenger != null) showApiErrorWithMessenger(messenger, message);
        _setResult(slot,
            DriverVerificationDecision(slot: slot, phase: 'failed', message: message));
        return;
      }
      // Backend bridge timeout defaults to 180s. Poll immediately, then wait
      // 2s between retries; the wait is cancellable on dispose.
      for (var i = 0; i < 90; i++) {
        await _waitForPoll(i, generation);
        if (!mounted || generation != _operationGeneration) return;
        final status = await _api.getVerificationStatus(taskId);
        if (!context.mounted || generation != _operationGeneration) return;
        final s = status['status']?.toString();
        if (s == 'completed') {
          final decision = status['final_decision']?.toString() ?? '';
          final reasons = (status['reason_codes'] as List?)
                  ?.map((e) => e.toString())
                  .join(', ') ??
              '';
          final quality = status['quality_status']?.toString() ?? '';
          _setResult(slot, DriverVerificationDecision(
            slot: slot,
            phase: 'done',
            decision: decision,
            reasons: reasons,
            message: quality,
            documentsVersion: _profile.documentsVersion,
          ));
          return;
        }
        if (s == 'failed') {
          final message = status['detail']?.toString() ??
              status['code']?.toString() ??
              'Verification failed';
          if (messenger != null) showApiErrorWithMessenger(messenger, message);
          _setResult(slot, DriverVerificationDecision(
            slot: slot,
            phase: 'failed',
            message: message,
          ));
          return;
        }
        if (i == 15 || i == 45) {
          if (mounted) {
            setState(() => _result = t(
              'Still checking this document. Please wait...',
              'ما زال جاري فحص المستند. يرجى الانتظار...',
              'Vérification en cours. Veuillez patienter...',
            ));
          }
        }
      }
      final message = t(
        'Verification timed out. Please retry this document.',
        'انتهت مهلة التحقق. أعد المحاولة لهذا المستند.',
        'La vérification a expiré. Réessayez pour ce document.',
      );
      if (!context.mounted) return;
      if (messenger != null) showApiErrorWithMessenger(messenger, message);
      _setResult(slot,
          DriverVerificationDecision(slot: slot, phase: 'failed', message: message));
    } catch (e) {
      if (!context.mounted) return;
      final message = apiErrorMessage(e);
      if (messenger != null) showApiErrorWithMessenger(messenger, message);
      _setResult(slot,
          DriverVerificationDecision(slot: slot, phase: 'failed', message: message));
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (_busy) return;
    if (!_canSubmit) {
      showApiError(context, _submitHint);
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await _api.submitDriverProfile();
      if (!mounted) return;
      setState(() {
        _applyProfile(updated);
        _result = t(
          'Submitted for review.',
          'تم الإرسال للمراجعة.',
          'Soumis pour révision.',
        );
      });
      widget.onSaved?.call(updated);
    } catch (e) {
      if (!mounted) return;
      if (messenger != null) showApiErrorWithMessenger(messenger, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('Account Verification', 'تحقق الحساب', 'Vérification du compte'),
            style: _pop(size: 17, weight: FontWeight.w700, color: const Color(0xFF111111))),
        actions: [
          IconButton(
            tooltip: t('Refresh', 'تحديث', 'Actualiser'),
            icon: const Icon(Icons.refresh, color: _amber),
            onPressed: _busy
                ? null
                : () async {
                    try {
                      final fresh = await _api.getDriverProfile();
                      if (!mounted) return;
                      setState(() => _applyProfile(fresh));
                    } catch (e) {
                      if (!context.mounted) return;
                      showApiError(context, e);
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _amber,
        onRefresh: () async {
          try {
            final fresh = await _api.getDriverProfile();
            if (!mounted) return;
            setState(() => _applyProfile(fresh));
          } catch (e) {
            if (!context.mounted) return;
            showApiError(context, e);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              _sectionTitle(t('Verification Status', 'حالة التحقق', 'Statut de vérification')),
              const SizedBox(height: 10),
              ..._slots.map(_buildVerificationTile),
              const SizedBox(height: 20),
              _sectionTitle(t('Documents', 'المستندات', 'Documents')),
              const SizedBox(height: 10),
              ..._slots.map(_buildDocumentTile),
              if (_result != null) ...[
                const SizedBox(height: 12),
                _card(
                  color: _resultColor(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_resultIcon(), size: 18, color: _resultTextColor()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _result!,
                          style: _pop(size: 13, weight: FontWeight.w600,
                              color: _resultTextColor()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: _amber),
                  ),
                ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _canSubmit ? _amber : const Color(0xFFCCCCCC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    t('Submit for review', 'إرسال للمراجعة', 'Soumettre pour révision'),
                    textAlign: TextAlign.center,
                    style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              if (_submitHint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _submitHint,
                  textAlign: TextAlign.center,
                  style: _pop(size: 11, color: const Color(0xFFE0533D)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _profile.status;
    final statusLabel = switch (status) {
      'approved' => t('Approved', 'موثق', 'Approuvé'),
      'pending_review' => t('Under review', 'قيد المراجعة', 'En révision'),
      'rejected' => t('Rejected', 'مرفوض', 'Refusé'),
      _ => t('Not verified', 'غير موثق', 'Non vérifié'),
    };
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: _amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${t('Status', 'الحالة', 'Statut')}: $statusLabel',
                  style: _pop(size: 14, weight: FontWeight.w700,
                      color: const Color(0xFF222222)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${t('Documents', 'المستندات', 'Documents')}: '
            '$_uploadedCount/${_slots.length}    •    '
            '${t('Quality passed', 'اجتاز الفحص', 'Qualité validée')}: '
            '$_passedCount/${_slots.length}',
            style: _pop(size: 12, color: const Color(0xFF666666)),
          ),
          if (status == 'rejected' &&
              (_profile.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${t('Reason', 'السبب', 'Motif')}: ${_profile.rejectionReason}',
              style: _pop(size: 12, color: const Color(0xFFE0533D)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: _pop(size: 15, weight: FontWeight.w700,
            color: const Color(0xFF111111)),
      );

  Widget _buildVerificationTile((String, String, String, String) s) {
    final r = _results[s.$1];
    final passed = r?.passedFor(_profile.documentsVersion) == true;
    final color = r == null
        ? const Color(0xFF999999)
        : passed
            ? const Color(0xFF4CAF50)
            : r.rejected || r.failed
                ? const Color(0xFFE0533D)
                : _amber;
    final label = r == null
        ? t('Not checked yet', 'لم يُفحص بعد', 'Pas encore vérifié')
        : passed
            ? (r.decision == 'ACCEPT'
                ? t('Accepted', 'مقبول', 'Accepté')
                : t('Manual review', 'مراجعة يدوية', 'Révision manuelle'))
            : r.rejected
                ? t('Rejected', 'مرفوض', 'Refusé')
                : t('Check failed', 'فشل الفحص', 'Échec du contrôle');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        child: Row(
          children: [
            Icon(passed ? Icons.verified : Icons.rule,
                size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t(s.$2, s.$3, s.$4),
                      style: _pop(size: 12, weight: FontWeight.w600,
                          color: const Color(0xFF222222))),
                  if (r != null && r.reasons.isNotEmpty)
                    Text(r.reasons,
                        style: _pop(size: 10, color: color)),
                  if (r != null && r.failed && r.message.isNotEmpty)
                    Text(r.message,
                        style: _pop(size: 10, color: color)),
                ],
              ),
            ),
            Text(label,
                style: _pop(size: 11, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile((String, String, String, String) s) {
    final uploaded = _uploaded(s.$1);
    final isBusy = _busySlot == s.$1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        child: Row(
          children: [
            Icon(uploaded ? Icons.check_circle : Icons.upload_file,
                color: uploaded ? const Color(0xFF4CAF50) : _amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(t(s.$2, s.$3, s.$4),
                  style: _pop(size: 13, color: const Color(0xFF333333))),
            ),
            if (isBusy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _amber),
              )
            else
              GestureDetector(
                onTap: _busy ? null : () => _upload(s.$1),
                child: Text(
                  uploaded
                      ? t('Retake', 'إعادة تصوير', 'Reprendre')
                      : t('Upload', 'رفع', 'Téléverser'),
                  style: _pop(size: 12, weight: FontWeight.w700, color: _amber),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _resultColor() {
    final r = _results.values.isEmpty
        ? null
        : _results.values.reduce((a, b) =>
            a.rejected || a.failed ? a : (b.rejected || b.failed ? b : a));
    if (r?.rejected == true || r?.failed == true) {
      return const Color(0xFFFFEBEE);
    }
    return const Color(0xFFE8F5E9);
  }

  IconData _resultIcon() {
    final r = _results.values.isEmpty
        ? null
        : _results.values.reduce((a, b) =>
            a.rejected || a.failed ? a : (b.rejected || b.failed ? b : a));
    return r?.rejected == true || r?.failed == true
        ? Icons.error_outline
        : Icons.check_circle_outline;
  }

  Color _resultTextColor() {
    final r = _results.values.isEmpty
        ? null
        : _results.values.reduce((a, b) =>
            a.rejected || a.failed ? a : (b.rejected || b.failed ? b : a));
    return r?.rejected == true || r?.failed == true
        ? const Color(0xFFB71C1C)
        : const Color(0xFF1B5E20);
  }

  Widget _card({required Widget child, Color? color}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: child,
      );
}
