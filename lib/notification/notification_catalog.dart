/// Reference data used by the Mission Notifications feature.
///
/// The truck families/sizes below mirror the vehicle catalogue already used by
/// the order flow (`order_flow.dart` `_truckTypesByCategory` / `_subCategories`)
/// and by the driver missions screens (`truck` / `size` fields), so the
/// notification matching stays consistent with the rest of the application.
library;

/// A driver selectable truck family.
class TruckFamily {
  final String id;
  final String en;
  final String ar;
  final String fr;
  final String image;
  final List<TruckSize> sizes;

  const TruckFamily({
    required this.id,
    required this.en,
    required this.ar,
    required this.fr,
    required this.image,
    required this.sizes,
  });

  String name(String lang) => lang == 'AR'
      ? ar
      : lang == 'FR'
      ? fr
      : en;
}

/// A size option inside a [TruckFamily].
///
/// [rank] is used for compatibility: a driver whose truck has a size with a
/// lower rank cannot handle a mission requiring a bigger truck.
class TruckSize {
  final String id;
  final String en;
  final String ar;
  final String fr;
  final int rank;

  const TruckSize({
    required this.id,
    required this.en,
    required this.ar,
    required this.fr,
    required this.rank,
  });

  String name(String lang) => lang == 'AR'
      ? ar
      : lang == 'FR'
      ? fr
      : en;
}

/// An Algerian wilaya used for the region filter.
class Region {
  final int code;
  final String ar;
  final String fr;
  final String en;
  final List<String> aliases;

  const Region({
    required this.code,
    required this.ar,
    required this.fr,
    required this.en,
    this.aliases = const [],
  });

  String name(String lang) => lang == 'AR'
      ? ar
      : lang == 'FR'
      ? fr
      : en;
}

const truckFamilies = <TruckFamily>[
  TruckFamily(
    id: 'fourgon',
    en: 'Fourgon',
    ar: 'فورغون',
    fr: 'Fourgon',
    image: 'assets/images/FOURGON_GENERAL.png',
    sizes: [
      TruckSize(
        id: 'fourgon-short',
        en: 'Short',
        ar: 'قصير',
        fr: 'Court',
        rank: 1,
      ),
      TruckSize(
        id: 'fourgon-medium',
        en: 'Medium',
        ar: 'متوسط',
        fr: 'Moyen',
        rank: 2,
      ),
      TruckSize(
        id: 'fourgon-long',
        en: 'Long',
        ar: 'طويل',
        fr: 'Long',
        rank: 3,
      ),
    ],
  ),
  TruckFamily(
    id: 'harbina',
    en: 'Harbina',
    ar: 'هاربينا',
    fr: 'Harbina',
    image: 'assets/images/HARBINA_GENERAL.png',
    sizes: [
      TruckSize(
        id: 'harbina-small',
        en: 'Small',
        ar: 'صغير',
        fr: 'Petit',
        rank: 1,
      ),
      TruckSize(
        id: 'harbina-large',
        en: 'Large',
        ar: 'كبير',
        fr: 'Grand',
        rank: 3,
      ),
    ],
  ),
  TruckFamily(
    id: 'camion',
    en: 'Camion',
    ar: 'كاميون',
    fr: 'Camion',
    image: 'assets/images/CAMION_GENERAL.png',
    sizes: [
      TruckSize(
        id: 'camion-small',
        en: 'Small',
        ar: 'صغير',
        fr: 'Petit',
        rank: 1,
      ),
      TruckSize(
        id: 'camion-large',
        en: 'Large',
        ar: 'كبير',
        fr: 'Grand',
        rank: 3,
      ),
    ],
  ),
];

// Wilaya aliases are used to resolve the free-form city names shown inside
// missions (e.g. "Algiers" -> wilaya "Alger"). Keep them lowercase.
const regions = <Region>[
  Region(code: 1, ar: 'أدرار', fr: 'Adrar', en: 'Adrar'),
  Region(
    code: 2,
    ar: 'الشلف',
    fr: 'Chlef',
    en: 'Chlef',
    aliases: ['ech cheliff'],
  ),
  Region(code: 3, ar: 'الأغواط', fr: 'Laghouat', en: 'Laghouat'),
  Region(code: 4, ar: 'أم البواقي', fr: "Oum El Bouaghi", en: 'Oum El Bouaghi'),
  Region(code: 5, ar: 'باتنة', fr: 'Batna', en: 'Batna', aliases: ['batnah']),
  Region(
    code: 6,
    ar: 'بجاية',
    fr: 'Béjaïa',
    en: 'Bejaia',
    aliases: ['bejaia', 'bejaa'],
  ),
  Region(code: 7, ar: 'بسكرة', fr: 'Biskra', en: 'Biskra'),
  Region(code: 8, ar: 'بشار', fr: 'Béchar', en: 'Bechar'),
  Region(code: 9, ar: 'البليدة', fr: 'Blida', en: 'Blida'),
  Region(code: 10, ar: 'البويرة', fr: 'Bouira', en: 'Bouira'),
  Region(code: 11, ar: 'تمنراست', fr: 'Tamanrasset', en: 'Tamanrasset'),
  Region(
    code: 12,
    ar: 'تبسة',
    fr: 'Tébessa',
    en: 'Tebessa',
    aliases: ['tebessa'],
  ),
  Region(code: 13, ar: 'تلمسان', fr: 'Tlemcen', en: 'Tlemcen'),
  Region(code: 14, ar: 'تيارت', fr: 'Tiaret', en: 'Tiaret'),
  Region(code: 15, ar: 'تيزي وزو', fr: 'Tizi Ouzou', en: 'Tizi Ouzou'),
  Region(
    code: 16,
    ar: 'الجزائر',
    fr: 'Alger',
    en: 'Algiers',
    aliases: ['alger', 'algiers', 'algere'],
  ),
  Region(code: 17, ar: 'الجلفة', fr: 'Djelfa', en: 'Djelfa'),
  Region(code: 18, ar: 'جيجل', fr: 'Jijel', en: 'Jijel'),
  Region(
    code: 19,
    ar: 'سطيف',
    fr: 'Sétif',
    en: 'Setif',
    aliases: ['setif', 'stif'],
  ),
  Region(code: 20, ar: 'سعيدة', fr: 'Saïda', en: 'Saida', aliases: ['saida']),
  Region(code: 21, ar: 'سكيكدة', fr: 'Skikda', en: 'Skikda'),
  Region(
    code: 22,
    ar: 'سيدي بلعباس',
    fr: 'Sidi Bel Abbès',
    en: 'Sidi Bel Abbes',
    aliases: ['sidi bel abbes'],
  ),
  Region(code: 23, ar: 'عنابة', fr: 'Annaba', en: 'Annaba'),
  Region(code: 24, ar: 'قالمة', fr: 'Guelma', en: 'Guelma'),
  Region(
    code: 25,
    ar: 'قسنطينة',
    fr: 'Constantine',
    en: 'Constantine',
    aliases: ['qacentina'],
  ),
  Region(code: 26, ar: 'المدية', fr: 'Médéa', en: 'Medea', aliases: ['medea']),
  Region(code: 27, ar: 'مستغانم', fr: 'Mostaganem', en: 'Mostaganem'),
  Region(
    code: 28,
    ar: 'المسيلة',
    fr: "M'Sila",
    en: "M'Sila",
    aliases: ['msila', 'm sila'],
  ),
  Region(code: 29, ar: 'معسكر', fr: 'Mascara', en: 'Mascara'),
  Region(code: 30, ar: 'ورقلة', fr: 'Ouargla', en: 'Ouargla'),
  Region(code: 31, ar: 'وهران', fr: 'Oran', en: 'Oran'),
  Region(code: 32, ar: 'البيض', fr: 'El Bayadh', en: 'El Bayadh'),
  Region(code: 33, ar: 'إليزي', fr: 'Illizi', en: 'Illizi'),
  Region(
    code: 34,
    ar: 'برج بوعريريج',
    fr: 'Bordj Bou Arréridj',
    en: 'Bordj Bou Arreridj',
    aliases: ['bordj bou arreridj'],
  ),
  Region(
    code: 35,
    ar: 'بومرداس',
    fr: 'Boumerdès',
    en: 'Boumerdes',
    aliases: ['boumerdes'],
  ),
  Region(code: 36, ar: 'الطارف', fr: 'El Tarf', en: 'El Tarf'),
  Region(code: 37, ar: 'تندوف', fr: 'Tindouf', en: 'Tindouf'),
  Region(code: 38, ar: 'تيسمسيلت', fr: 'Tissemsilt', en: 'Tissemsilt'),
  Region(
    code: 39,
    ar: 'الوادي',
    fr: 'El Oued',
    en: 'El Oued',
    aliases: ['el wadi'],
  ),
  Region(code: 40, ar: 'خنشلة', fr: 'Khenchela', en: 'Khenchela'),
  Region(code: 41, ar: 'سوق أهراس', fr: 'Souk Ahras', en: 'Souk Ahras'),
  Region(
    code: 42,
    ar: 'تيبازة',
    fr: 'Tipaza',
    en: 'Tipaza',
    aliases: ['tipasa'],
  ),
  Region(code: 43, ar: 'ميلة', fr: 'Mila', en: 'Mila'),
  Region(
    code: 44,
    ar: 'عين الدفلى',
    fr: 'Aïn Defla',
    en: 'Ain Defla',
    aliases: ['ain defla'],
  ),
  Region(code: 45, ar: 'النعامة', fr: 'Naâma', en: 'Naama', aliases: ['naama']),
  Region(
    code: 46,
    ar: 'عين تموشنت',
    fr: 'Aïn Témouchent',
    en: 'Ain Temouchent',
    aliases: ['ain temouchent'],
  ),
  Region(
    code: 47,
    ar: 'غرداية',
    fr: 'Ghardaïa',
    en: 'Ghardaia',
    aliases: ['ghardaia'],
  ),
  Region(code: 48, ar: 'غليزان', fr: 'Relizane', en: 'Relizane'),
  Region(code: 49, ar: 'تيميمون', fr: 'Timimoun', en: 'Timimoun'),
  Region(
    code: 50,
    ar: 'برج باجي مختار',
    fr: 'Bordj Badji Mokhtar',
    en: 'Bordj Badji Mokhtar',
  ),
  Region(code: 51, ar: 'أولاد جلال', fr: 'Ouled Djellal', en: 'Ouled Djellal'),
  Region(
    code: 52,
    ar: 'بني عباس',
    fr: 'Béni Abbès',
    en: 'Beni Abbes',
    aliases: ['beni abbes'],
  ),
  Region(
    code: 53,
    ar: 'عين صالح',
    fr: 'In Salah',
    en: 'In Salah',
    aliases: ['ain salah'],
  ),
  Region(
    code: 54,
    ar: 'عين قزام',
    fr: 'In Guezzam',
    en: 'In Guezzam',
    aliases: ['ain guezzam'],
  ),
  Region(code: 55, ar: 'تقرت', fr: 'Touggourt', en: 'Touggourt'),
  Region(code: 56, ar: 'جانت', fr: 'Djanet', en: 'Djanet'),
  Region(
    code: 57,
    ar: 'المغير',
    fr: "El M'Ghair",
    en: "El M'Ghair",
    aliases: ['el mghair'],
  ),
  Region(code: 58, ar: 'المنيعة', fr: 'El Meniaa', en: 'El Meniaa'),
];

/// Strips accents and punctuation so free-form city names can be matched
/// against wilayas.
String normalizeRegionText(String raw) {
  const accents = {
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'É': 'e',
    'È': 'e',
    'À': 'a',
    'Ç': 'c',
    'Ô': 'o',
    'Û': 'u',
  };
  final buffer = StringBuffer();
  for (final ch in raw.toLowerCase().split('')) {
    final plain = accents[ch] ?? ch;
    if (RegExp(r'[a-z0-9 ]').hasMatch(plain)) buffer.write(plain);
  }
  return buffer.toString().trim();
}

/// Returns the first wilaya whose official name or alias matches [raw].
Region? findRegion(String raw) {
  final normalized = normalizeRegionText(raw);
  if (normalized.isEmpty) return null;
  for (final region in regions) {
    final names = [region.en, region.fr, region.ar, ...region.aliases];
    for (final n in names) {
      final candidate = normalizeRegionText(n);
      if (candidate.isEmpty) continue;
      if (candidate == normalized ||
          normalized.contains(candidate) ||
          candidate.contains(normalized)) {
        return region;
      }
    }
  }
  return null;
}

/// Best effort: maps a mission departure/arrival city to a Region.
Region? regionForCity(String city) => findRegion(city);

/// true when [regionCode] belongs to the list of selected region codes.
bool isRegionSelected(String regionCode, Iterable<String> selected) =>
    selected.contains(regionCode);
