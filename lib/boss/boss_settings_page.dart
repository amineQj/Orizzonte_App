import 'package:flutter/material.dart';
import '../app_language.dart';
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

  double _parse(TextEditingController c, double fallback) {
    final v = double.tryParse(c.text.trim().replaceAll(',', ''));
    return v ?? fallback;
  }

  Future<void> _savePricing() async {
    final s = BossRepository.instance.settings;
    await BossRepository.instance.saveSettings(
      s.copyWith(
        baseRate: _parse(_baseRate, s.baseRate),
        premiumMarkup: _parse(_markup, s.premiumMarkup),
        minPrice: _parse(_minPrice, s.minPrice),
      ),
    );
    _toast(tr('Settings saved', 'تم حفظ الإعدادات', 'Réglages enregistrés'));
  }

  Future<void> _saveAccount() async {
    final s = BossRepository.instance.settings;
    await BossRepository.instance.saveSettings(
      s.copyWith(
        adminName: _name.text.trim().isEmpty ? s.adminName : _name.text.trim(),
        adminEmail: _email.text.trim().isEmpty
            ? s.adminEmail
            : _email.text.trim(),
      ),
    );
    _password.clear();
    _toast(tr('Account updated', 'تم تحديث الحساب', 'Compte mis à jour'));
  }

  void _signOut() {
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
          const SizedBox(height: 16),
          _card(
            title: tr(
              'Pricing Configuration',
              'تكوين الأسعار',
              'Configuration tarifaire',
            ),
            icon: Icons.attach_money,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        label: tr(
                          'Base Rate (DZD/km)',
                          'السعر الأساسي (دج/كم)',
                          'Tarif de base (DZD/km)',
                        ),
                        controller: _baseRate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        label: tr(
                          'Premium Markup (%)',
                          'الهامش المميز (٪)',
                          'Majoration premium (%)',
                        ),
                        controller: _markup,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _numberField(
                  label: tr(
                    'Min. Mission Price (DZD)',
                    'الحد الأدنى لسعر المهمة (دج)',
                    'Prix min. mission (DZD)',
                  ),
                  controller: _minPrice,
                ),
                const SizedBox(height: 18),
                _saveButton(
                  label: tr('Save Changes', 'حفظ التغييرات', 'Enregistrer'),
                  onTap: _savePricing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: tr('Admin Account', 'حساب المدير', 'Compte admin'),
            icon: Icons.admin_panel_settings_outlined,
            child: Column(
              children: [
                _textField(
                  label: tr('Full Name', 'الاسم الكامل', 'Nom complet'),
                  controller: _name,
                ),
                const SizedBox(height: 14),
                _textField(
                  label: tr('Email', 'البريد الإلكتروني', 'E-mail'),
                  controller: _email,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _textField(
                  label: tr(
                    'New Password',
                    'كلمة المرور الجديدة',
                    'Nouveau mot de passe',
                  ),
                  controller: _password,
                  obscure: true,
                  hint: tr(
                    'Leave blank to keep current',
                    'اتركه فارغاً للإبقاء عليه',
                    'Laissez vide pour conserver',
                  ),
                ),
                const SizedBox(height: 18),
                _saveButton(
                  label: tr('Update Account', 'تحديث الحساب', 'Mettre à jour'),
                  onTap: _saveAccount,
                ),
              ],
            ),
          ),
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

  Widget _fieldBase({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: pop(
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
  }) {
    return _fieldBase(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: pop(size: 13, color: const Color(0xFF111111)),
        decoration: _decoration(),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboard,
    bool obscure = false,
    String? hint,
  }) {
    return _fieldBase(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        style: pop(size: 13, color: const Color(0xFF111111)),
        decoration: _decoration(hint: hint),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: pop(size: 13, color: const Color(0xFFBBBBBB)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF5A524), width: 1.5),
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: pop(size: 13, color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
