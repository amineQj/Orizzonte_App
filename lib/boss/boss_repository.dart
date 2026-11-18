import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../customer/mission_repository.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import 'boss_model.dart';

/// Boss dashboard repository backed by the ORIZZONTE API.
///
/// Loads dashboard statistics, pending driver approvals (and, through
/// [MissionRepository], all missions) from the backend. Settings remain local
/// preferences because the backend has no settings endpoint.
class BossRepository extends ChangeNotifier {
  BossRepository._();
  static final BossRepository instance = BossRepository._();

  static const _settingsKey = 'boss_settings_v1';

  final ApiService _api = ApiService();

  List<BossDriver> _drivers = [];
  List<PendingDriver> _pendingDrivers = [];
  Map<String, dynamic> _stats = {};
  BossSettings _settings = const BossSettings();

  bool _loading = false;
  String? _error;
  bool _isDemo = false;

  List<BossDriver> get drivers => List.unmodifiable(_drivers);
  List<PendingDriver> get pendingDrivers => List.unmodifiable(_pendingDrivers);
  Map<String, dynamic> get stats => Map.unmodifiable(_stats);
  BossSettings get settings => _settings;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isDemo => _isDemo;

  BossDriver? driverByName(String name) {
    for (final d in _drivers) {
      if (d.name.toLowerCase() == name.toLowerCase()) return d;
    }
    return null;
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getDashboardStats(),
        _api.getPendingDrivers(),
        MissionRepository.instance.load(),
      ]);
      _stats = results[0] as Map<String, dynamic>;
      _pendingDrivers = results[1] as List<PendingDriver>;
      _drivers = _pendingDrivers.map(_toBossDriver).toList();
      _isDemo = false;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw != null && raw.isNotEmpty) {
        _settings = BossSettings.fromJson(json.decode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      _error = apiErrorMessage(e);
      _stats = const {
        'total_missions': 0,
        'completed_missions': 0,
        'active_missions': 0,
        'pending_drivers': 2,
      };
      _pendingDrivers = _demoPendingDrivers();
      _drivers = _pendingDrivers.map(_toBossDriver).toList();
      _isDemo = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => load();

  Future<bool> approveDriver(String driverId) async {
    final id = int.tryParse(driverId);
    if (id == null) return false;
    try {
      await _api.approveDriver(id);
      await load();
      return true;
    } catch (e) {
      _error = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectDriver(String driverId, String reason) async {
    final id = int.tryParse(driverId);
    if (id == null) return false;
    try {
      await _api.rejectDriver(id, reason);
      await load();
      return true;
    } catch (e) {
      _error = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> saveSettings(BossSettings settings) async {
    _settings = settings;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
  }

  /// Offline sample approvals — only used when the backend is unreachable.
  static List<PendingDriver> _demoPendingDrivers() => const [
        PendingDriver(
          userId: 901,
          fullName: 'Demo Driver One',
          phone: '0550 00 00 01',
          profileStatus: 'pending_review',
          vehiclePlate: '1234 AB 01',
          documentsVersion: 1,
        ),
        PendingDriver(
          userId: 902,
          fullName: 'Demo Driver Two',
          phone: '0661 00 00 02',
          profileStatus: 'pending_review',
          vehiclePlate: '5678 CD 02',
          documentsVersion: 1,
        ),
      ];

  static BossDriver _toBossDriver(PendingDriver d) {
    final initials = d.fullName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return BossDriver(
      id: d.userId.toString(),
      name: d.fullName.isEmpty ? 'Driver #${d.userId}' : d.fullName,
      role: d.profileStatus.replaceAll('_', ' '),
      initials: initials.isEmpty ? 'DR' : initials,
      missions: 0,
      phone: d.phone,
      rating: 0,
      vehicle: d.vehiclePlate.isEmpty ? null : d.vehiclePlate,
    );
  }
}
