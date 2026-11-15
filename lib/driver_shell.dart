import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'driver_home_page.dart';
import 'driver_missions_page.dart';
import 'driver_profile_page.dart';
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

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

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

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isArabic
                  ? 'اختر اللغة'
                  : _lang == 'FR'
                  ? 'Choisir la langue'
                  : 'Select Language',
              style: _pop(
                size: 16,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            _langOption('EN', 'English'),
            _langOption('AR', 'العربية'),
            _langOption('FR', 'Français'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _langOption(String code, String label) {
    final selected = _lang == code;
    return InkWell(
      onTap: () {
        appLanguage.setLang(code);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
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
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFFF5A524)
                    : const Color(0xFF111111),
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    final pages = [
      const DriverHomePage(),
      const DriverMissionsPage(),
      const DriverProfilePage(),
      const MissionNotificationsPage(embedded: true),
    ];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(topPad),
            Expanded(child: pages[_currentIndex]),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_outlined,
                    Icons.home,
                    _t('Home', 'الرئيسية', 'Accueil'),
                  ),
                  _buildNavItem(
                    1,
                    Icons.assignment_outlined,
                    Icons.assignment,
                    _t('Missions', 'المهام', 'Missions'),
                  ),
                  _buildNavItem(
                    2,
                    Icons.person_outline,
                    Icons.person,
                    _t('Profile', 'الملف', 'Profil'),
                  ),
                  _buildNavItem(
                    3,
                    Icons.notifications_none,
                    Icons.notifications,
                    _t('Notifications', 'الإشعارات', 'Notifications'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5A524).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'ORIZZONTE',
                style: _pop(
                  size: 13,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111111),
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showLanguageDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFECECEC), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    size: 12,
                    color: Color(0xFF333333),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _lang,
                    style: _pop(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF333333),
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final active = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFF7E6) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? filledIcon : outlineIcon,
                size: 22,
                color: active
                    ? const Color(0xFFF5A524)
                    : const Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: _pop(
                size: 10,
                weight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? const Color(0xFFF5A524)
                    : const Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
