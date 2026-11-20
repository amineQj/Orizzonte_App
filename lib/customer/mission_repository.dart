import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import '../order_model.dart';
import '../services/api_payload.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../widgets/api_state.dart';
import 'mission_model.dart';

/// Mission repository backed by the ORIZZONTE API.
///
/// [load] fetches the signed-in client's own missions from
/// `/api/missions/client/my/`, or ALL missions from `/api/missions/all/` when
/// the user is a boss. The SharedPreferences cache is write-through only;
/// failures surface as an error state with retry, never as sample data.
/// [createMission] performs the real estimate + confirm calls.
class MissionRepository extends ChangeNotifier {
  MissionRepository._();

  static final MissionRepository instance = MissionRepository._();

  static const String _key = 'customer_missions_v1';

  /// Cache is scoped per user so a fallback can never leak another account's
  /// missions when switching clients on the same device.
  String get _cacheKey => '${_key}_${AuthSession.instance.userId ?? 'anon'}';

  final ApiService _api = ApiService();

  List<CustomerMission> _missions = [];
  bool _loading = false;
  String? _error;
  EstimateResult? _lastEstimate;

  List<CustomerMission> get missions => List.unmodifiable(_missions);
  bool get isLoading => _loading;
  String? get error => _error;
  EstimateResult? get lastEstimate => _lastEstimate;

  bool get _isBoss => AuthSession.instance.role == 'boss';

  CustomerMission? byId(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (_isBoss) {
        final remote = await _api.getAllMissions();
        _missions = remote.map(_fromBackendMission).toList();
        await _persist();
      } else {
        // API is the single source of truth for the client's mission history.
        final remote = await _api.getClientMissions();
        _missions = remote.map(_fromBackendMission).toList();
        await _persist();
      }
    } catch (e) {
      _error = apiErrorMessage(e);
      _missions = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetches a fresh estimate from the backend and caches the result.
  Future<EstimateResult> estimate(OrderData order) async {
    final result = await _api.estimateMission(ApiPayload.estimate(order));
    _lastEstimate = result;
    notifyListeners();
    return result;
  }

  /// Confirms an order through the backend (using the estimate's quote_id)
  /// and stores the created mission in the local list.
  Future<CustomerMission> createMission(
    OrderData order, {
    String? quoteId,
    bool negotiable = false,
  }) async {
    _error = null;
    final backend = await _api.confirmMission(ApiPayload.confirm(
      order,
      quoteId: quoteId,
      negotiable: negotiable,
    ));
    final mission = _fromBackendMission(backend);
    order.negotiable = negotiable || backend.negotiable;
    _missions = [mission, ..._missions];
    await _persist();
    notifyListeners();
    return mission;
  }

  /// Kept for compatibility with the existing order flow.
  Future<void> addMission(CustomerMission mission) async {
    _missions = [mission, ..._missions];
    notifyListeners();
    await _persist();
  }

  Future<void> updateStatus(String id, MissionStatus status) async {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final missionId = int.tryParse(id);

    // Boss cancellation is a real backend action.
    if (_isBoss && status == MissionStatus.cancelled && missionId != null) {
      try {
        await _api.cancelMission(missionId);
      } catch (e) {
        _error = apiErrorMessage(e);
        notifyListeners();
        return;
      }
    }

    _missions[idx] = _missions[idx].copyWith(status: status);
    notifyListeners();
    await _persist();
  }

  Future<void> assignDriver(String id, DriverInfo driver) async {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final missionId = int.tryParse(id);
    final driverId = int.tryParse(driver.id);

    if (missionId != null && driverId != null && _isBoss) {
      try {
        await _api.assignMission(missionId, driverId);
      } catch (e) {
        _error = apiErrorMessage(e);
        notifyListeners();
        return;
      }
    }

    _missions[idx] = _missions[idx].copyWith(
      status: MissionStatus.accepted,
      driver: driver,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteMission(String id) async {
    final missionId = int.tryParse(id);
    if (_isBoss && missionId != null) {
      try {
        await _api.deleteMission(missionId);
      } catch (e) {
        _error = apiErrorMessage(e);
        notifyListeners();
        return;
      }
    }
    _missions = _missions.where((m) => m.id != id).toList();
    notifyListeners();
    await _persist();
  }

  /// Refreshes client/boss missions from the backend (used as retry action).
  Future<void> retry() => load();

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      json.encode(_missions.map((m) => m.toJson()).toList()),
    );
  }

  static MissionStatus _status(String raw) {
    switch (raw) {
      case 'completed':
        return MissionStatus.completed;
      case 'in_progress':
        return MissionStatus.inProgress;
      case 'accepted':
        return MissionStatus.accepted;
      case 'cancelled':
        return MissionStatus.cancelled;
      default:
        return MissionStatus.pending;
    }
  }

  static CustomerMission _fromBackendMission(Mission m) {
    final employee = m.assignedEmployee;
    DriverInfo? driver;
    if (employee != null) {
      driver = DriverInfo(
        id: (employee['id'] ?? '').toString(),
        name: (employee['full_name'] ?? employee['username'] ?? '').toString(),
        phone: '',
      );
    }
    final order = OrderData(
      category: m.category,
      shipmentType: m.shipmentType,
      truckType: m.truckType,
      truckModel: m.size,
      weight: m.capacity.toString(),
      // The backend currently stores route coordinates, not human-readable
      // addresses. Show neutral labels here instead of leaking a client name or
      // raw coordinates into the delivery field (M2).
      pickup: 'Pickup',
      delivery: 'Drop-off',
      pickupCoords: {'lat': m.departureLat, 'lng': m.departureLon},
      deliveryCoords: {'lat': m.arrivalLat, 'lng': m.arrivalLon},
      distance: '${m.distance.toStringAsFixed(1)} km',
      isNow: false,
      manualDate: m.date,
      manualTime: m.time,
      helpers: m.workers,
      phoneNumber: m.phoneNumber,
      estimatedPrice: formatDzd(m.price),
      negotiable: m.negotiable,
    );
    return CustomerMission(
      id: m.id.toString(),
      order: order,
      status: _status(m.status),
      createdAt: m.createdAt ?? DateTime.now(),
      driver: driver,
      negotiable: m.negotiable,
    );
  }
}
