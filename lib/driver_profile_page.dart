import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'notification/mission_notifications_page.dart';

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

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final int _verificationStatus =
      1; // 0 = not started, 1 = under review, 2 = verified

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
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildMenuButton(
            icon: Icons.person_outline,
            label: _t(
              'Personal Information',
              'المعلومات الشخصية',
              'Informations personnelles',
            ),
            subtitle: _t(
              'View and edit your profile',
              'عرض وتعديل ملفك الشخصnel',
              'Voir et modifier votre profil',
            ),
            color: const Color(0xFFF5A524),
            onTap: () => _showPersonalInfoPage(),
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            icon: Icons.verified_user_outlined,
            label: _t(
              'Account Verification',
              'تحقق الحساب',
              'Vérification du compte',
            ),
            subtitle: _verificationStatus == 2
                ? _t('Verified', 'موثق', 'Vérifié')
                : _verificationStatus == 1
                ? _t(
                    'Documents under review',
                    'المستندات قيد المراجعة',
                    'Documents en révision',
                  )
                : _t('Not verified yet', 'لم يتم التحقق بعد', 'Non vérifié'),
            color: _verificationStatus == 2
                ? const Color(0xFF4CAF50)
                : _verificationStatus == 1
                ? const Color(0xFF2196F3)
                : const Color(0xFFF5A524),
            onTap: () => _showVerificationPage(),
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            icon: Icons.language,
            label: _t('Language', 'اللغة', 'Langue'),
            subtitle: _lang == 'AR'
                ? 'العربية'
                : _lang == 'FR'
                ? 'Français'
                : 'English',
            color: const Color(0xFF2196F3),
            onTap: () => _showLanguageDialog(),
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            icon: Icons.notifications_none,
            label: _t(
              'Mission Notifications',
              'إشعارات المهام',
              'Notifications de mission',
            ),
            subtitle: _t(
              'Manage push notifications for new missions',
              'إدارة إشعارات المهام الجديدة',
              'Gérez les notifications des nouvelles missions',
            ),
            color: const Color(0xFFF5A524),
            onTap: () => _showMissionNotificationsPage(),
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A524), Color(0xFFF5A524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A524).withValues(alpha: 0.3),
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'AB',
                style: _pop(
                  size: 24,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ahmed Benali',
            style: _pop(size: 18, weight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'ahmed.benali@email.com',
            style: _pop(size: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
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
                  _verificationStatus == 2
                      ? Icons.verified
                      : _verificationStatus == 1
                      ? Icons.hourglass_top
                      : Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _verificationStatus == 2
                      ? _t('Verified', 'موثق', 'Vérifié')
                      : _verificationStatus == 1
                      ? _t('Under Review', 'قيد المراجعة', 'En révision')
                      : _t('Not Verified', 'غير موثق', 'Non vérifié'),
                  style: _pop(
                    size: 11,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
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
                  Text(
                    label,
                    style: _pop(
                      size: 14,
                      weight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _pop(size: 11, color: const Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: const Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.logout,
                    size: 32,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t('Logout', 'تسجيل الخروج', 'Déconnexion'),
                  style: _pop(
                    size: 16,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    'Are you sure you want to logout?',
                    'هل أنت متأكد من تسجيل الخروج؟',
                    'Êtes-vous sûr ?',
                  ),
                  textAlign: TextAlign.center,
                  style: _pop(size: 13, color: const Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              _t('Cancel', 'إلغاء', 'Annuler'),
                              style: _pop(
                                size: 14,
                                weight: FontWeight.w600,
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushReplacementNamed(
                            context,
                            '/onboarding',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              _t('Logout', 'خروج', 'Déconnexion'),
                              style: _pop(
                                size: 14,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              _t('Logout', 'تسجيل الخروج', 'Déconnexion'),
              style: _pop(
                size: 14,
                weight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t('Language', 'اللغة', 'Langue'),
          style: _pop(
            size: 17,
            weight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('English', 'EN', Icons.language),
            const SizedBox(height: 8),
            _languageOption('العربية', 'AR', Icons.language),
            const SizedBox(height: 8),
            _languageOption('Français', 'FR', Icons.language),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String label, String code, IconData icon) {
    final selected = _lang == code;
    return GestureDetector(
      onTap: () {
        appLanguage.setLang(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF5A524).withValues(alpha: 0.1)
              : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(0xFFF5A524)
                  : const Color(0xFF999999),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: _pop(
                size: 14,
                weight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: Color(0xFFF5A524),
              ),
          ],
        ),
      ),
    );
  }

  void _showPersonalInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PersonalInfoPage(lang: _lang, t: _t),
      ),
    );
  }

  void _showMissionNotificationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MissionNotificationsPage()),
    );
  }

  void _showVerificationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VerificationStatusPage(
          lang: _lang,
          t: _t,
          status: _verificationStatus,
        ),
      ),
    );
  }
}

class _PersonalInfoPage extends StatelessWidget {
  final String lang;
  final String Function(String, String, String) t;
  const _PersonalInfoPage({required this.lang, required this.t});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t(
            'Personal Information',
            'المعلومات الشخصية',
            'Informations personnelles',
          ),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5A524), Color(0xFFF5A524)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A524).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'AB',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Info cards
            _infoCard(
              Icons.person_outline,
              t('Full Name', 'الاسم الكامل', 'Nom complet'),
              'Ahmed Benali',
            ),
            const SizedBox(height: 10),
            _infoCard(
              Icons.email_outlined,
              t('Email', 'البريد الإلكتروني', 'Email'),
              'ahmed.benali@email.com',
            ),
            const SizedBox(height: 10),
            _infoCard(
              Icons.phone_outlined,
              t('Phone', 'الهاتف', 'Téléphone'),
              '+213 555 123 456',
            ),
            const SizedBox(height: 10),
            _infoCard(
              Icons.location_on_outlined,
              t('Address', 'العنوان', 'Adresse'),
              'Algiers, Algeria',
            ),
            const SizedBox(height: 10),
            _infoCard(
              Icons.local_shipping_outlined,
              t('Vehicle Type', 'نوع المركبة', 'Type de véhicule'),
              'Camion Large',
            ),
            const SizedBox(height: 10),
            _infoCard(
              Icons.calendar_today_outlined,
              t('Member Since', 'عضو منذ', 'Membre depuis'),
              'January 2025',
            ),
            const SizedBox(height: 10),
            _infoCard(
              Icons.star_outline,
              t('Rating', 'التقييم', 'Note'),
              '4.8 / 5.0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5A524).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFF5A524)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusPage extends StatelessWidget {
  final String lang;
  final String Function(String, String, String) t;
  final int status;
  const _VerificationStatusPage({
    required this.lang,
    required this.t,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color bannerColor;
    final IconData bannerIcon;
    final String bannerTitle;
    final String bannerSubtitle;

    if (status == 2) {
      bannerColor = const Color(0xFF4CAF50);
      bannerIcon = Icons.verified;
      bannerTitle = t('Account Verified', 'الحساب موثق', 'Compte vérifié');
      bannerSubtitle = t(
        'Your account is fully verified. You can accept all missions.',
        'حسابك موثق بالكامل. يمكنك قبول جميع المهام.',
        'Votre compte est vérifié.',
      );
    } else if (status == 1) {
      bannerColor = const Color(0xFF2196F3);
      bannerIcon = Icons.hourglass_top;
      bannerTitle = t(
        'Documents Under Review',
        'المستندات قيد المراجعة',
        'Documents en révision',
      );
      bannerSubtitle = t(
        'Your documents are being reviewed. This usually takes 24-48 hours.',
        'مستنداتك قيد المراجعة. يستغرق هذا عادة 24-48 ساعة.',
        'Vos documents sont en cours de révision.',
      );
    } else {
      bannerColor = const Color(0xFFF5A524);
      bannerIcon = Icons.warning_amber_rounded;
      bannerTitle = t('Not Verified', 'لم يتم التحقق', 'Non vérifié');
      bannerSubtitle = t(
        'Complete verification to start accepting missions.',
        'أكمل التحقق لتتمكن من قبول المهام.',
        'Complétez la vérification pour accepter des missions.',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('Account Verification', 'تحقق الحساب', 'Vérification du compte'),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bannerColor, bannerColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: bannerColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(bannerIcon, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    bannerTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bannerSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Document items
            _docItem(
              Icons.badge_outlined,
              t('Identity Card', 'بطاقة الهوية', 'Carte d\'identité'),
              status >= 1
                  ? t('Submitted', 'تم الإرسال', 'Soumis')
                  : t('Not submitted', 'لم يتم الإرسال', 'Non soumis'),
              status >= 1,
            ),
            const SizedBox(height: 10),
            _docItem(
              Icons.camera_alt_outlined,
              t('Selfie', 'السيلفي', 'Selfie'),
              status >= 1
                  ? t('Submitted', 'تم الإرسال', 'Soumis')
                  : t('Not submitted', 'لم يتم الإرسال', 'Non soumis'),
              status >= 1,
            ),
            const SizedBox(height: 10),
            _docItem(
              Icons.directions_car_outlined,
              t('Vehicle Registration', 'تسجيل المركبة', 'Immatriculation'),
              status >= 1
                  ? t('Submitted', 'تم الإرسال', 'Soumis')
                  : t('Not submitted', 'لم يتم الإرسال', 'Non soumis'),
              status >= 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _docItem(IconData icon, String title, String subtitle, bool done) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: done ? const Color(0xFF4CAF50) : const Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle : Icons.arrow_forward_ios,
            size: done ? 22 : 16,
            color: done ? const Color(0xFF4CAF50) : const Color(0xFFCCCCCC),
          ),
        ],
      ),
    );
  }
}
