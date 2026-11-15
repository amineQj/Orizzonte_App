import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mission_model.dart';

/// Local store for the missions created by the customer.
///
/// The project has no backend yet, so this repository persists missions with
/// [shared_preferences] (the same persistence mechanism already used by the
/// notification preferences). It is a [ChangeNotifier] so the Customer Home
/// updates immediately whenever a mission is added or its status changes.
class MissionRepository extends ChangeNotifier {
  MissionRepository._();

  static final MissionRepository instance = MissionRepository._();

  static const String _key = 'customer_missions_v1';

  List<CustomerMission> _missions = [];
  bool _loading = false;
  String? _error;

  /// Missions ordered newest first.
  List<CustomerMission> get missions => List.unmodifiable(_missions);

  bool get isLoading => _loading;
  String? get error => _error;

  CustomerMission? byId(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = json.decode(raw) as List;
        _missions = list
            .map((e) => CustomerMission.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _missions = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addMission(CustomerMission mission) async {
    _missions = [mission, ..._missions];
    notifyListeners();
    await _persist();
  }

  Future<void> updateStatus(String id, MissionStatus status) async {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _missions[idx] = _missions[idx].copyWith(status: status);
    notifyListeners();
    await _persist();
  }

  /// Assigns a [driver] to the mission and moves it to [MissionStatus.accepted].
  Future<void> assignDriver(String id, DriverInfo driver) async {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _missions[idx] = _missions[idx].copyWith(
      status: MissionStatus.accepted,
      driver: driver,
    );
    notifyListeners();
    await _persist();
  }

  /// Permanently removes a mission from the list.
  Future<void> deleteMission(String id) async {
    _missions = _missions.where((m) => m.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(_missions.map((m) => m.toJson()).toList()),
    );
  }
}
