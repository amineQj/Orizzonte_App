import 'package:flutter/material.dart';
import '../app_language.dart';
import '../screens/boss_pricing_screen.dart';
import '../services/auth_session.dart';
import 'boss_repository.dart';
import 'boss_ui.dart';

/// Settings tab: pricing configuration, admin account and sign out.
class BossSettingsPage extends StatefulWidget {
  const BossSettingsPage({super.key});

  @override
  State<BossSettingsPage> createState() => _BossSettingsPageState();
}

class _BossSettingsPageState extends State<BossSettingsPage> {
  late final TextEditingController _baseRate;
  late final TextEditingController _markup;
  late final TextEditingController _minPrice;
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    final s = BossRepository.instance.settings;
    _baseRate = TextEditingController(text: _num(s.baseRate));
    _markup = TextEditingController(text: _num(s.premiumMarkup));
    _minPrice = TextEditingController(text: _num(s.minPrice));
    _name = TextEditingController(text: s.adminName);
    _email = TextEditingController(text: s.adminEmail);
    _password = TextEditingController(text: '');
    appLanguage.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    _baseRate.dispose();
    _markup.dispose();
    _minPrice.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  String _num(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  void _signOut() async {
    await AuthSession.instance.clear();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Settings', 'الإعدادات', 'Réglages'),
            style: pop(
              size: 18,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Configure platform parameters.',
              'اضبط معايير المنصة.',
              'Configurez les paramètres de la plateforme.',
            ),
            style: pop(size: 12, color: const Color(0xFF999999)),
          ),
          if (AuthSession.instance.isBoss()) ...[
            _card(
              title: tr(
                'Backend Pricing Config (API)',
                'إعدادات التسعير (واجهة برمجة التطبيقات)',
                'Config tarifaire backend (API)',
              ),
              icon: Icons.cloud_sync_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      'Fetch and update live pricing parameters from the server. Password confirmation is required when saving.',
                      'جلب وتحديث معايير التسعير المباشرة من الخادم. يلزم تأكيد كلمة المرور عند الحفظ.',
                      'Récupérez et mettez à jour les paramètres tarifaires depuis le serveur. Confirmation par mot de passe requise.',
                    ),
                    style: pop(size: 12, color: const Color(0xFF666666), height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  _saveButton(
                    label: tr(
                      'Open Pricing Configuration',
                      'فتح إعدادات التسعير',
                      'Ouvrir la configuration tarifaire',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BossPricingScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ],
            const SizedBox(height: 20),
          GestureDetector(
            onTap: _signOut,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, size: 18, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text(
                    tr('Sign Out', 'تسجيل الخروج', 'Déconnexion'),
                    style: pop(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
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

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFF5A524)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: pop(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _saveButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A524).withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: pop(size: 13, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

}
