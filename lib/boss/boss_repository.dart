import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'boss_model.dart';

/// Local data source for the Boss dashboard.
///
/// Missions come from the existing [MissionRepository]; this repository only
/// manages the seeded driver list and the platform settings so the Boss
/// dashboard has real data to read while the backend is being built.
class BossRepository extends ChangeNotifier {
  BossRepository._();
  static final BossRepository instance = BossRepository._();

  static const _driversKey = 'boss_drivers_v1';
  static const _settingsKey = 'boss_settings_v1';

  final List<BossDriver> _drivers = _seedDrivers();

  List<BossDriver> get drivers => List.unmodifiable(_drivers);

  BossSettings _settings = const BossSettings();
  BossSettings get settings => _settings;

  bool _loading = false;
  bool get isLoading => _loading;

  BossDriver? driverByName(String name) {
    for (final d in _drivers) {
      if (d.name.toLowerCase() == name.toLowerCase()) return d;
    }
    return null;
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawDrivers = prefs.getString(_driversKey);
      if (rawDrivers != null && rawDrivers.isNotEmpty) {
        final list = json.decode(rawDrivers) as List;
        _drivers
          ..clear()
          ..addAll(
            list.map((e) => BossDriver.fromJson(e as Map<String, dynamic>)),
          );
      }
      final rawSettings = prefs.getString(_settingsKey);
      if (rawSettings != null && rawSettings.isNotEmpty) {
        _settings = BossSettings.fromJson(
          json.decode(rawSettings) as Map<String, dynamic>,
        );
      }
      notifyListeners();
    } finally {
      _loading = false;
    }
  }

  Future<void> saveSettings(BossSettings settings) async {
    _settings = settings;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
  }

  static List<BossDriver> _seedDrivers() {
    return const [
      BossDriver(
        id: '1',
        name: 'Mehdi Cherbi',
        role: 'Driver — Senior',
        initials: 'MC',
        missions: 24,
        phone: '0550 12 34 56',
        rating: 4.9,
        vehicle: 'Iveco Daily',
      ),
      BossDriver(
        id: '2',
        name: 'Abdellah Chenane',
        role: 'Packing Specialist',
        initials: 'AC',
        missions: 19,
        phone: '0661 23 45 67',
        rating: 4.7,
        vehicle: 'Packing crew',
      ),
      BossDriver(
        id: '3',
        name: 'Lyamine Zerrouki',
        role: 'Driver — Junior',
        initials: 'LZ',
        missions: 7,
        phone: '0770 34 56 78',
        rating: 4.4,
        vehicle: 'Renault Trucks',
      ),
      BossDriver(
        id: '4',
        name: 'Mouhamed Chekirou',
        role: 'Logistics Manager',
        initials: 'MK',
        missions: 31,
        phone: '0555 45 67 89',
        rating: 4.8,
        vehicle: 'Mercedes Actros',
      ),
      BossDriver(
        id: '5',
        name: 'Diaa Chouabbi',
        role: 'Operations',
        initials: 'DC',
        missions: 14,
        phone: '0660 56 78 90',
        rating: 4.6,
        vehicle: '—',
      ),
    ];
  }
}
