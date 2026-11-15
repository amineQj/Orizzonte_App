import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'order_model.dart';

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

const _categoryIds = [
  'house_moving',
  'commercial',
  'heavy_equipment',
  'chemicals',
  'towing',
  'construction',
  'water',
  'appliances',
];

const _truckTypesByCategory = <int, List<Map<String, String>>>{
  0: [
    {
      'id': 'fourgon',
      'img': 'assets/images/FOURGON_GENERAL.png',
      'en': 'Fourgon',
      'ar': 'فوروغون',
      'fr': 'Fourgon',
    },
    {
      'id': 'harbina',
      'img': 'assets/images/HARBINA_GENERAL.png',
      'en': 'Harbina',
      'ar': 'هاربينا',
      'fr': 'Harbina',
    },
    {
      'id': 'camion',
      'img': 'assets/images/CAMION_GENERAL.png',
      'en': 'Camion',
      'ar': 'كاميون',
      'fr': 'Camion',
    },
    {
      'id': 'commercial',
      'img': 'assets/images/COMMERCIAL_GENERAL.png',
      'en': 'Commercial',
      'ar': 'تجاري',
      'fr': 'Commercial',
    },
  ],
  1: [
    {
      'id': 'fourgon',
      'img': 'assets/images/FOURGON_GENERAL.png',
      'en': 'Fourgon',
      'ar': 'فوروغون',
      'fr': 'Fourgon',
    },
    {
      'id': 'harbina',
      'img': 'assets/images/HARBINA_GENERAL.png',
      'en': 'Harbina',
      'ar': 'هاربينا',
      'fr': 'Harbina',
    },
    {
      'id': 'camion',
      'img': 'assets/images/CAMION_GENERAL.png',
      'en': 'Camion',
      'ar': 'كاميون',
      'fr': 'Camion',
    },
    {
      'id': 'commercial',
      'img': 'assets/images/COMMERCIAL_GENERAL.png',
      'en': 'Commercial',
      'ar': 'تجاري',
      'fr': 'Commercial',
    },
  ],
  2: [
    {
      'id': 'camion',
      'img': 'assets/images/CAMION_GENERAL.png',
      'en': 'Camion',
      'ar': 'كاميون',
      'fr': 'Camion',
    },
  ],
  3: [
    {
      'id': 'camion-citerne',
      'img': 'assets/images/CAMION_CITERNE.png',
      'en': 'Camion-Citerne',
      'ar': 'كاميون صهريج',
      'fr': 'Camion-Citerne',
    },
  ],
  4: [
    {
      'id': 'porte-chare',
      'img': 'assets/images/PORTE_CHARE.png',
      'en': 'Porte Chare',
      'ar': 'بورت شار',
      'fr': 'Porte Chare',
    },
    {
      'id': 'depannage',
      'img': 'assets/images/DEPANNAGE.png',
      'en': 'Depannage',
      'ar': 'ديباناج',
      'fr': 'Depannage',
    },
  ],
  5: [
    {
      'id': 'fourgon',
      'img': 'assets/images/FOURGON_GENERAL.png',
      'en': 'Fourgon',
      'ar': 'فوروغون',
      'fr': 'Fourgon',
    },
    {
      'id': 'harbina',
      'img': 'assets/images/HARBINA_GENERAL.png',
      'en': 'Harbina',
      'ar': 'هاربينا',
      'fr': 'Harbina',
    },
    {
      'id': 'camion',
      'img': 'assets/images/CAMION_GENERAL.png',
      'en': 'Camion',
      'ar': 'كاميون',
      'fr': 'Camion',
    },
    {
      'id': 'benne',
      'img': 'assets/images/CAMION_BENNE.png',
      'en': 'Benne',
      'ar': 'بين',
      'fr': 'Benne',
    },
  ],
  6: [
    {
      'id': 'citerne',
      'img': 'assets/images/CAMION_CITERNE.png',
      'en': 'Citerne',
      'ar': 'صهريج',
      'fr': 'Citerne',
    },
  ],
  7: [
    {
      'id': 'fourgon',
      'img': 'assets/images/FOURGON_GENERAL.png',
      'en': 'Fourgon',
      'ar': 'فوروغون',
      'fr': 'Fourgon',
    },
    {
      'id': 'harbina',
      'img': 'assets/images/HARBINA_GENERAL.png',
      'en': 'Harbina',
      'ar': 'هاربينا',
      'fr': 'Harbina',
    },
    {
      'id': 'commercial',
      'img': 'assets/images/COMMERCIAL_GENERAL.png',
      'en': 'Commercial',
      'ar': 'تجاري',
      'fr': 'Commercial',
    },
  ],
};

const _subCategories = <String, List<Map<String, String>>>{
  'fourgon': [
    {
      'id': 'fourgon-long',
      'img': 'assets/images/FOURGON_LONG.png',
      'en': 'Long',
      'ar': 'طويل',
      'fr': 'Long',
    },
    {
      'id': 'fourgon-medium',
      'img': 'assets/images/FOURGON_MEDIUM.png',
      'en': 'Medium',
      'ar': 'متوسط',
      'fr': 'Moyen',
    },
    {
      'id': 'fourgon-short',
      'img': 'assets/images/FOURGON_SHORT.png',
      'en': 'Short',
      'ar': 'قصير',
      'fr': 'Court',
    },
  ],
  'harbina': [
    {
      'id': 'harbina-large',
      'img': 'assets/images/HARBINA_LONG.png',
      'en': 'Large',
      'ar': 'كبير',
      'fr': 'Grand',
    },
    {
      'id': 'harbina-small',
      'img': 'assets/images/HARBINA_SHORT.png',
      'en': 'Small',
      'ar': 'صغير',
      'fr': 'Petit',
    },
  ],
  'camion': [
    {
      'id': 'camion-large',
      'img': 'assets/images/CAMION_LARGE.png',
      'en': 'Large',
      'ar': 'كبير',
      'fr': 'Grand',
    },
    {
      'id': 'camion-small',
      'img': 'assets/images/CAMION_SMALL.png',
      'en': 'Small',
      'ar': 'صغير',
      'fr': 'Petit',
    },
  ],
  'commercial': [
    {
      'id': 'commercial',
      'img': 'assets/images/COMMERCIAL_GENERAL.png',
      'en': 'Commercial',
      'ar': 'تجاري',
      'fr': 'Commercial',
    },
  ],
  'benne': [
    {
      'id': 'benne',
      'img': 'assets/images/CAMION_BENNE.png',
      'en': 'Benne',
      'ar': 'بين',
      'fr': 'Benne',
    },
  ],
  'citerne': [
    {
      'id': 'eau',
      'img': 'assets/images/CAMION_EAU.png',
      'en': 'Eau',
      'ar': 'ماء',
      'fr': 'Eau',
    },
  ],
  'camion-citerne': [
    {
      'id': 'carburant',
      'img': 'assets/images/CAMION_CARBURANT.png',
      'en': 'Carburant',
      'ar': 'وقود',
      'fr': 'Carburant',
    },
  ],
};

const _bodyTypes = <String, Map<String, String>>{
  'contenaire': {
    'img': 'assets/images/CAMION_CONTENAIRE.png',
    'en': 'Contenaire',
    'ar': 'كونتينر',
    'fr': 'Conteneur',
  },
  'ridelle': {
    'img': 'assets/images/CAMION_RIDELLE.png',
    'en': 'Ridelle',
    'ar': 'ريدل',
    'fr': 'Ridelle',
  },
  'plateux': {
    'img': 'assets/images/CAMION_PLATEAUX.png',
    'en': 'Plateux',
    'ar': 'بلاطو',
    'fr': 'Plateau',
  },
};

const _capacities = <String, List<String>>{
  'fourgon-long': ['2T'],
  'fourgon-medium': ['1.5T'],
  'fourgon-short': ['1.2T'],
  'harbina-large': ['1.5T'],
  'harbina-small': ['1T'],
  'camion-large': ['10T', '15T', '20T'],
  'camion-small': ['3.5T', '5T'],
  'commercial': ['1T', '2T'],
  'benne': ['12.5T', '15T', '22T', '30T'],
  'eau': ['6000L', '10000L', '12000L', '18000L'],
  'carburant': ['18000L', '240000L', '270000L', '300000L'],
  'contenaire': ['10T', '15T', '20T'],
  'ridelle': ['10T', '15T', '20T'],
  'plateux': ['10T', '15T', '20T'],
};

enum _Step { truckType, subCategory, bodyType, capacity }

enum _TowingStep {
  truckType,
  depannageSubCategory,
  depannageCapacity,
  dimensions,
}

/// Returns the localized display name for a truck type id.
///
/// Reuses the truck catalogue already defined above so the customer mission
/// views show the same names as the order flow.
String truckTypeLabel(String id, String lang) {
  for (final types in _truckTypesByCategory.values) {
    for (final t in types) {
      if (t['id'] == id) {
        if (lang == 'AR') return t['ar'] ?? t['en'] ?? id;
        if (lang == 'FR') return t['fr'] ?? t['en'] ?? id;
        return t['en'] ?? id;
      }
    }
  }
  return id;
}

class OrderFlow extends StatefulWidget {
  final int categoryIndex;
  final VoidCallback onBack;
  final ValueChanged<OrderData>? onNext;
  const OrderFlow({
    super.key,
    required this.categoryIndex,
    required this.onBack,
    this.onNext,
  });

  @override
  State<OrderFlow> createState() => _OrderFlowState();
}

class _OrderFlowState extends State<OrderFlow> {
  final OrderData _data = OrderData();
  bool _isTowing = false;

  _Step _step = _Step.truckType;
  _TowingStep _towingStep = _TowingStep.truckType;

  String? _selectedTruckType;
  String? _selectedSubCategory;
  String? _selectedBodyType;
  String? _selectedCapacity;

  String? _selectedDepannageType;

  int _towingDimTab = 0;
  String? _towingWeight;
  String? _towingLength;
  String? _towingWidth;

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
    _data.category = _categoryIds[widget.categoryIndex];
    _data.shipmentType = _categoryIds[widget.categoryIndex];
    _isTowing = widget.categoryIndex == 4;
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  void _selectTruckType(String id) {
    setState(() {
      _selectedTruckType = id;
      _data.truckType = id;
    });
    if (_isTowing) {
      if (id == 'porte-chare') {
        setState(() => _towingStep = _TowingStep.dimensions);
      } else {
        setState(() => _towingStep = _TowingStep.depannageSubCategory);
      }
    } else {
      final subs = _subCategories[id];
      if (subs != null && subs.length == 1) {
        _selectedSubCategory = subs[0]['id']!;
        _data.truckModel = subs[0]['id']!;
        if (widget.categoryIndex == 2) {
          setState(() => _step = _Step.bodyType);
        } else {
          setState(() => _step = _Step.capacity);
        }
      } else {
        setState(() => _step = _Step.subCategory);
      }
    }
  }

  void _selectSubCategory(String id) {
    setState(() {
      _selectedSubCategory = id;
      _data.truckModel = id;
    });
    if (widget.categoryIndex == 2) {
      setState(() => _step = _Step.bodyType);
    } else {
      setState(() => _step = _Step.capacity);
    }
  }

  void _selectBodyType(String id) {
    setState(() {
      _selectedBodyType = id;
      _data.bodyType = id;
    });
    setState(() => _step = _Step.capacity);
  }

  void _selectCapacity(String cap) {
    setState(() {
      _selectedCapacity = cap;
      _data.weight = cap;
    });
    _onNext();
  }

  void _selectDepannageType(String id, String weight) {
    setState(() {
      _selectedDepannageType = id;
      _data.truckModel = id;
      _data.weight = weight;
    });
    _onNext();
  }

  void _selectTowingWeight(String w) {
    setState(() {
      _towingWeight = w;
      _data.weight = w;
      _towingDimTab = 1;
    });
  }

  void _selectTowingLength(String l) {
    setState(() {
      _towingLength = l;
      _data.length = l;
      _towingDimTab = 2;
    });
  }

  void _selectTowingWidth(String w) {
    setState(() {
      _towingWidth = w;
      _data.width = w;
    });
    if (_towingWeight != null && _towingLength != null) {
      _onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
    if (_isRtl)
      return Directionality(textDirection: TextDirection.rtl, child: content);
    return content;
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).viewPadding.top;
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
                textDirection: TextDirection.ltr,
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

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const SizedBox(height: 20),
          if (_isTowing) _buildTowingContent() else _buildStandardContent(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (_isTowing) {
          if (_towingStep == _TowingStep.dimensions) {
            setState(() {
              _towingStep = _TowingStep.truckType;
              _selectedTruckType = null;
              _towingWeight = null;
              _towingLength = null;
              _towingWidth = null;
              _towingDimTab = 0;
            });
          } else if (_towingStep == _TowingStep.depannageSubCategory) {
            setState(() {
              _towingStep = _TowingStep.truckType;
              _selectedTruckType = null;
            });
          } else if (_towingStep == _TowingStep.depannageCapacity) {
            setState(() {
              _towingStep = _TowingStep.depannageSubCategory;
              _selectedDepannageType = null;
              _data.weight = '';
              _data.truckModel = '';
            });
          } else {
            widget.onBack();
          }
        } else {
          if (_step == _Step.truckType) {
            widget.onBack();
          } else if (_step == _Step.subCategory) {
            setState(() {
              _step = _Step.truckType;
              _selectedTruckType = null;
              _selectedSubCategory = null;
            });
          } else if (_step == _Step.bodyType) {
            setState(() {
              _step = _Step.subCategory;
              _selectedSubCategory = null;
              _selectedBodyType = null;
            });
          } else if (_step == _Step.capacity) {
            setState(() {
              _step = widget.categoryIndex == 2
                  ? _Step.bodyType
                  : _Step.subCategory;
              _selectedCapacity = null;
              _data.weight = '';
              if (widget.categoryIndex != 2) _selectedSubCategory = null;
            });
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF5A524).withValues(alpha: 0.2),
                width: 1,
              ),
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
          Text(
            _t('Back', 'رجوع', 'Retour'),
            style: _pop(
              size: 13,
              weight: FontWeight.w600,
              color: const Color(0xFFF5A524),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardContent() {
    switch (_step) {
      case _Step.truckType:
        return _buildTruckTypeGrid();
      case _Step.subCategory:
        return _buildSubCategoryGrid();
      case _Step.bodyType:
        return _buildBodyTypeGrid();
      case _Step.capacity:
        return _buildCapacityGrid();
    }
  }

  Widget _buildTowingContent() {
    switch (_towingStep) {
      case _TowingStep.truckType:
        return _buildTowingTruckTypeGrid();
      case _TowingStep.depannageSubCategory:
        return _buildDepannageSubCategory();
      case _TowingStep.depannageCapacity:
        return _buildDepannageCapacity();
      case _TowingStep.dimensions:
        return _buildPorteChareDimensions();
    }
  }

  Widget _buildTruckTypeGrid() {
    final types = _truckTypesByCategory[widget.categoryIndex] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Truck type', 'نوع الشاحنة', 'Type de camion'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select the truck that fits the cargo',
            'اختر الشاحنة المناسبة للبضاعة',
            'Sélectionnez le camion adapté à la cargaison',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: types
              .map(
                (t) => _buildCard(
                  t,
                  selected: _selectedTruckType == t['id'],
                  onTap: () => _selectTruckType(t['id']!),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubCategoryGrid() {
    final subs = _subCategories[_selectedTruckType] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Category', 'الفئة', 'Catégorie'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select truck category',
            'اختر فئة الشاحنة',
            'Sélectionnez la catégorie du camion',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: subs
              .map(
                (s) => _buildCard(
                  s,
                  selected: _selectedSubCategory == s['id'],
                  onTap: () => _selectSubCategory(s['id']!),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBodyTypeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Sub Category', 'الفئة الفرعية', 'Sous-catégorie'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select sub category',
            'اختر الفئة الفرعية',
            'Sélectionnez la sous-catégorie',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: _bodyTypes.entries.map((e) {
            return _buildCard(
              {
                'id': e.key,
                'img': e.value['img']!,
                'en': e.value['en']!,
                'ar': e.value['ar']!,
                'fr': e.value['fr']!,
              },
              selected: _selectedBodyType == e.key,
              onTap: () => _selectBodyType(e.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCapacityGrid() {
    final modelId = widget.categoryIndex == 2
        ? (_selectedBodyType ?? '')
        : (_selectedSubCategory ?? '');
    final caps = _capacities[modelId] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Capacity', 'القدرة', 'Capacité'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select desired capacity',
            'اختر القدرة المطلوبة',
            'Sélectionnez la capacité désirée',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: caps.map((c) {
            final selected = _selectedCapacity == c;
            return GestureDetector(
              onTap: () => _selectCapacity(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFF5A524) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFF5A524)
                        : const Color(0xFFEFEFEF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    selected
                        ? BoxShadow(
                            color: const Color(0xFFF5A524).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        : BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                  ],
                ),
                child: Center(
                  child: Text(
                    c,
                    style: _pop(
                      size: 14,
                      weight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTowingTruckTypeGrid() {
    final types = _truckTypesByCategory[4] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Truck type', 'نوع الشاحنة', 'Type de camion'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select the truck that fits the cargo',
            'اختر الشاحنة المناسبة للبضاعة',
            'Sélectionnez le camion adapté à la cargaison',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: types
              .map(
                (t) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SizedBox(
                      height: 180,
                      child: _buildCard(
                        t,
                        selected: _selectedTruckType == t['id'],
                        onTap: () => _selectTruckType(t['id']!),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDepannageSubCategory() {
    final depannageTypes = [
      {
        'id': 'mid-weight',
        'img': 'assets/images/mid_weight_depannage.png',
        'en': 'Mid-weight (10T)',
        'ar': 'متوسط (10T)',
        'fr': 'Moyen (10T)',
        'weight': '10T',
      },
      {
        'id': 'light-weight',
        'img': 'assets/images/DEPANNAGE.png',
        'en': 'Light-weight (5T)',
        'ar': 'خفيف (5T)',
        'fr': 'Léger (5T)',
        'weight': '5T',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Category', 'الفئة', 'Catégorie'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select depannage category',
            'اختر فئة الديباناج',
            'Sélectionnez la catégorie de dépannage',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: depannageTypes
              .map(
                (t) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SizedBox(
                      height: 160,
                      child: _buildCard(
                        t,
                        selected: _selectedDepannageType == t['id'],
                        onTap: () =>
                            _selectDepannageType(t['id']!, t['weight']!),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDepannageCapacity() {
    return const SizedBox.shrink();
  }

  Widget _buildPorteChareDimensions() {
    final tabs = [
      _t('Weight', 'الوزن', 'Poids'),
      _t('Length', 'الطول', 'Longueur'),
      _t('Width', 'العرض', 'Largeur'),
    ];
    final dimOptions = <int, List<String>>{
      0: ['32T', '45T', '54T', '60T', '80T', '100T'],
      1: ['10M', '11M', '14M'],
      2: ['2.5M', '2.8M', '3M', '3.2M', '3.5M', '3.8M'],
    };
    final currentOptions = dimOptions[_towingDimTab] ?? [];
    final dimValues = [_towingWeight, _towingLength, _towingWidth];
    final allSelected =
        _towingWeight != null && _towingLength != null && _towingWidth != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Sub Category', 'الفئة الفرعية', 'Sous-catégorie'),
          textAlign: TextAlign.start,
          style: _pop(
            size: 26,
            weight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.2,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _t(
            'Select category to specify dimensions',
            'اختر الفئة لتحديد الأبعاد',
            'Sélectionnez la catégorie pour spécifier les dimensions',
          ),
          textAlign: TextAlign.start,
          style: _pop(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF999999),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(3, (i) {
            final isActive = _towingDimTab == i;
            final done = dimValues[i] != null;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _towingDimTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFF5A524) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFF5A524)
                            : done
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEFEFEF),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tabs[i],
                          style: _pop(
                            size: 12,
                            weight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : done
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF666666),
                          ),
                        ),
                        if (done) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF22C55E),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        if (allSelected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF22C55E), width: 1),
            ),
            child: Text(
              '${_t("All dimensions selected", "جميع الأبعاد محددة", "Toutes les dimensions sélectionnées")}: $_towingWeight, $_towingLength, $_towingWidth',
              textAlign: TextAlign.center,
              style: _pop(
                size: 13,
                weight: FontWeight.w600,
                color: const Color(0xFF22C55E),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: currentOptions.map((opt) {
              final dimKey = _towingDimTab == 0
                  ? _towingWeight
                  : _towingDimTab == 1
                  ? _towingLength
                  : _towingWidth;
              final selected = dimKey == opt;
              return GestureDetector(
                onTap: () {
                  if (_towingDimTab == 0) {
                    _selectTowingWeight(opt);
                  } else if (_towingDimTab == 1) {
                    _selectTowingLength(opt);
                  } else {
                    _selectTowingWidth(opt);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF5A524) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF5A524)
                          : const Color(0xFFEFEFEF),
                      width: 1.5,
                    ),
                    boxShadow: [
                      selected
                          ? BoxShadow(
                              color: const Color(
                                0xFFF5A524,
                              ).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            )
                          : BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                    ],
                  ),
                  child: Text(
                    opt,
                    style: _pop(
                      size: 14,
                      weight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF111111),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCard(
    Map<String, String> item, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final img = item['img']!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5A524) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF),
            width: 1.5,
          ),
          boxShadow: [
            selected
                ? BoxShadow(
                    color: const Color(0xFFF5A524).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  )
                : BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(img, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(item['en']!, item['ar']!, item['fr']!),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pop(
                size: 12,
                weight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    if (widget.onNext != null) {
      widget.onNext!(_data);
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
}
