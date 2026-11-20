import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'models/api_models.dart';
import 'negotiation/negotiation_page.dart';
import 'services/api_service.dart';
import 'services/driver_mission_filters.dart';
import 'services/driver_mission_store.dart';
import 'widgets/api_state.dart';
import 'verification_flow_screen.dart';

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

String _truckImage(String truckType, String truckSize) {
  final t = truckType.toLowerCase();
  final s = truckSize.toLowerCase();
  if (t == 'camion') {
    if (s == 'small') return 'assets/images/CAMION_SMALL.png';
    if (s == 'large') return 'assets/images/CAMION_LARGE.png';
    return 'assets/images/CAMION_GENERAL.png';
  }
  if (t == 'fourgon') {
    if (s == 'short') return 'assets/images/FOURGON_SHORT.png';
    if (s == 'medium') return 'assets/images/FOURGON_MEDIUM.png';
    if (s == 'long') return 'assets/images/FOURGON_LONG.png';
    return 'assets/images/FOURGON_GENERAL.png';
  }
  if (t == 'harbina') {
    if (s == 'short') return 'assets/images/HARBINA_SHORT.png';
    if (s == 'long') return 'assets/images/HARBINA_LONG.png';
    return 'assets/images/HARBINA_GENERAL.png';
  }
  return 'assets/images/truck.svg';
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final ApiService _api = ApiService();
  int _verified = 0;

  // Backed by GET /api/drivers/me/profile/ — the backend refuses mission
  // acceptance with `driver_not_approved` until this status is `approved`.
  String? _profileStatus;
  String? _profileReason;
  bool _profileLoading = true;
  String? _profileError;
  String? _acceptingId;
  String? _acceptError;
  Map<String, String>? _acceptErrorMission;
  DriverMissionFilters _filters = const DriverMissionFilters();

  bool get _isApproved => _profileStatus == 'approved';

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
    DriverMissionStore.instance.addListener(_onStoreChanged);
    DriverMissionStore.instance.load();
    _loadProfile();
  }

  /// Loads the live approval status so the UI can explain *why* acceptance is
  /// blocked instead of surfacing a bare 403 from the API.
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final profile = await _api.getDriverProfile();
      if (!mounted) return;
      setState(() {
        _profileStatus = profile.status;
        _profileReason = profile.rejectionReason;
        _profileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Keep the local verification banner as a fallback; the accept handler
        // still guards with the backend error if the profile cannot be read.
        _profileError = apiErrorMessage(e);
        _profileLoading = false;
      });
    }
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    DriverMissionStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onLangChanged() {
    setState(() {});
  }

  void _onStoreChanged() {
    setState(() {});
  }

  List<Map<String, String>> get _available => _filters.apply(
        DriverMissionStore.instance.availableMissions
            .map((m) => m.toMap())
            .toList(),
      );

  /// Explicit confirmation before a one-way mission acceptance (M22).
  Future<bool> _confirmAccept(Map<String, String> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t('Accept this mission?', 'قبول هذه المهمة؟', 'Accepter cette mission ?'),
          style: _pop(size: 16, weight: FontWeight.w700,
              color: const Color(0xFF111111)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow(_t('Client', 'العميل', 'Client'), m['client'] ?? ''),
            _confirmRow(_t('Pickup', 'الالتقاط', 'Départ'), m['from'] ?? ''),
            _confirmRow(_t('Drop-off', 'التسليم', 'Arrivée'), m['to'] ?? ''),
            _confirmRow(_t('Distance', 'المسافة', 'Distance'), m['dist'] ?? ''),
            _confirmRow(_t('Price', 'السعر', 'Prix'), m['price'] ?? ''),
            const SizedBox(height: 6),
            Text(
              _t('You will be assigned to this mission. The backend remains authoritative.',
                  'سيتم تعيينك لهذه المهمة. الخادم هو المرجع النهائي.',
                  'Vous serez assigné à cette mission. Le serveur reste autoritatif.'),
              style: _pop(size: 11, color: const Color(0xFF888888)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Cancel', 'إلغاء', 'Annuler'),
                style: _pop(size: 13, color: const Color(0xFF777777))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Accept', 'قبول', 'Accepter'),
                style: _pop(size: 13, weight: FontWeight.w700,
                    color: const Color(0xFFF5A524))),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Widget _confirmRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            style: _pop(size: 12, color: const Color(0xFF444444)),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      );

  /// POST /api/missions/{id}/accept/ through the store, with an explicit
  /// approval guard, per-mission loading state, exact backend errors and a
  /// backend refresh so the mission disappears from "Available" immediately.
  Future<void> _accept(Map<String, String> m) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final id = m['id'] ?? '';
    final missionId = int.tryParse(id);
    if (missionId == null) {
      final message = _t(
        'Demo mission — sign in to accept real missions.',
        'مهمة تجريبية — سجّل الدخول لقبول مهام حقيقية.',
        'Mission de démonstration — connectez-vous pour accepter.',
      );
      if (!context.mounted) return;
      setState(() => _acceptError = message);
      showApiError(context, message);
      return;
    }
    if (!_isApproved) {
      final status = _profileStatus ?? 'incomplete';
      final message = _t(
        'Your profile is not approved yet (status: $status). '
        'Complete verification and wait for the boss to approve it.',
        'لم تتم الموافقة على ملفك بعد (الحالة: $status). '
        'أكمل التحقق وانتظر موافقة المدير.',
        'Votre profil n\'est pas encore approuvé (statut : $status). '
        'Terminez la vérification et attendez l\'approbation.',
      );
      if (!context.mounted) return;
      setState(() => _acceptError = message);
      showApiError(context, message);
      return;
    }
    if (!mounted) return;
    if (!await _confirmAccept(m)) return;
    if (!mounted) return;
    setState(() {
      _acceptingId = id;
      _acceptError = null;
      _acceptErrorMission = null;
    });
    final ok = await DriverMissionStore.instance.acceptMission(id);
    if (!context.mounted) return;
    if (!ok) {
      final message = DriverMissionStore.instance.error ??
          _t('Could not accept the mission.', 'تعذر قبول المهمة.', 'Impossible d\'accepter la mission.');
      if (messenger != null) showApiErrorWithMessenger(messenger, message);
      setState(() {
        _acceptingId = null;
        _acceptError = message;
        _acceptErrorMission = m;
      });
      return;
    }
    setState(() => _acceptingId = null);
    // Re-fetch available + my missions so both lists are consistent.
    await DriverMissionStore.instance.load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('Mission accepted. Find it in My Missions.',
            'تم قبول المهمة. تجدها في مهامي.', 'Mission acceptée. Retrouvez-la dans Mes missions.')),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFF5A524),
      onRefresh: () async {
        await Future.wait([
          DriverMissionStore.instance.load(),
          _loadProfile(),
        ]);
      },
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_profileLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFF5A524),
              ),
            ),
          if (_profileStatus != null && !_isApproved) ...[
            _buildApprovalBanner(),
            const SizedBox(height: 16),
          ] else if (_profileStatus == null && _verified == 0) ...[
            _buildVerifyBanner(),
            const SizedBox(height: 16),
          ] else if (_profileStatus == null && _verified == 1) ...[
            _buildReviewBanner(),
            const SizedBox(height: 16),
          ],
          if (_profileError != null) ...[
            _buildProfileErrorBanner(),
            const SizedBox(height: 12),
          ],
          _buildQuickStats(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t(
                  'Available Missions',
                  'المهام المتاحة',
                  'Missions disponibles',
                ),
                style: _pop(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_available.length}',
                    style: _pop(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showFilterPage(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.tune,
                        size: 16,
                        color: _filters.isActive
                            ? const Color(0xFFF5A524)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMissionList(),
        ],
      ),
      ),
    );
  }

  Widget _buildMissionList() {
    final store = DriverMissionStore.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_acceptError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: Color(0xFFE0533D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _acceptError!,
                    style: _pop(size: 11, color: const Color(0xFFB71C1C)),
                  ),
                ),
                if (_acceptErrorMission != null && _isApproved)
                  GestureDetector(
                    onTap: _acceptingId != null
                        ? null
                        : () => _accept(_acceptErrorMission!),
                    child: Text(
                      _t('Retry', 'إعادة المحاولة', 'Réessayer'),
                      style: _pop(size: 11, weight: FontWeight.w700,
                          color: const Color(0xFFE0533D)),
                    ),
                  ),
              ],
            ),
          ),
        if (store.isLoading)
          const SizedBox(
            height: 180,
            child: ApiLoadingView(message: 'Loading available missions...'),
          )
        else if (store.error != null && _available.isEmpty)
          SizedBox(
            height: 260,
            child: ApiErrorView(
              message: store.error!,
              onRetry: () => store.retry(),
            ),
          )
        else if (_available.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _t('No available missions right now.',
                    'لا توجد مهام متاحة حالياً.',
                    'Aucune mission disponible.'),
                style: _pop(size: 13, color: const Color(0xFF999999)),
              ),
            ),
          )
        else
          Column(
            children: _available
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProfessionalCard(m),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  /// Explains the live backend approval state and offers a path to fix it.
  Widget _buildApprovalBanner() {
    final rejected = _profileStatus == 'rejected';
    final title = rejected
        ? _t('Profile rejected', 'تم رفض الملف', 'Profil refusé')
        : _profileStatus == 'pending_review'
            ? _t('Documents under review', 'المستندات قيد المراجعة', 'Documents en révision')
            : _t('Verify your account', 'وثّق حسابك', 'Vérifiez votre compte');
    final body = rejected
        ? (_profileReason ?? '').isNotEmpty
            ? '${_t('Reason', 'السبب', 'Motif')}: $_profileReason'
            : _t('Update your documents and resubmit.', 'حدّث مستنداتك وأعد الإرسال.', 'Mettez à jour vos documents et soumettez à nouveau.')
        : _t('Your profile is not approved yet. Complete verification and wait for the boss before accepting missions.',
            'لم تتم الموافقة على ملفك بعد. أكمل التحقق وانتظر المدير قبل قبول المهام.',
            'Votre profil n\'est pas encore approuvé. Terminez la vérification et attendez le patron avant d\'accepter des missions.');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rejected ? const Color(0xFFFFEBEE) : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rejected ? const Color(0xFFEF9A9A) : const Color(0xFFF5C86A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rejected ? Icons.error_outline : Icons.hourglass_top,
                size: 18,
                color: rejected ? const Color(0xFFE0533D) : const Color(0xFFB87600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: _pop(size: 13, weight: FontWeight.w700,
                        color: const Color(0xFF222222))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: _pop(size: 11, color: const Color(0xFF666666))),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VerificationFlowScreen(),
                ),
              );
              if (result == true && mounted) setState(() => _verified = 1);
              await _loadProfile();
            },
            child: Text(
              _t('Open verification', 'فتح التحقق', 'Ouvrir la vérification'),
              style: _pop(size: 12, weight: FontWeight.w700,
                  color: const Color(0xFFF5A524)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileErrorBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 16, color: Color(0xFFE0533D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_t('Could not load approval status', 'تعذر تحميل حالة الموافقة', 'Statut indisponible')}: $_profileError',
                style: _pop(size: 11, color: const Color(0xFFB71C1C)),
              ),
            ),
            GestureDetector(
              onTap: _loadProfile,
              child: Text(_t('Retry', 'إعادة', 'Réessayer'),
                  style: _pop(size: 11, weight: FontWeight.w700,
                      color: const Color(0xFFE0533D))),
            ),
          ],
        ),
      );

  Widget _buildVerifyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF5A524).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Verify your account',
                        'تحقق من حسابك',
                        'Vérifiez votre compte',
                      ),
                      style: _pop(
                        size: 15,
                        weight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        'Complete verification to start accepting missions.',
                        'أكمل التحقق لتتمكن من قبول المهام.',
                        'Complétez la vérification pour accepter des missions.',
                      ),
                      style: _pop(size: 12, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VerificationFlowScreen(),
                ),
              );
              if (result == true) {
                setState(() {
                  _verified = 1;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A524).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _t('Verify Account', 'تحقق من الحساب', 'Vérifier le compte'),
                textAlign: TextAlign.center,
                style: _pop(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.hourglass_top,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    'Documents under review',
                    'المستندات قيد المراجعة',
                    'Documents en cours de révision',
                  ),
                  style: _pop(
                    size: 15,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t(
                    'Your submitted documents are being reviewed. This usually takes 24-48 hours.',
                    'مستنداتك المرسلة قيد المراجعة. يستغرق هذا عادة 24-48 ساعة.',
                    'Vos documents sont en cours de révision. 24-48 heures.',
                  ),
                  style: _pop(size: 12, color: const Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final store = DriverMissionStore.instance;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _t('Available', 'متاح', 'Disponibles'),
            '${store.availableMissions.length}',
            Icons.assignment_outlined,
            const Color(0xFFF5A524),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            _t('In Progress', 'قيد التنفيذ', 'En cours'),
            '${store.inProgressMissions.length}',
            Icons.local_shipping_outlined,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            _t('Completed', 'مكتمل', 'Terminées'),
            '${store.completedMissions.length}',
            Icons.verified_outlined,
            const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: _pop(
              size: 24,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: _pop(size: 11, color: const Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard(Map<String, String> m) {
    final img = _truckImage(m['truck']!, m['size']!);
    final isSvg = img.endsWith('.svg');
    // No dead tap target: the only actions are the explicit buttons below.
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A524).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row 1: image LEFT, type + client RIGHT
            Row(
              children: [
                Container(
                  width: 80,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSvg
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(img, fit: BoxFit.contain),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(img, fit: BoxFit.contain),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${m['truck']} ${m['size']}',
                            style: _pop(
                              size: 14,
                              weight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _t('Available', 'متاح', 'Disponible'),
                              style: _pop(
                                size: 9,
                                weight: FontWeight.w700,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m['client']!,
                        style: _pop(size: 12, color: const Color(0xFF999999)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              m['from']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _pop(
                                size: 10,
                                weight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 10,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5A524),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              m['to']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _pop(
                                size: 10,
                                weight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: date, distance, price
            Row(
              children: [
                _metaChip(Icons.calendar_today_outlined, m['date']!),
                const SizedBox(width: 12),
                _metaChip(Icons.straighten, m['dist']!),
                const Spacer(),
                Text(
                  m['price']!,
                  style: _pop(
                    size: 13,
                    weight: FontWeight.w800,
                    color: const Color(0xFFF5A524),
                  ),
                ),
              ],
            ),
            if (m['negotiable'] == 'true') ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final id = int.tryParse(m['id']!);
                  if (id == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NegotiationPage(missionId: id, role: 'driver'),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF5A524)),
                  ),
                  child: Text(
                    _t('Propose a price', 'اقترح سعراً', 'Proposer un prix'),
                    textAlign: TextAlign.center,
                    style: _pop(
                      size: 12,
                      weight: FontWeight.w700,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Row 3: action button — guarded by live approval status.
            GestureDetector(
              onTap: _acceptingId != null ? null : () => _accept(m),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _acceptingId == m['id']
                      ? const Color(0xFFE0A93B)
                      : _isApproved
                          ? const Color(0xFFF5A524)
                          : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A524).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _acceptingId == m['id']
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _t('Accepting...', 'جارٍ القبول...', 'Acceptation...'),
                            style: _pop(size: 12, weight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        _t('Accept Mission', 'قبول المهمة', 'Accepter la mission'),
                        textAlign: TextAlign.center,
                        style: _pop(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFBBBBBB)),
        const SizedBox(width: 4),
        Text(text, style: _pop(size: 11, color: const Color(0xFF777777))),
      ],
    );
  }

  Future<void> _showFilterPage() async {
    String vehicleType = _filters.vehicleType;
    String priceRange = _filters.priceRange;
    String distanceRange = _filters.distanceRange;
    String sortBy = _filters.sortBy;

    final applied = await showModalBottomSheet<DriverMissionFilters>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t('Filters', 'الفلاتر', 'Filtres'),
                        style: _pop(
                          size: 20,
                          weight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setModalState(() {
                          vehicleType = 'All';
                          priceRange = 'All';
                          distanceRange = 'All';
                          sortBy = 'Date';
                        }),
                        child: Text(
                          _t('Reset', 'إعادة', 'Réinitialiser'),
                          style: _pop(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFFF5A524),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(
                    _t('Vehicle Type', 'نوع المركبة', 'Type de véhicule'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Camion', 'Fourgon', 'Harbina'].map((t) {
                      final sel = vehicleType == t;
                      return GestureDetector(
                        onTap: () => setModalState(() => vehicleType = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFF5A524)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFF5A524)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Text(
                            t == 'All' ? _t('All', 'الكل', 'Toutes') : t,
                            style: _pop(
                              size: 12,
                              weight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(
                    _t('Price Range', 'نطاق السعر', 'Fourchette de prix'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'All',
                          '< 10,000',
                          '10,000 - 15,000',
                          '15,000 - 20,000',
                          '> 20,000',
                        ].map((p) {
                          final sel = priceRange == p;
                          return GestureDetector(
                            onTap: () => setModalState(() => priceRange = p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFFF5A524)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFFF5A524)
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Text(
                                p == 'All'
                                    ? _t('All', 'الكل', 'Toutes')
                                    : '$p DZD',
                                style: _pop(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(_t('Distance', 'المسافة', 'Distance')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'All',
                          '< 200 km',
                          '200 - 400 km',
                          '400 - 600 km',
                          '> 600 km',
                        ].map((d) {
                          final sel = distanceRange == d;
                          return GestureDetector(
                            onTap: () => setModalState(() => distanceRange = d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFFF5A524)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFFF5A524)
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Text(
                                d == 'All' ? _t('All', 'الكل', 'Toutes') : d,
                                style: _pop(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(_t('Sort By', 'ترتيب حسب', 'Trier par')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Date', 'Price ↑', 'Price ↓', 'Distance'].map((
                      s,
                    ) {
                      final sel = sortBy == s;
                      return GestureDetector(
                        onTap: () => setModalState(() => sortBy = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFF5A524)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFF5A524)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Text(
                            s,
                            style: _pop(
                              size: 11,
                              weight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(
                      context,
                      DriverMissionFilters(
                        vehicleType: vehicleType,
                        priceRange: priceRange,
                        distanceRange: distanceRange,
                        sortBy: sortBy,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A524),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF5A524,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _t('Apply Filters', 'تطبيق الفلاتر', 'Appliquer'),
                        textAlign: TextAlign.center,
                        style: _pop(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (applied != null && mounted) {
      setState(() => _filters = applied);
    }
  }

  Widget _filterSectionTitle(String title) {
    return Text(
      title,
      style: _pop(
        size: 14,
        weight: FontWeight.w700,
        color: const Color(0xFF111111),
      ),
    );
  }
}
