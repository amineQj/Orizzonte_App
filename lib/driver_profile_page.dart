import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'app_language.dart';
import 'models/api_models.dart';
import 'notification/mission_notifications_page.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
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
        builder: (_) => _PersonalInfoPage(
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
        builder: (_) => _VerificationStatusPage(profile: profile, t: _t),
      ),
    );
  }
}

class _PersonalInfoPage extends StatefulWidget {
  final DriverProfile profile;
  final String Function(String, String, String) t;
  final void Function(DriverProfile) onSaved;
  const _PersonalInfoPage({
    required this.profile,
    required this.t,
    required this.onSaved,
  });

  @override
  State<_PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<_PersonalInfoPage> {
  final ApiService _api = ApiService();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
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
    _nationalId.text = _str(raw['national_id_number']);
    _license.text = _str(raw['driving_license_number']);
    _licenseExpiry.text = _str(raw['driving_license_expiry']);
    _plate.text = _str(raw['vehicle_plate']);
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
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
      final updated = await _api.updateDriverProfile({
        'full_name': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'national_id_number': _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
        'driving_license_number': _license.text.trim().isEmpty ? null : _license.text.trim(),
        'driving_license_expiry': _licenseExpiry.text.trim().isEmpty ? null : _licenseExpiry.text.trim(),
        'vehicle_plate': _plate.text.trim(),
      });
      widget.onSaved(updated);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = t('Saved successfully.', 'تم الحفظ بنجاح.', 'Enregistré.');
      });
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
            _field(_nationalId, t('National ID number', 'رقم الهوية', 'Numéro CNI'), Icons.badge_outlined),
            const SizedBox(height: 10),
            _field(_license, t('Driving license number', 'رقم رخصة القيادة', 'Numéro permis'), Icons.credit_card_outlined),
            const SizedBox(height: 10),
            _field(_licenseExpiry, t('License expiry (YYYY-MM-DD)', 'انتهاء الرخصة (YYYY-MM-DD)', 'Expiration permis (AAAA-MM-JJ)'), Icons.calendar_today_outlined),
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
  const _VerificationStatusPage({required this.profile, required this.t});

  @override
  State<_VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<_VerificationStatusPage> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  late DriverProfile _profile;
  bool _busy = false;
  String? _result;

  String Function(String, String, String) get t => widget.t;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  bool _uploaded(String slot) =>
      (_profile.documents[slot] as Map?)?['uploaded'] == true;

  Future<void> _upload(String slot) async {
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x == null) {
        setState(() => _busy = false);
        return;
      }
      final bytes = await x.readAsBytes();
      final updated = await _api.uploadDocument(slot, bytes, x.name);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _busy = false;
        _result = t('Uploaded. Running automatic check...', 'تم الرفع. جاري الفحص التلقائي...', 'Téléversé. Vérification automatique...');
      });
      await _check(slot, bytes, x.name);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _check(String slot, List<int> bytes, String filename) async {
    try {
      final taskId = await _api.checkDocument(slot, bytes, filename);
      if (taskId.isEmpty) return;
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await _api.getVerificationStatus(taskId);
        final s = status['status']?.toString();
        if (s == 'completed') {
          final decision = status['final_decision']?.toString() ?? '';
          final reasons = (status['reason_codes'] as List?)?.join(', ') ?? '';
          if (!mounted) return;
          setState(() {
            _busy = false;
            _result = '$decision${reasons.isEmpty ? '' : '  •  $reasons'}';
          });
          return;
        }
        if (s == 'failed') {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _result = status['detail']?.toString() ?? 'Verification failed';
          });
          return;
        }
      }
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final updated = await _api.submitDriverProfile();
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _busy = false;
        _result = t('Submitted for review.', 'تم الإرسال للمراجعة.', 'Soumis pour révision.');
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${t('Status', 'الحالة', 'Statut')}: ${_profile.status}',
                      style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF222222)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t('Documents', 'المستندات', 'Documents'),
                style: _pop(size: 15, weight: FontWeight.w700, color: const Color(0xFF111111))),
            const SizedBox(height: 10),
            ..._slots.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _card(
                  child: Row(
                    children: [
                      Icon(_uploaded(s.$1) ? Icons.check_circle : Icons.upload_file,
                          color: _uploaded(s.$1) ? const Color(0xFF4CAF50) : _amber),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t(s.$2, s.$3, s.$4), style: _pop(size: 13, color: const Color(0xFF333333)))),
                      GestureDetector(
                        onTap: _busy ? null : () => _upload(s.$1),
                        child: Text(t('Upload', 'رفع', 'Téléverser'),
                            style: _pop(size: 12, weight: FontWeight.w700, color: _amber)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              _card(child: Text(_result!, style: _pop(size: 13, color: const Color(0xFF333333)))),
            ],
            if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: _amber))),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _busy ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                    color: _busy ? const Color(0xFFCCCCCC) : _amber,
                    borderRadius: BorderRadius.circular(14)),
                child: Text(t('Submit for review', 'إرسال للمراجعة', 'Soumettre pour révision'),
                    textAlign: TextAlign.center,
                    style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: child,
      );
}
