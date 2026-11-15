import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'order_flow.dart';
import 'order_model.dart';
import 'route_time_screen.dart';

TextStyle _poppins({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

const _categories = <Map<String, String>>[
  {'en_name': 'House Moving & Personal Effects', 'en_desc': 'Residential and personal belongings', 'ar_name': 'نقل المنازل والمتعلقات الشخصية', 'ar_desc': 'الأثاث المنزلي والمتعلقات الشخصية', 'fr_name': 'Déménagement & Effets personnels', 'fr_desc': 'Résidentiel et objets personnels'},
  {'en_name': 'Commercial Merchandise', 'en_desc': 'Commercial and cargo freight', 'ar_name': 'البضائع التجارية', 'ar_desc': 'الشحن التجاري والبضائع', 'fr_name': 'Marchandises commerciales', 'fr_desc': 'Fret commercial et cargo'},
  {'en_name': 'Heavy Equipment', 'en_desc': 'Machinery and industrial equipment', 'ar_name': 'المعدات الثقيلة', 'ar_desc': 'الآلات والمعدات الصناعية', 'fr_name': 'Équipements lourds', 'fr_desc': 'Machines et équipements industriels'},
  {'en_name': 'Carbon & Chemicals', 'en_desc': 'Refined cargo / chemical products', 'ar_name': 'الكيماويات والمواد الخطرة', 'ar_desc': 'البضائع الكيميائية والمصفاة', 'fr_name': 'Carbone & Produits chimiques', 'fr_desc': 'Cargaison raffinée / produits chimiques'},
  {'en_name': 'Towing', 'en_desc': 'Vehicle towing and recovery', 'ar_name': 'خدمة السحب', 'ar_desc': 'سحب واسترداد المركبات', 'fr_name': 'Remorquage', 'fr_desc': 'Remorquage et récupération de véhicules'},
  {'en_name': 'Construction Materials', 'en_desc': 'Bulk building materials', 'ar_name': 'مواد البناء', 'ar_desc': 'مواد البناء بالجملة', 'fr_name': 'Matériaux de construction', 'fr_desc': 'Matériaux de chantier en vrac'},
  {'en_name': 'Water', 'en_desc': 'Water tankers and supply', 'ar_name': 'المياه', 'ar_desc': 'صهاريج المياه والتوريد', 'fr_name': 'Eau', 'fr_desc': 'Camions-citernes et approvisionnement'},
  {'en_name': 'Appliances', 'en_desc': 'Household and commercial appliances', 'ar_name': 'الأجهزة المنزلية', 'ar_desc': 'الأجهزة المنزلية والتجارية', 'fr_name': 'Appareils électroménagers', 'fr_desc': 'Appareils ménagers et commerciaux'},
];

const _categoryIds = [
  'house_moving', 'commercial', 'heavy_equipment', 'chemicals',
  'towing', 'construction', 'water', 'appliances',
];

/// Returns the localized display name for a category id.
///
/// Reuses the category catalogue already defined above so the customer mission
/// views show the same names as the category picker.
String categoryLabel(String id, String lang) {
  final idx = _categoryIds.indexOf(id);
  if (idx < 0 || idx >= _categories.length) return id;
  final c = _categories[idx];
  if (lang == 'AR') return c['ar_name'] ?? c['en_name'] ?? id;
  if (lang == 'FR') return c['fr_name'] ?? c['en_name'] ?? id;
  return c['en_name'] ?? id;
}

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key, this.onMissionConfirmed});

  /// Called with the confirmed [OrderData] once a mission is created.
  ///
  /// When provided, the mission is saved and the flow returns to the caller
  /// (the Customer shell). When null, the flow behaves as before.
  final void Function(OrderData data)? onMissionConfirmed;

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  int? _selected;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';
  bool get _isRtl => _isArabic;

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(_isArabic ? 'اختر اللغة' : _lang == 'FR' ? 'Choisir la langue' : 'Select Language',
              style: _poppins(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
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
      onTap: () { appLanguage.setLang(code); Navigator.pop(context); },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF), width: 1.5),
        ),
        child: Row(children: [
          Icon(Icons.language, size: 20, color: selected ? const Color(0xFFF5A524) : const Color(0xFF999999)),
          const SizedBox(width: 12),
          Text(label, style: _poppins(size: 14, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFFF5A524) : const Color(0xFF111111))),
          const Spacer(),
          if (selected) const Icon(Icons.check_circle, size: 20, color: Color(0xFFF5A524)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    final content = Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(topPad),
          Expanded(child: _buildBody()),
        ],
      ),
    );
    if (_isRtl) return Directionality(textDirection: TextDirection.rtl, child: content);
    return content;
  }

  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 14),
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
              width: 48, height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, width: 48, height: 48),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text('ORIZZONTE', style: _poppins(size: 13, weight: FontWeight.w800, color: const Color(0xFF111111), letterSpacing: -0.02)),
          ]),
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
                textDirection: TextDirection.ltr,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 12, color: Color(0xFF333333)),
                  const SizedBox(width: 5),
                  Text(_lang, style: _poppins(size: 11, weight: FontWeight.w600, color: const Color(0xFF333333), letterSpacing: 0.05)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF5A524).withValues(alpha: 0.2), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      _isRtl ? Icons.chevron_right : Icons.chevron_left,
                      size: 20,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(_t('Back', 'رجوع', 'Retour'),
                  style: _poppins(size: 13, weight: FontWeight.w600, color: const Color(0xFFF5A524))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(_t('What do you need to ship?', 'ماذا تريد أن تشحن؟', 'Que souhaitez-vous expédier ?'),
            textAlign: TextAlign.start,
            style: _poppins(size: 26, weight: FontWeight.w800, color: const Color(0xFF111111), height: 1.2, letterSpacing: -0.03)),
          const SizedBox(height: 10),
          Text(_t('Select the category for your cargo to find the right vehicle.', 'اختر فئة البضاعة للعثور على المركبة المناسبة.', 'Sélectionnez la catégorie de votre cargaison pour trouver le bon véhicule.'),
            textAlign: TextAlign.start,
            style: _poppins(size: 13, weight: FontWeight.w400, color: const Color(0xFF999999), height: 1.6)),
          const SizedBox(height: 24),
          ...List.generate(_categories.length, (i) => _buildCategoryCard(i)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _selectCategory(int i) {
    setState(() => _selected = i);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderFlow(
          categoryIndex: i,
          onBack: () => Navigator.pop(context),
          onNext: (data) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RouteTimeScreen(
                  orderData: data,
                  onBack: () => Navigator.pop(context),
                  onMissionConfirmed: widget.onMissionConfirmed,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(int i) {
    final cat = _categories[i];
    final active = _selected == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectCategory(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF5A524) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF), width: 1.5),
            boxShadow: [
              active
                ? BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 6))
                : BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: _categoryIcon(i, active)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t(cat['en_name'] as String, cat['ar_name'] as String, cat['fr_name'] as String),
                    textAlign: TextAlign.start,
                    style: _poppins(size: 14, weight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF111111), letterSpacing: -0.01, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(_t(cat['en_desc'] as String, cat['ar_desc'] as String, cat['fr_desc'] as String),
                    textAlign: TextAlign.start,
                    style: _poppins(size: 11, weight: FontWeight.w400, color: active ? Colors.white.withValues(alpha: 0.75) : const Color(0xFFAAAAAA))),
                ],
              )),
            ]),
        ),
      ),
    );
  }

  Widget _categoryIcon(int index, bool active) {
    if (index == 4) {
      return Image.asset(
        'assets/images/towing.png',
        width: 32,
        height: 32,
        fit: BoxFit.contain,
      );
    }
    const svgPaths = [
      'assets/images/housemouving.svg',
      'assets/images/commercial.svg',
      'assets/images/heavyequipments.svg',
      'assets/images/carbon.svg',
      '',
      'assets/images/constructions.svg',
      'assets/images/WATER.svg',
      'assets/images/appliances.svg',
    ];
    return SvgPicture.asset(
      svgPaths[index],
      width: 32,
      height: 32,
    );
  }
}
