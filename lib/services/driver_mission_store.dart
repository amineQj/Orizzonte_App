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
  DriverMissionStore._();

  static final DriverMissionStore instance = DriverMissionStore._();

  final ApiService _api = ApiService();

  final List<DriverMissionItem> _missions = [];
  bool _loading = false;
  String? _error;
  bool _isDemo = false;

  List<DriverMissionItem> get allMissions => List.unmodifiable(_missions);
  List<DriverMissionItem> get availableMissions =>
      _missions.where((m) => m.status == 'Available').toList();
  List<DriverMissionItem> get acceptedMissions =>
      _missions.where((m) => m.status == 'Accepted').toList();
  List<DriverMissionItem> get inProgressMissions =>
      _missions.where((m) => m.status == 'In Progress').toList();
  List<DriverMissionItem> get completedMissions =>
      _missions.where((m) => m.status == 'Completed').toList();

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isDemo => _isDemo;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Only fetch driver data when signed in as a driver.
      if (AuthSession.instance.role != 'driver') {
        _missions
          ..clear()
          ..addAll(_demoFallback());
        _isDemo = true;
      } else {
        final available = await _api.getAvailableMissions();
        final mine = await _api.getMyMissions();
        final seen = <String>{};
        final next = <DriverMissionItem>[];
        for (final m in [...mine, ...available]) {
          if (!seen.add(m.id.toString())) continue;
          next.add(_fromBackendMission(m));
        }
        _missions
          ..clear()
          ..addAll(next);
        _isDemo = false;
      }
    } catch (e) {
      _error = apiErrorMessage(e);
      _missions
        ..clear()
        ..addAll(_demoFallback());
      _isDemo = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => load();

  Future<bool> acceptMission(String id) =>
      _act(id, (mid) => _api.acceptMission(mid), 'In Progress');

  Future<bool> startMission(String id) =>
      _act(id, (mid) => _api.startMission(mid), 'In Progress');

  Future<bool> completeMission(String id) =>
      _act(id, (mid) => _api.completeMission(mid), 'Completed');

  Future<bool> _act(
    String id,
    Future<Mission> Function(int) call,
    String newStatus,
  ) async {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx == -1) return false;
    final missionId = int.tryParse(id);
    if (missionId != null) {
      try {
        final updated = await call(missionId);
        _missions[idx] = _fromBackendMission(updated);
      } catch (e) {
        _error = apiErrorMessage(e);
        notifyListeners();
        return false;
      }
    }
    _missions[idx].status = newStatus;
    notifyListeners();
    return true;
  }

  DriverMissionItem? findById(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  static String _status(Mission m) {
    final ds = m.displayStatus.toLowerCase();
    if (ds == 'completed' || m.status == 'completed') return 'Completed';
    if (ds == 'in_progress' || m.status == 'in_progress') return 'In Progress';
    if (ds == 'taken' || m.status == 'accepted') return 'Accepted';
    return 'Available';
  }

  static DriverMissionItem _fromBackendMission(Mission m) {
    final client = (m.client?['full_name'] ?? m.client?['username'] ?? '')
        .toString();
    return DriverMissionItem(
      id: m.id.toString(),
      client: client.isNotEmpty
          ? client
          : (m.phoneNumber.isNotEmpty ? 'Client (${m.phoneNumber})' : 'Customer'),
      from: '${m.departureLat.toStringAsFixed(3)}, ${m.departureLon.toStringAsFixed(3)}',
      to: '${m.arrivalLat.toStringAsFixed(3)}, ${m.arrivalLon.toStringAsFixed(3)}',
      date: '${m.date} ${m.time}'.trim(),
      truck: m.truckType,
      size: m.size,
      dist: '${m.distance.toStringAsFixed(1)} km',
      price: m.driverNet != null
          ? '${formatDzd(m.driverNet!)} DZD net'
          : '${formatDzd(m.price)} DZD',
      negotiable: m.negotiable,
      status: _status(m),
    );
  }

  /// Sample missions used ONLY when there is no driver session or the backend
  /// is unreachable. The UI shows a clear "offline demo data" warning banner
  /// whenever this fallback is active ([isDemo]).
  static List<DriverMissionItem> _demoFallback() => [
        DriverMissionItem(
            id: 'M-001', client: 'Ahmed Benali', from: 'Algiers', to: 'Oran',
            date: '25 Jul 09:00', truck: 'Camion', size: 'Large',
            dist: '420 km', price: '15,000 DZD'),
        DriverMissionItem(
            id: 'M-002', client: 'Sara Khelifi', from: 'Constantine', to: 'Annaba',
            date: '26 Jul 14:30', truck: 'Fourgon', size: 'Medium',
            dist: '180 km', price: '8,500 DZD'),
        DriverMissionItem(
            id: 'M-003', client: 'Omar Saidi', from: 'Blida', to: 'Setif',
            date: '27 Jul 08:00', truck: 'Harbina', size: 'Short',
            dist: '300 km', price: '12,000 DZD'),
        DriverMissionItem(
            id: 'M-004', client: 'Fatima Zeroual', from: 'Tlemcen', to: 'Bejaia',
            date: '28 Jul 10:00', truck: 'Camion', size: 'Small',
            dist: '520 km', price: '18,000 DZD'),
        DriverMissionItem(
            id: 'M-005', client: 'Mohamed Cherif', from: 'Algiers', to: 'Tlemcen',
            date: '25 Jul 08:00', truck: 'Camion', size: 'Large',
            dist: '680 km', price: '22,000 DZD', status: 'Accepted'),
        DriverMissionItem(
            id: 'M-006', client: 'Amina Bouzid', from: 'Oran', to: 'Constantine',
            date: '26 Jul 10:30', truck: 'Fourgon', size: 'Short',
            dist: '510 km', price: '17,500 DZD', status: 'Accepted'),
        DriverMissionItem(
            id: 'M-007', client: 'Youcef Hamidi', from: 'Setif', to: 'Algiers',
            date: '24 Jul 14:00', truck: 'Harbina', size: 'Medium',
            dist: '310 km', price: '13,500 DZD', status: 'In Progress'),
        DriverMissionItem(
            id: 'M-008', client: 'Karim Sahli', from: 'Annaba', to: 'Blida',
            date: '22 Jul 09:00', truck: 'Camion', size: 'Small',
            dist: '450 km', price: '16,000 DZD', status: 'Completed'),
        DriverMissionItem(
            id: 'M-009', client: 'Nadia Merah', from: 'Bejaia', to: 'Oran',
            date: '20 Jul 11:30', truck: 'Fourgon', size: 'Long',
            dist: '620 km', price: '20,500 DZD', status: 'Completed'),
        DriverMissionItem(
            id: 'M-010', client: 'Samir Touati', from: 'Tizi Ouzou', to: 'Setif',
            date: '18 Jul 07:00', truck: 'Harbina', size: 'Short',
            dist: '250 km', price: '9,000 DZD', status: 'Completed'),
      ];
}
