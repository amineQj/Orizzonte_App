import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_session.dart';
import '../widgets/api_state.dart';

class DriverMissionItem {
  final String id;
  final String client;
  final String from;
  final String to;
  final String date;
  final String truck;
  final String size;
  final String dist;
  final String price;
  final bool negotiable;
  String status; // 'Available' | 'Accepted' | 'In Progress' | 'Completed'

  DriverMissionItem({
    required this.id,
    required this.client,
    required this.from,
    required this.to,
    required this.date,
    required this.truck,
    required this.size,
    required this.dist,
    required this.price,
    this.negotiable = false,
    this.status = 'Available',
  });

  Map<String, String> toMap() => {
        'id': id,
        'client': client,
        'from': from,
        'to': to,
        'date': date,
        'truck': truck,
        'size': size,
        'dist': dist,
        'price': price,
        'status': status,
        'negotiable': negotiable.toString(),
      };
}

/// Driver mission store backed by the ORIZZONTE API.
///
/// `load()` fetches `/api/missions/available/` and `/api/missions/my/`;
/// accept / start / complete call their respective backend endpoints.
class DriverMissionStore extends ChangeNotifier {
  DriverMissionStore._({ApiService? api}) : _api = api ?? ApiService();

  static final DriverMissionStore instance = DriverMissionStore._();

  @visibleForTesting
  static DriverMissionStore withApi(ApiService api) =>
      DriverMissionStore._(api: api);

  final ApiService _api;

  final List<DriverMissionItem> _missions = [];
  bool _loading = false;
  String? _error;

  List<DriverMissionItem> get allMissions => List.unmodifiable(_missions);
  List<DriverMissionItem> get availableMissions =>
      _missions.where((m) => m.status == 'Available').toList();
  List<DriverMissionItem> get acceptedMissions =>
      _missions.where((m) => m.status == 'Accepted').toList();
  List<DriverMissionItem> get inProgressMissions =>
      _missions.where((m) => m.status == 'In Progress').toList();
  List<DriverMissionItem> get completedMissions =>
      _missions.where((m) => m.status == 'Completed').toList();

  @visibleForTesting
  void seedForTest(Iterable<Mission> missions) {
    _missions
      ..clear()
      ..addAll(missions.map(fromBackendMission));
    notifyListeners();
  }

  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Only fetch driver data when signed in as a driver.
      if (AuthSession.instance.role != 'driver') {
        _missions.clear();
        _error = 'Sign in as a driver to load missions.';
      } else {
        final available = await _api.getAvailableMissions();
        final mine = await _api.getMyMissions();
        final seen = <String>{};
        final next = <DriverMissionItem>[];
        for (final m in [...mine, ...available]) {
          if (!seen.add(m.id.toString())) continue;
          next.add(fromBackendMission(m));
        }
        _missions
          ..clear()
          ..addAll(next);
      }
    } catch (e) {
      _error = apiErrorMessage(e);
      _missions.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => load();

  Future<bool> acceptMission(String id) =>
      _act(id, (mid) => _api.acceptMission(mid));

  Future<bool> startMission(String id) =>
      _act(id, (mid) => _api.startMission(mid));

  Future<bool> completeMission(String id) =>
      _act(id, (mid) => _api.completeMission(mid));

  /// The backend response is authoritative for the new status. Local code
  /// must never invent a lifecycle state (C12).
  Future<bool> _act(
    String id,
    Future<Mission> Function(int) call,
  ) async {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx == -1) return false;
    final missionId = int.tryParse(id);
    if (missionId == null) {
      _error = 'Demo mission — sign in to perform this action on a real mission.';
      notifyListeners();
      return false;
    }
    try {
      final updated = await call(missionId);
      _missions[idx] = fromBackendMission(updated);
    } catch (e) {
      _error = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  DriverMissionItem? findById(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Preserve the backend `status` / `display_status` pair. `taken` is the
  /// driver-facing label for an accepted-but-not-started mission; it must stay
  /// distinct from `in_progress`.
  static String statusFromBackend(Mission m) {
    final ds = m.displayStatus.toLowerCase();
    if (ds == 'completed' || m.status == 'completed') return 'Completed';
    if (ds == 'in_progress' || m.status == 'in_progress') return 'In Progress';
    if (ds == 'taken' || m.status == 'accepted') return 'Accepted';
    return 'Available';
  }

  /// Use backend address text when supplied. Older payloads only carry
  /// coordinates, so neutral labels are shown instead of raw lat/lon (m7).
  static ({String from, String to}) addressLabels(Mission m) {
    final pickup = m.pickupAddress.trim();
    final dropoff = m.dropoffAddress.trim();
    return (
      from: pickup.isNotEmpty ? pickup : 'Pickup',
      to: dropoff.isNotEmpty ? dropoff : 'Drop-off',
    );
  }

  static DriverMissionItem fromBackendMission(Mission m) {
    final client = (m.client?['full_name'] ?? m.client?['username'] ?? '')
        .toString();
    final address = addressLabels(m);
    return DriverMissionItem(
      id: m.id.toString(),
      client: client.isNotEmpty
          ? client
          : (m.phoneNumber.isNotEmpty ? 'Client (${m.phoneNumber})' : 'Customer'),
      from: address.from,
      to: address.to,
      date: '${m.date} ${m.time}'.trim(),
      truck: m.truckType,
      size: m.size,
      dist: '${m.distance.toStringAsFixed(1)} km',
      price: m.driverNet != null
          ? '${formatDzd(m.driverNet!)} DZD net'
          : '${formatDzd(m.price)} DZD',
      negotiable: m.negotiable,
      status: statusFromBackend(m),
    );
  }
}
