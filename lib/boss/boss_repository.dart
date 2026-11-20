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
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic> _stats = {};
  BossSettings _settings = const BossSettings();

  bool _loading = false;
  String? _error;

  List<BossDriver> get drivers => List.unmodifiable(_drivers);
  List<PendingDriver> get pendingDrivers => List.unmodifiable(_pendingDrivers);
  List<Map<String, dynamic>> get employees => List.unmodifiable(_employees);
  Map<String, dynamic> get stats => Map.unmodifiable(_stats);
  BossSettings get settings => _settings;
  bool get isLoading => _loading;
  String? get error => _error;

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
        _api.getEmployees(),
      ]);
      _stats = results[0] as Map<String, dynamic>;
      _pendingDrivers = results[1] as List<PendingDriver>;
      _drivers = _pendingDrivers.map(_toBossDriver).toList();
      _employees = results[3] as List<Map<String, dynamic>>;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw != null && raw.isNotEmpty) {
        _settings = BossSettings.fromJson(json.decode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      _error = apiErrorMessage(e);
      _stats = const {};
      _pendingDrivers = const [];
      _drivers = const [];
      _employees = const [];
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

  Future<bool> removeEmployee(String employeeId) async {
    final id = int.tryParse(employeeId);
    if (id == null) return false;
    try {
      await _api.deleteEmployee(id);
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
