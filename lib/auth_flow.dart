import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'models/api_models.dart';

const Map<String, String> _t = {
  'login': 'Welcome Back',
  'loginSub': 'Sign in to continue your journey',
  'email': 'Email Address',
  'password': 'Password',
  'rememberMe': 'Remember me',
  'forgot': 'Forgot Password?',
  'loginBtn': 'Sign In',
  'noAccount': "Don't have an account?",
  'signUpLink': 'Sign Up',
  'signup': 'Create Account',
  'signupSub': 'Join Orizzonte and move smarter',
  'firstName': 'First Name',
  'lastName': 'Last Name',
  'phone': 'Phone Number',
  'confirmPw': 'Confirm Password',
  'terms': 'I agree to the',
  'termsLink': 'Terms & Privacy Policy',
  'createBtn': 'Create Account',
  'hasAccount': 'Already have an account?',
  'loginLink': 'Sign In',
  'otpTitle': 'Verify Your Number',
  'otpSub': "We've sent a 6-digit code to your phone number.",
  'verifyBtn': 'Verify',
  'resend': 'Resend Code',
  'resendIn': 'Resend in',
  'forgotTitle': 'Reset Password',
  'forgotSub':
      'Enter your email or phone number and we will send you a reset code.',
  'emailOrPhone': 'Email or Phone Number',
  'continueBtn': 'Continue',
  'resetTitle': 'New Password',
  'resetSub': 'Create a strong password for your account.',
  'newPw': 'New Password',
  'confirmNewPw': 'Confirm Password',
  'resetBtn': 'Reset Password',
  'backToLogin': 'Back to Sign In',
  'pwWeak': 'Weak',
  'pwFair': 'Fair',
  'pwGood': 'Good',
  'pwStrong': 'Strong',
  'pwMismatch': 'Passwords do not match',
  'fieldRequired': 'This field is required',
  'invalidEmail': 'Enter a valid email address',
  'invalidPhone': 'Enter a valid phone number',
  'otpWrong': 'Incorrect code. Please try again.',
  's': 's',
  // FR
  'fr_login': 'Bon Retour',
  'fr_loginSub': 'Connectez-vous pour continuer',
  'fr_email': 'Adresse e-mail',
  'fr_password': 'Mot de passe',
  'fr_rememberMe': 'Se souvenir de moi',
  'fr_forgot': 'Mot de passe oublié ?',
  'fr_loginBtn': 'Se connecter',
  'fr_noAccount': 'Pas encore de compte ?',
  'fr_signUpLink': "S'inscrire",
  'fr_signup': 'Créer un compte',
  'fr_signupSub': 'Rejoignez Orizzonte et bougez plus intelligemment',
  'fr_firstName': 'Prénom',
  'fr_lastName': 'Nom de famille',
  'fr_phone': 'Numéro de téléphone',
  'fr_confirmPw': 'Confirmer le mot de passe',
  'fr_terms': "J'accepte les",
  'fr_termsLink': 'CGU & Politique de confidentialité',
  'fr_createBtn': 'Créer un compte',
  'fr_hasAccount': 'Déjà un compte ?',
  'fr_loginLink': 'Se connecter',
  'fr_otpTitle': 'Vérifiez votre numéro',
  'fr_otpSub':
      'Nous vous avons envoyé un code à 6 chiffres sur votre téléphone.',
  'fr_verifyBtn': 'Vérifier',
  'fr_resend': 'Renvoyer le code',
  'fr_resendIn': 'Renvoyer dans',
  'fr_forgotTitle': 'Réinitialiser',
  'fr_forgotSub':
      'Entrez votre e-mail ou numéro de téléphone pour recevoir un code.',
  'fr_emailOrPhone': 'E-mail ou numéro de téléphone',
  'fr_continueBtn': 'Continuer',
  'fr_resetTitle': 'Nouveau mot de passe',
  'fr_resetSub': 'Créez un mot de passe fort pour votre compte.',
  'fr_newPw': 'Nouveau mot de passe',
  'fr_confirmNewPw': 'Confirmer le mot de passe',
  'fr_resetBtn': 'Réinitialiser',
  'fr_backToLogin': 'Retour à la connexion',
  'fr_pwWeak': 'Faible',
  'fr_pwFair': 'Moyen',
  'fr_pwGood': 'Bien',
  'fr_pwStrong': 'Fort',
  'fr_pwMismatch': 'Les mots de passe ne correspondent pas',
  'fr_fieldRequired': 'Ce champ est requis',
  'fr_invalidEmail': 'Entrez une adresse e-mail valide',
  'fr_invalidPhone': 'Entrez un numéro de téléphone valide',
  'fr_otpWrong': 'Code incorrect. Veuillez réessayer.',
  'fr_s': 's',
  // AR
  'ar_login': 'مرحباً بعودتك',
  'ar_loginSub': 'سجّل الدخول لمتابعة رحلتك',
  'ar_email': 'البريد الإلكتروني',
  'ar_password': 'كلمة المرور',
  'ar_rememberMe': 'تذكّرني',
  'ar_forgot': 'نسيت كلمة المرور؟',
  'ar_loginBtn': 'تسجيل الدخول',
  'ar_noAccount': 'ليس لديك حساب؟',
  'ar_signUpLink': 'إنشاء حساب',
  'ar_signup': 'إنشاء حساب',
  'ar_signupSub': 'انضم إلى أوريزونتي وتنقّل بذكاء',
  'ar_firstName': 'الاسم الأول',
  'ar_lastName': 'اسم العائلة',
  'ar_phone': 'رقم الهاتف',
  'ar_confirmPw': 'تأكيد كلمة المرور',
  'ar_terms': 'أوافق على',
  'ar_termsLink': 'الشروط وسياسة الخصوصية',
  'ar_createBtn': 'إنشاء الحساب',
  'ar_hasAccount': 'لديك حساب بالفعل؟',
  'ar_loginLink': 'تسجيل الدخول',
  'ar_otpTitle': 'تحقّق من رقمك',
  'ar_otpSub': 'أرسلنا رمزاً مكوناً من 6 أرقام إلى هاتفك.',
  'ar_verifyBtn': 'تحقّق',
  'ar_resend': 'إعادة الإرسال',
  'ar_resendIn': 'إعادة الإرسال خلال',
  'ar_forgotTitle': 'إعادة تعيين كلمة المرور',
  'ar_forgotSub': 'أدخل بريدك الإلكتروني أو رقم هاتفك لتلقي رمز إعادة التعيين.',
  'ar_emailOrPhone': 'البريد الإلكتروني أو رقم الهاتف',
  'ar_continueBtn': 'متابعة',
  'ar_resetTitle': 'كلمة مرور جديدة',
  'ar_resetSub': 'أنشئ كلمة مرور قوية لحسابك.',
  'ar_newPw': 'كلمة مرور جديدة',
  'ar_confirmNewPw': 'تأكيد كلمة المرور',
  'ar_resetBtn': 'إعادة التعيين',
  'ar_backToLogin': 'العودة لتسجيل الدخول',
  'ar_pwWeak': 'ضعيفة',
  'ar_pwFair': 'متوسطة',
  'ar_pwGood': 'جيدة',
  'ar_pwStrong': 'قوية',
  'ar_pwMismatch': 'كلمتا المرور غير متطابقتين',
  'ar_fieldRequired': 'هذا الحقل مطلوب',
  'ar_invalidEmail': 'أدخل عنوان بريد إلكتروني صحيح',
  'ar_invalidPhone': 'أدخل رقم هاتف صحيح',
  'ar_otpWrong': 'الرمز غير صحيح. حاول مجدداً.',
  'ar_s': 'ث',
};

String _tr(String key) {
  final lang = appLanguage.lang;
  if (lang == 'AR') {
    return _t['ar_$key'] ?? _t[key] ?? key;
  }
  if (lang == 'FR') {
    return _t['fr_$key'] ?? _t[key] ?? key;
  }
  return _t[key] ?? key;
}

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

bool _isValidEmail(String v) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
bool _isValidPhone(String v) =>
    RegExp(r'^\d{7,14}$').hasMatch(v.replaceAll(RegExp(r'\s'), ''));

int _passwordStrength(String pw) {
  if (pw.isEmpty) {
    return 0;
  }
  int s = 0;
  if (pw.length >= 8) {
    s++;
  }
  if (RegExp(r'[A-Z]').hasMatch(pw)) {
    s++;
  }
  if (RegExp(r'[0-9]').hasMatch(pw)) {
    s++;
  }
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) {
    s++;
  }
  return s;
}

const _strengthColors = [
  Color(0xFFE8E8E8),
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFEAB308),
  Color(0xFF22C55E),
];

enum AuthScreen { login, signup, otp, forgot, reset }

enum OtpContext { verify, forgot }

class AuthFlow extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBossSuccess;
  final VoidCallback onBack;
  final String demoRole;
  const AuthFlow({
    super.key,
    required this.onSuccess,
    required this.onBossSuccess,
    required this.onBack,
    this.demoRole = 'client',
  });

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  AuthScreen _screen = AuthScreen.login;
  OtpContext _otpCtx = OtpContext.verify;
  bool _visible = true;

  bool get _isRtl => appLanguage.isRtl;

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
    if (mounted) {
      setState(() {});
    }
  }

  void _go(AuthScreen next, {OtpContext? ctx}) {
    setState(() {
      _visible = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _screen = next;
          if (ctx != null) {
            _otpCtx = ctx;
          }
          _visible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: const Duration(milliseconds: 220),
        child: Stack(
          children: [
            Positioned.fill(child: _buildScreen()),
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 12,
              right: 18,
              child: GestureDetector(
                onTap: _showLanguageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECECEC)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language,
                        size: 11,
                        color: Color(0xFF333333),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        appLanguage.lang,
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
            ),
          ],
        ),
      ),
    );

    final wrapped = Scaffold(backgroundColor: Colors.white, body: content);

    if (_isRtl) {
      return Directionality(textDirection: TextDirection.rtl, child: wrapped);
    }
    return wrapped;
  }

  Widget _buildScreen() {
    switch (_screen) {
      case AuthScreen.login:
        return LoginScreen(
          onLogin: widget.onSuccess,
          onBossSuccess: widget.onBossSuccess,
          onSignup: () => _go(AuthScreen.signup),
          onForgot: () => _go(AuthScreen.forgot),
          onBack: widget.onBack,
          demoRole: widget.demoRole,
        );
      case AuthScreen.signup:
        return SignupScreen(
          onNext: () => _go(AuthScreen.otp, ctx: OtpContext.verify),
          onLogin: () => _go(AuthScreen.login),
          onBack: () => _go(AuthScreen.login),
        );
      case AuthScreen.otp:
        return OtpScreen(
          onVerified: () {
            if (_otpCtx == OtpContext.verify) {
              widget.onSuccess();
            } else {
              _go(AuthScreen.reset);
            }
          },
          onBack: () {
            if (_otpCtx == OtpContext.verify) {
              _go(AuthScreen.signup);
            } else {
              _go(AuthScreen.forgot);
            }
          },
        );
      case AuthScreen.forgot:
        return ForgotScreen(
          onNext: () => _go(AuthScreen.otp, ctx: OtpContext.forgot),
          onBack: () => _go(AuthScreen.login),
        );
      case AuthScreen.reset:
        return ResetScreen(
          onDone: () => _go(AuthScreen.login),
          onBack: () => _go(AuthScreen.login),
        );
    }
  }

  void _showLanguageDialog() {
    final lang = appLanguage.lang;
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
              _tr('select_language'),
              style: _pop(
                size: 16,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            _langOption(lang, 'EN', 'English'),
            _langOption(
              lang,
              'AR',
              '\u0627\u0644\u0639\u0631\u0628\u064A\u0629',
            ),
            _langOption(lang, 'FR', 'Fran\u00e7ais'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _langOption(String current, String code, String label) {
    final selected = current == code;
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
}

/* ─── Shared Widgets ─── */

class _Field extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChange;
  final String? placeholder;
  final String error;
  final bool obscure;
  final Widget? right;
  const _Field({
    required this.label,
    required this.value,
    required this.onChange,
    this.placeholder,
    this.error = '',
    this.obscure = false,
    this.right,
  });
  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_Field old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = appLanguage.isRtl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: _pop(
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              TextField(
                controller: _ctrl,
                onChanged: widget.onChange,
                obscureText: widget.obscure,
                textAlign: TextAlign.start,
                style: _pop(size: 14, color: const Color(0xFF111111)),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: _pop(size: 14, color: const Color(0xFFBBBBBB)),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    right: widget.right != null ? 48 : 16,
                    top: 14,
                    bottom: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: widget.error.isNotEmpty
                          ? const Color(0xFFEF4444)
                          : _focused
                          ? const Color(0xFFF5A524)
                          : const Color(0xFFE8E8E8),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: widget.error.isNotEmpty
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE8E8E8),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFF5A524),
                      width: 1.5,
                    ),
                  ),
                ),
                onTap: () => setState(() => _focused = true),
                onEditingComplete: () => setState(() => _focused = false),
              ),
              if (widget.right != null)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: isRtl ? 14 : null,
                  right: isRtl ? null : 14,
                  child: Center(child: widget.right),
                ),
            ],
          ),
          if (widget.error.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.error,
              style: _pop(size: 11, color: const Color(0xFFEF4444)),
              textAlign: TextAlign.start,
            ),
          ],
        ],
      ),
    );
  }
}

class _PwField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChange;
  final String? placeholder;
  final String error;
  const _PwField({
    required this.label,
    required this.value,
    required this.onChange,
    this.placeholder,
    this.error = '',
  });
  @override
  State<_PwField> createState() => _PwFieldState();
}

class _PwFieldState extends State<_PwField> {
  bool _show = false;
  @override
  Widget build(BuildContext context) {
    return _Field(
      label: widget.label,
      value: widget.value,
      onChange: widget.onChange,
      placeholder: widget.placeholder,
      error: widget.error,
      obscure: !_show,
      right: GestureDetector(
        onTap: () => setState(() => _show = !_show),
        child: Icon(
          _show ? Icons.visibility_off : Icons.visibility,
          size: 18,
          color: const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final String pw;
  const _StrengthBar({required this.pw});
  @override
  Widget build(BuildContext context) {
    final s = _passwordStrength(pw);
    if (pw.isEmpty) {
      return const SizedBox.shrink();
    }
    final labels = [
      _tr('pwWeak'),
      _tr('pwWeak'),
      _tr('pwFair'),
      _tr('pwGood'),
      _tr('pwStrong'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < s ? _strengthColors[s] : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            labels[s],
            style: _pop(
              size: 11,
              weight: FontWeight.w600,
              color: _strengthColors[s],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onClick;
  final bool disabled;
  const _PrimaryBtn({
    required this.label,
    required this.onClick,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onClick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF0D49A) : const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(22),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFF5A524).withValues(alpha: 0.38),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: _pop(
              size: 15,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.01,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final VoidCallback? onBack;
  const _PageHeader({this.onBack});

  @override
  Widget build(BuildContext context) {
    final isRtl = appLanguage.isRtl;
    final topPad = MediaQuery.of(context).viewPadding.top;
    return SizedBox(
      height: 180 + topPad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180 + topPad,
            child: ClipPath(
              clipper: _AmberClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8941C), Color(0xFFF7B84B)],
                  ),
                ),
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              top: topPad + 18,
              left: 18,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 18,
                    textDirection: isRtl
                        ? TextDirection.ltr
                        : TextDirection.rtl,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 26,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    width: 130,
                    height: 130,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmberClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.quadraticBezierTo(w * 0.5, h - 70, 0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}

Widget _screenWrap({
  required BuildContext context,
  VoidCallback? onBack,
  required Widget child,
}) {
  return Column(
    children: [
      _PageHeader(onBack: onBack),
      const SizedBox(height: 32),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    ],
  );
}

/* ─── SCREENS ─── */

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onBossSuccess;
  final VoidCallback onSignup;
  final VoidCallback onForgot;
  final VoidCallback onBack;
  final String demoRole;
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onBossSuccess,
    required this.onSignup,
    required this.onForgot,
    required this.onBack,
    this.demoRole = 'client',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _pw = '';
  bool _remember = false;
  bool _touched = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLang);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLang);
    _scroll.dispose();
    super.dispose();
  }

  void _onLang() {
    if (mounted) {
      setState(() {});
    }
  }

  String? get _emailErr {
    if (!_touched) {
      return null;
    }
    if (_email.isEmpty) {
      return _tr('fieldRequired');
    }
    if (!_isValidEmail(_email)) {
      return _tr('invalidEmail');
    }
    return null;
  }

  String? get _pwErr {
    if (!_touched) {
      return null;
    }
    if (_pw.isEmpty) {
      return _tr('fieldRequired');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _screenWrap(
      context: context,
      onBack: widget.onBack,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Text(
            _tr('login'),
            textAlign: TextAlign.start,
            style: _pop(
              size: 26,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr('loginSub'),
            textAlign: TextAlign.start,
            style: _pop(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          _Field(
            label: _tr('email'),
            value: _email,
            onChange: (v) => _email = v,
            placeholder: 'you@example.com',
            error: _emailErr ?? '',
          ),
          _PwField(
            label: _tr('password'),
            value: _pw,
            onChange: (v) => _pw = v,
            placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            error: _pwErr ?? '',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _remember
                            ? const Color(0xFFF5A524)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _remember
                              ? const Color(0xFFF5A524)
                              : const Color(0xFFDDDDDD),
                          width: 2,
                        ),
                      ),
                      child: _remember
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tr('rememberMe'),
                      style: _pop(
                        size: 12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onForgot,
                child: Text(
                  _tr('forgot'),
                  style: _pop(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFFF5A524),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PrimaryBtn(
            label: _tr('loginBtn'),
            onClick: () async {
              setState(() => _touched = true);
              if (_emailErr == null &&
                  _pwErr == null &&
                  _email.isNotEmpty &&
                  _pw.isNotEmpty) {
                try {
                  final auth = AuthService();
                  final resp = await auth.login(_email.trim(), _pw);
                  if (resp.user.role == 'boss') {
                    widget.onBossSuccess();
                  } else {
                    widget.onLogin();
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sign in failed: ${apiErrorMessage(e)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFFE0533D),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: _pop(size: 13, color: const Color(0xFF999999)),
                children: [
                  TextSpan(text: '${_tr('noAccount')} '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: widget.onSignup,
                      child: Text(
                        _tr('signUpLink'),
                        style: _pop(
                          size: 13,
                          weight: FontWeight.w700,
                          color: const Color(0xFFF5A524),
                        ),
                      ),
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
}

class SignupScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onLogin;
  final VoidCallback onBack;
  const SignupScreen({
    super.key,
    required this.onNext,
    required this.onLogin,
    required this.onBack,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _first = '',
      _last = '',
      _email = '',
      _phone = '',
      _pw = '',
      _confirm = '';
  bool _agreed = false;
  bool _touched = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLang);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLang);
    _scroll.dispose();
    super.dispose();
  }

  void _onLang() {
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, String> get _errs {
    if (!_touched) {
      return {};
    }
    final e = <String, String>{};
    if (_first.trim().isEmpty) {
      e['first'] = _tr('fieldRequired');
    }
    if (_last.trim().isEmpty) {
      e['last'] = _tr('fieldRequired');
    }
    if (_email.isEmpty) {
      e['email'] = _tr('fieldRequired');
    } else if (!_isValidEmail(_email)) {
      e['email'] = _tr('invalidEmail');
    }
    if (_phone.isEmpty) {
      e['phone'] = _tr('fieldRequired');
    } else if (!_isValidPhone(_phone)) {
      e['phone'] = _tr('invalidPhone');
    }
    if (_pw.isEmpty) {
      e['pw'] = _tr('fieldRequired');
    }
    if (_confirm.isEmpty) {
      e['confirm'] = _tr('fieldRequired');
    } else if (_confirm != _pw) {
      e['confirm'] = _tr('pwMismatch');
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    final errs = _errs;
    return _screenWrap(
      context: context,
      onBack: widget.onBack,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Text(
            _tr('signup'),
            textAlign: TextAlign.start,
            style: _pop(
              size: 26,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr('signupSub'),
            textAlign: TextAlign.start,
            style: _pop(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: _tr('firstName'),
                  value: _first,
                  onChange: (v) => _first = v,
                  placeholder: 'Ali',
                  error: errs['first'] ?? '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: _tr('lastName'),
                  value: _last,
                  onChange: (v) => _last = v,
                  placeholder: 'Hassan',
                  error: errs['last'] ?? '',
                ),
              ),
            ],
          ),
          _Field(
            label: _tr('email'),
            value: _email,
            onChange: (v) => _email = v,
            placeholder: 'you@example.com',
            error: errs['email'] ?? '',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('phone'),
                  style: _pop(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    TextField(
                      controller: TextEditingController(text: _phone)
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _phone.length),
                        ),
                      onChanged: (v) => _phone = v,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.start,
                      style: _pop(size: 14, color: const Color(0xFF111111)),
                      decoration: InputDecoration(
                        hintText: '555 000 000',
                        hintStyle: _pop(
                          size: 14,
                          color: const Color(0xFFBBBBBB),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 14,
                          bottom: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8E8E8),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8E8E8),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if ((errs['phone'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    errs['phone']!,
                    style: _pop(size: 11, color: const Color(0xFFEF4444)),
                  ),
                ],
              ],
            ),
          ),
          _PwField(
            label: _tr('password'),
            value: _pw,
            onChange: (v) => _pw = v,
            placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            error: errs['pw'] ?? '',
          ),
          _StrengthBar(pw: _pw),
          _PwField(
            label: _tr('confirmPw'),
            value: _confirm,
            onChange: (v) => _confirm = v,
            placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            error: errs['confirm'] ?? '',
          ),
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: _agreed
                          ? const Color(0xFFF5A524)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreed
                            ? const Color(0xFFF5A524)
                            : const Color(0xFFDDDDDD),
                        width: 2,
                      ),
                    ),
                    child: _agreed
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: _pop(
                          size: 12,
                          color: const Color(0xFF666666),
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: '${_tr('terms')} '),
                          TextSpan(
                            text: _tr('termsLink'),
                            style: _pop(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFFF5A524),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _PrimaryBtn(
            label: _tr('createBtn'),
            onClick: () {
              setState(() => _touched = true);
              if (_errs.isEmpty && _agreed) {
                widget.onNext();
              }
            },
            disabled: !_agreed,
          ),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: _pop(size: 13, color: const Color(0xFF999999)),
                children: [
                  TextSpan(text: '${_tr('hasAccount')} '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: widget.onLogin,
                      child: Text(
                        _tr('loginLink'),
                        style: _pop(
                          size: 13,
                          weight: FontWeight.w700,
                          color: const Color(0xFFF5A524),
                        ),
                      ),
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
}

class OtpScreen extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback onBack;
  const OtpScreen({super.key, required this.onVerified, required this.onBack});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _seconds = 60;
  String _error = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLang);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    appLanguage.removeListener(_onLang);
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onLang() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _resend() {
    setState(() {
      _error = '';
      _seconds = 60;
    });
    for (final c in _controllers) {
      c.clear();
    }
    _startTimer();
    _nodes[0].requestFocus();
  }

  void _verify() {
    final code = _controllers.map((c) => c.text).join();
    if (code == '123456') {
      widget.onVerified();
    } else {
      setState(() => _error = _tr('otpWrong'));
      for (final c in _controllers) {
        c.clear();
      }
      _nodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = _controllers.every((c) => c.text.isNotEmpty);
    return _screenWrap(
      context: context,
      onBack: widget.onBack,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: Color(0xFFF5A524),
              ),
            ),
          ),
          Text(
            _tr('otpTitle'),
            textAlign: TextAlign.center,
            style: _pop(
              size: 24,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _tr('otpSub'),
            textAlign: TextAlign.center,
            style: _pop(size: 13, color: const Color(0xFF999999), height: 1.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Demo code: 123456',
            textAlign: TextAlign.center,
            style: _pop(size: 11, color: const Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (i) => Container(
                width: 46,
                height: 56,
                margin: EdgeInsets.only(right: i < 5 ? 10 : 0),
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: _pop(
                    size: 22,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _controllers[i].text.isNotEmpty
                        ? const Color(0xFFFFF7E6)
                        : const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _error.isNotEmpty
                            ? const Color(0xFFEF4444)
                            : _controllers[i].text.isNotEmpty
                            ? const Color(0xFFF5A524)
                            : const Color(0xFFE8E8E8),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _error.isNotEmpty
                            ? const Color(0xFFEF4444)
                            : _controllers[i].text.isNotEmpty
                            ? const Color(0xFFF5A524)
                            : const Color(0xFFE8E8E8),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFF5A524),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    if (v.isNotEmpty && i < 5) {
                      _nodes[i + 1].requestFocus();
                    }
                  },
                ),
              ),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: _pop(size: 12, color: const Color(0xFFEF4444)),
            ),
          ],
          const SizedBox(height: 28),
          _seconds > 0
              ? Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: _pop(size: 13, color: const Color(0xFF999999)),
                      children: [
                        TextSpan(text: '${_tr('resendIn')} '),
                        TextSpan(
                          text:
                              '${_seconds.toString().padLeft(2, '0')}${_tr('s')}',
                          style: _pop(
                            size: 13,
                            weight: FontWeight.w700,
                            color: const Color(0xFFF5A524),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: GestureDetector(
                    onTap: _resend,
                    child: Text(
                      _tr('resend'),
                      style: _pop(
                        size: 13,
                        weight: FontWeight.w700,
                        color: const Color(0xFFF5A524),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 28),
          _PrimaryBtn(
            label: _tr('verifyBtn'),
            onClick: _verify,
            disabled: !filled,
          ),
        ],
      ),
    );
  }
}

class ForgotScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ForgotScreen({super.key, required this.onNext, required this.onBack});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  String _value = '';
  String _error = '';
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLang);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _screenWrap(
      context: context,
      onBack: widget.onBack,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Text(
            _tr('forgotTitle'),
            textAlign: TextAlign.start,
            style: _pop(
              size: 26,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr('forgotSub'),
            textAlign: TextAlign.start,
            style: _pop(size: 13, color: const Color(0xFF999999), height: 1.6),
          ),
          const SizedBox(height: 32),
          _Field(
            label: _tr('emailOrPhone'),
            value: _value,
            onChange: (v) {
              _value = v;
              if (_touched) {
                setState(() => _error = '');
              }
            },
            placeholder: 'you@example.com',
            error: _touched ? _error : '',
          ),
          const SizedBox(height: 8),
          _PrimaryBtn(
            label: _tr('continueBtn'),
            onClick: () {
              setState(() {
                _touched = true;
              });
              if (_value.trim().isEmpty) {
                setState(() => _error = _tr('fieldRequired'));
                return;
              }
              if (!_isValidEmail(_value) && !_isValidPhone(_value)) {
                setState(() => _error = _tr('invalidEmail'));
                return;
              }
              widget.onNext();
            },
          ),
        ],
      ),
    );
  }
}

class ResetScreen extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onBack;
  const ResetScreen({super.key, required this.onDone, required this.onBack});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  String _pw = '';
  String _confirm = '';
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLang);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() {
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, String> get _errs {
    if (!_touched) {
      return {};
    }
    final e = <String, String>{};
    if (_pw.isEmpty) {
      e['pw'] = _tr('fieldRequired');
    }
    if (_confirm.isEmpty) {
      e['confirm'] = _tr('fieldRequired');
    } else if (_confirm != _pw) {
      e['confirm'] = _tr('pwMismatch');
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    final errs = _errs;
    return _screenWrap(
      context: context,
      onBack: widget.onBack,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Text(
            _tr('resetTitle'),
            textAlign: TextAlign.start,
            style: _pop(
              size: 26,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr('resetSub'),
            textAlign: TextAlign.start,
            style: _pop(size: 13, color: const Color(0xFF999999), height: 1.6),
          ),
          const SizedBox(height: 32),
          _PwField(
            label: _tr('newPw'),
            value: _pw,
            onChange: (v) => _pw = v,
            placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            error: errs['pw'] ?? '',
          ),
          _StrengthBar(pw: _pw),
          _PwField(
            label: _tr('confirmNewPw'),
            value: _confirm,
            onChange: (v) => _confirm = v,
            placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            error: errs['confirm'] ?? '',
          ),
          const SizedBox(height: 8),
          _PrimaryBtn(
            label: _tr('resetBtn'),
            onClick: () {
              setState(() => _touched = true);
              if (_errs.isEmpty && _pw.isNotEmpty) {
                widget.onDone();
              }
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: widget.onBack,
              child: Text(
                _tr('backToLogin'),
                style: _pop(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xFFF5A524),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
