import 'package:flutter/material.dart';
import '../app_language.dart';
import 'boss_repository.dart';
import 'boss_dashboard_page.dart';
import 'boss_drivers_page.dart';
import 'boss_requests_page.dart';
import 'boss_revenue_page.dart';
import 'boss_settings_page.dart';
import 'boss_ui.dart';

/// Mobile shell for the Boss/Admin dashboard.
///
/// Adapts the web sidebar into a bottom navigation bar:
/// Dashboard, Requests, Drivers, Revenue and Settings.
class BossShell extends StatefulWidget {
  const BossShell({super.key});

  @override
  State<BossShell> createState() => _BossShellState();
}

class _BossShellState extends State<BossShell> {
  int _tab = 0;

  String get _lang => appLanguage.lang;

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    BossRepository.instance.load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    final pages = [
      BossDashboardPage(onSeeAll: () => setState(() => _tab = 1)),
      const BossRequestsPage(),
      const BossDriversPage(),
      const BossRevenuePage(),
      const BossSettingsPage(),
    ];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: Column(
          children: [
            _buildHeader(topPad),
            Expanded(child: pages[_tab]),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  _buildNavItem(
                    0,
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    tr('Dashboard', 'الرئيسية', 'Tableau'),
                  ),
                  _buildNavItem(
                    1,
                    Icons.assignment_outlined,
                    Icons.assignment,
                    tr('Requests', 'الطلبات', 'Demandes'),
                  ),
                  _buildNavItem(
                    2,
                    Icons.local_shipping_outlined,
                    Icons.local_shipping,
                    tr('Drivers', 'السائقون', 'Chauffeurs'),
                  ),
                  _buildNavItem(
                    3,
                    Icons.payments_outlined,
                    Icons.payments,
                    tr('Revenue', 'الإيرادات', 'Revenus'),
                  ),
                  _buildNavItem(
                    4,
                    Icons.settings_outlined,
                    Icons.settings,
                    tr('Settings', 'الإعدادات', 'Réglages'),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORIZZONTE',
                    style: pop(
                      size: 13,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111111),
                      letterSpacing: -0.02,
                    ),
                  ),
                  Text(
                    tr('Boss Dashboard', 'لوحة الرئيس', 'Tableau de bord'),
                    style: pop(
                      size: 9,
                      weight: FontWeight.w600,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                ],
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
                    style: pop(
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
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFF7E6) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? filledIcon : outlineIcon,
                size: 21,
                color: active
                    ? const Color(0xFFF5A524)
                    : const Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pop(
                size: 9,
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

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildLanguageSheet(ctx),
    );
  }

  Widget _buildLanguageSheet(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30),
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
            tr('Select Language', 'اختر اللغة', 'Choisir la langue'),
            style: pop(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          _langOption(ctx, 'EN', 'English'),
          _langOption(ctx, 'AR', 'العربية'),
          _langOption(ctx, 'FR', 'Français'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _langOption(BuildContext ctx, String code, String label) {
    final selected = _lang == code;
    return InkWell(
      onTap: () {
        appLanguage.setLang(code);
        Navigator.pop(ctx);
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
              style: pop(
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
}
