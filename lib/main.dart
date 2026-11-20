import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'auth_flow.dart';
import 'boss/boss_shell.dart';
import 'customer/customer_shell.dart';
import 'driver_shell.dart';
import 'services/api_service.dart' show ApiConfig;
import 'services/auth_service.dart';
import 'services/auth_session.dart';
import 'splash_screen.dart';

const _slides = [
  'https://images.unsplash.com/photo-1766785368863-f2188a8c8b32?w=800&h=1000&fit=crop&auto=format',
  'https://images.unsplash.com/photo-1614976523626-d598aafd4fda?w=800&h=1000&fit=crop&auto=format',
  'https://images.unsplash.com/photo-1778629794381-d3ae4a54311c?w=800&h=1000&fit=crop&auto=format',
  'https://images.unsplash.com/photo-1696592783645-33e966c4c274?w=800&h=1000&fit=crop&auto=format',
  'https://images.unsplash.com/photo-1758429551604-885ca2c55ddd?w=800&h=1000&fit=crop&auto=format',
  'https://images.unsplash.com/photo-1655478157959-3fcfc543c1a2?w=800&h=1000&fit=crop&auto=format',
];

const Map<String, String> _translations = {
  // tags
  'we_pack': 'WE PACK',
  'we_care': 'WE CARE',
  'we_deliver': 'WE DELIVER',
  // headline
  'headline_line1': 'Moving your world',
  'headline_line2a': 'with ',
  'headline_line2b': 'care',
  'headline_line2c': ' and',
  'headline_line3a': 'precision',
  'headline_line3b': '.',
  // subtitle
  'subtitle':
      'The logistics platform connecting customers and verified carriers — fast, reliable, nationwide.',
  // buttons
  'customer_title': "I'm a Customer",
  'customer_subtitle': 'Get a quote for your shipment',
  'driver_title': "I'm a Driver",
  'driver_subtitle': 'Register as a carrier and start earning',
  // terms
  'terms1': 'By continuing you agree to our ',
  'terms_tos': 'Terms of Service',
  'terms_and': ' & ',
  'terms_pp': 'Privacy Policy',
  // lang dialog
  'select_language': 'Select Language',
  // lang labels
  'lang_en': 'English',
  'lang_ar': 'العربية',
  'lang_fr': 'Français',
  // arabic translations
  'ar_we_pack': 'نُنقّل',
  'ar_we_care': 'نَرعى',
  'ar_we_deliver': 'نُوصّل',
  'ar_headline_line1': 'نحرّك عالمك',
  'ar_headline_line2a': 'بـ',
  'ar_headline_line2b': 'عناية',
  'ar_headline_line2c': ' و',
  'ar_headline_line3a': 'دقة',
  'ar_headline_line3b': '.',
  'ar_subtitle':
      'منصة اللوجستيات التي تربط العملاء والناقلين المعتمدين — سريعة وموثوقة على مستوى الوطن.',
  'ar_customer_title': 'أنا عميل',
  'ar_customer_subtitle': 'احصل على عرض سعر لشحنتك',
  'ar_driver_title': 'أنا سائق',
  'ar_driver_subtitle': 'سجّل كناقل وابدأ الأرباح',
  'ar_terms1': 'بالمتابعة أنت توافق على ',
  'ar_terms_tos': 'شروط الخدمة',
  'ar_terms_and': ' و',
  'ar_terms_pp': 'سياسة الخصوصية',
  // french translations
  'fr_we_pack': 'NOUS EMBALLONS',
  'fr_we_care': 'NOUS PRENONS SOIN',
  'fr_we_deliver': 'NOUS LIVRONS',
  'fr_headline_line1': 'Déplacer votre monde',
  'fr_headline_line2a': 'avec ',
  'fr_headline_line2b': 'soin',
  'fr_headline_line2c': ' et',
  'fr_headline_line3a': 'précision',
  'fr_headline_line3b': '.',
  'fr_subtitle':
      'La plateforme logistique reliant les clients et les transporteurs vérifiés — rapide, fiable, nationale.',
  'fr_customer_title': 'Je suis Client',
  'fr_customer_subtitle': 'Obtenez un devis pour votre envoi',
  'fr_driver_title': 'Je suis Chauffeur',
  'fr_driver_subtitle':
      'Inscrivez-vous comme transporteur et commencez à gagner',
  'fr_terms1': 'En continuant, vous acceptez nos ',
  'fr_terms_tos': 'Conditions d\'utilisation',
  'fr_terms_and': ' et notre ',
  'fr_terms_pp': 'Politique de confidentialité',
};

TextStyle _poppins({
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fail fast on a misconfigured release build instead of at first request.
  ApiConfig.validate();
  await AuthSession.instance.load();
  // Register the single 401 → refresh-token handler for the whole app,
  // including sessions restored from storage on a cold start.
  AuthService.instance;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await appLanguage.load();
  runApp(const MyApp());
}

Locale _localeFor(String lang) {
  switch (lang) {
    case 'AR':
      return const Locale('ar');
    case 'FR':
      return const Locale('fr');
    default:
      return const Locale('en');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguage,
      builder: (context, _) {
        return MaterialApp(
      title: 'Orizzonte',
      debugShowCheckedModeBanner: false,
      locale: _localeFor(appLanguage.lang),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
      ],
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
      },
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _current = 0;
  Timer? _timer;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';
  bool get _isFrench => _lang == 'FR';
  bool get _isRtl => _isArabic;

  String _t(String key) {
    if (_isArabic) return _translations['ar_$key'] ?? _translations[key] ?? key;
    if (_isFrench) return _translations['fr_$key'] ?? _translations[key] ?? key;
    return _translations[key] ?? key;
  }

  /// Routing is driven by the role returned from `/api/token/`, never by the
  /// onboarding tile the user tapped.
  Future<void> _handleAuthSuccess() async {
    final role = AuthSession.instance.role;
    final Widget shell;
    switch (role) {
      case 'client':
        shell = const CustomerShell();
        break;
      case 'driver':
        shell = const DriverShell();
        break;
      case 'boss':
        shell = const BossShell();
        break;
      default:
        await AuthService.instance.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                role == null
                    ? 'Sign-in did not return a role. Please try again.'
                    : 'Unknown account role: $role. Please contact support.',
              ),
              backgroundColor: const Color(0xFFE0533D),
            ),
          );
        }
        return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => shell),
    );
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      _goTo((_current + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  void _goTo(int index) {
    if (mounted) {
      setState(() {
        _current = index;
      });
    }
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
              _t('select_language'),
              style: _poppins(
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
              style: _poppins(
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
    final screenH = MediaQuery.of(context).size.height;
    final content = Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 60,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: screenH * 0.55, child: _buildCarousel()),
              Expanded(child: _buildBottomPanel()),
            ],
          ),
        ),
      ),
    );
    if (_isRtl) {
      return Directionality(textDirection: TextDirection.rtl, child: content);
    }
    return content;
  }

  Widget _buildCarousel() {
    final topPad = MediaQuery.of(context).viewPadding.top;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: Image.network(
            _slides[_current],
            key: ValueKey(_current),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x59000000),
                  Colors.transparent,
                  Color(0x8CFFFFFF),
                  Colors.white,
                ],
                stops: [0.0, 0.45, 0.82, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: topPad + 16,
          right: 20,
          child: GestureDetector(
            onTap: _showLanguageDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    size: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _lang,
                    style: _poppins(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: topPad + 16,
          left: 20,
          child: Row(
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
                style:
                    _poppins(
                      size: 18,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.04,
                    ).copyWith(
                      shadows: [
                        const Shadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _current
                      ? const Color(0xFFF5A524)
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tag(_t('we_pack')),
              _dot(),
              _tag(_t('we_care')),
              _dot(),
              _tag(_t('we_deliver')),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeadline(),
          const SizedBox(height: 12),
          Text(
            _t('subtitle'),
            style: _poppins(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFF999999),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          _customerButton(),
          const SizedBox(height: 16),
          _driverButton(),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: _poppins(
                  size: 11,
                  weight: FontWeight.w400,
                  color: const Color(0xFFC8C8C8),
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: _t('terms1')),
                  TextSpan(
                    text: _t('terms_tos'),
                    style: _poppins(
                      size: 11,
                      weight: FontWeight.w500,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                  TextSpan(text: _t('terms_and')),
                  TextSpan(
                    text: _t('terms_pp'),
                    style: _poppins(
                      size: 11,
                      weight: FontWeight.w500,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (_isRtl) {
      return Directionality(textDirection: TextDirection.rtl, child: content);
    }
    return content;
  }

  Widget _buildHeadline() {
    return RichText(
      text: TextSpan(
        style: _poppins(
          size: 26,
          weight: FontWeight.w800,
          color: const Color(0xFF111111),
          height: 1.15,
          letterSpacing: -0.03,
        ),
        children: [
          TextSpan(text: _t('headline_line1')),
          const TextSpan(text: '\n'),
          TextSpan(text: _t('headline_line2a')),
          TextSpan(
            text: _t('headline_line2b'),
            style: _poppins(
              size: 26,
              weight: FontWeight.w800,
              color: const Color(0xFFF5A524),
              height: 1.15,
              letterSpacing: -0.03,
            ),
          ),
          TextSpan(text: _t('headline_line2c')),
          const TextSpan(text: '\n'),
          TextSpan(
            text: _t('headline_line3a'),
            style: _poppins(
              size: 26,
              weight: FontWeight.w800,
              color: const Color(0xFFF5A524),
              height: 1.15,
              letterSpacing: -0.03,
            ),
          ),
          TextSpan(text: _t('headline_line3b')),
        ],
      ),
    );
  }

  Widget _tag(String text) => Text(
    text.toUpperCase(),
    style: _poppins(
      size: 10,
      weight: FontWeight.w600,
      color: const Color(0xFFF5A524),
      letterSpacing: 0.08,
    ),
  );

  Widget _dot() => Container(
    width: 3,
    height: 3,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xFFF5A524),
      shape: BoxShape.circle,
    ),
  );

  Widget _customerButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuthFlow(
              demoRole: 'client',
              onBack: () => Navigator.pop(context),
              onSuccess: _handleAuthSuccess,
              onBossSuccess: _handleAuthSuccess,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A524).withValues(alpha: 0.40),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('customer_title'),
                    style: _poppins(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _t('customer_subtitle'),
                    style: _poppins(
                      size: 11,
                      weight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuthFlow(
              demoRole: 'driver',
              onBack: () => Navigator.pop(context),
              onSuccess: _handleAuthSuccess,
              onBossSuccess: _handleAuthSuccess,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Color(0xFFF5A524),
                size: 21,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('driver_title'),
                    style: _poppins(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF111111),
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _t('driver_subtitle'),
                    style: _poppins(
                      size: 11,
                      weight: FontWeight.w400,
                      color: const Color(0xFFABABAB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }
}
