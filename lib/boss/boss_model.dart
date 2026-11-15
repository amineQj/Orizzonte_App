/// A driver registered on the platform, managed from the Boss dashboard.
///
/// Drivers register on their own (there is no "add employee" flow), so the
/// Boss only reads this list and assigns drivers to missions.
class BossDriver {
  final String id;
  final String name;
  final String role;
  final String initials;
  final int missions;
  final String phone;
  final double rating;
  final String? vehicle;

  const BossDriver({
    required this.id,
    required this.name,
    required this.role,
    required this.initials,
    required this.missions,
    required this.phone,
    required this.rating,
    this.vehicle,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'initials': initials,
    'missions': missions,
    'phone': phone,
    'rating': rating,
    'vehicle': vehicle,
  };

  factory BossDriver.fromJson(Map<String, dynamic> j) => BossDriver(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    role: j['role'] as String? ?? '',
    initials: j['initials'] as String? ?? '',
    missions: j['missions'] as int? ?? 0,
    phone: j['phone'] as String? ?? '',
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
    vehicle: j['vehicle'] as String?,
  );
}

/// Pricing and admin account configuration for the Boss dashboard.
class BossSettings {
  final double baseRate;
  final double premiumMarkup;
  final double minPrice;
  final String adminName;
  final String adminEmail;

  const BossSettings({
    this.baseRate = 45,
    this.premiumMarkup = 25,
    this.minPrice = 8000,
    this.adminName = 'Admin ORIZZONTE',
    this.adminEmail = 'admin@orizzonte.dz',
  });

  BossSettings copyWith({
    double? baseRate,
    double? premiumMarkup,
    double? minPrice,
    String? adminName,
    String? adminEmail,
  }) {
    return BossSettings(
      baseRate: baseRate ?? this.baseRate,
      premiumMarkup: premiumMarkup ?? this.premiumMarkup,
      minPrice: minPrice ?? this.minPrice,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseRate': baseRate,
    'premiumMarkup': premiumMarkup,
    'minPrice': minPrice,
    'adminName': adminName,
    'adminEmail': adminEmail,
  };

  factory BossSettings.fromJson(Map<String, dynamic> j) => BossSettings(
    baseRate: (j['baseRate'] as num?)?.toDouble() ?? 45,
    premiumMarkup: (j['premiumMarkup'] as num?)?.toDouble() ?? 25,
    minPrice: (j['minPrice'] as num?)?.toDouble() ?? 8000,
    adminName: j['adminName'] as String? ?? 'Admin ORIZZONTE',
    adminEmail: j['adminEmail'] as String? ?? 'admin@orizzonte.dz',
  );
}
