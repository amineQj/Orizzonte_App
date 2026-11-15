import 'package:flutter/foundation.dart';
import '../customer/mission_model.dart';
import '../customer/mission_repository.dart';

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
    this.status = 'Available',
  });

  Map<String, String> toMap() {
    return {
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
    };
  }
}

class DriverMissionStore extends ChangeNotifier {
  DriverMissionStore._() {
    _initDefaults();
    _listenCustomerMissions();
  }

  static final DriverMissionStore instance = DriverMissionStore._();

  final List<DriverMissionItem> _missions = [];

  List<DriverMissionItem> get allMissions => List.unmodifiable(_missions);

  List<DriverMissionItem> get availableMissions =>
      _missions.where((m) => m.status == 'Available').toList();

  List<DriverMissionItem> get acceptedMissions =>
      _missions.where((m) => m.status == 'Accepted').toList();

  List<DriverMissionItem> get inProgressMissions =>
      _missions.where((m) => m.status == 'In Progress').toList();

  List<DriverMissionItem> get completedMissions =>
      _missions.where((m) => m.status == 'Completed').toList();

  void _initDefaults() {
    _missions.addAll([
      DriverMissionItem(
        id: 'M-001',
        client: 'Ahmed Benali',
        from: 'Algiers',
        to: 'Oran',
        date: '25 Jul 09:00',
        truck: 'Camion',
        size: 'Large',
        dist: '420 km',
        price: '15,000 DZD',
        status: 'Available',
      ),
      DriverMissionItem(
        id: 'M-002',
        client: 'Sara Khelifi',
        from: 'Constantine',
        to: 'Annaba',
        date: '26 Jul 14:30',
        truck: 'Fourgon',
        size: 'Medium',
        dist: '180 km',
        price: '8,500 DZD',
        status: 'Available',
      ),
      DriverMissionItem(
        id: 'M-003',
        client: 'Omar Saidi',
        from: 'Blida',
        to: 'Setif',
        date: '27 Jul 08:00',
        truck: 'Harbina',
        size: 'Short',
        dist: '300 km',
        price: '12,000 DZD',
        status: 'Available',
      ),
      DriverMissionItem(
        id: 'M-004',
        client: 'Fatima Zeroual',
        from: 'Tlemcen',
        to: 'Bejaia',
        date: '28 Jul 10:00',
        truck: 'Camion',
        size: 'Small',
        dist: '520 km',
        price: '18,000 DZD',
        status: 'Available',
      ),
      DriverMissionItem(
        id: 'M-005',
        client: 'Mohamed Cherif',
        from: 'Algiers',
        to: 'Tlemcen',
        date: '25 Jul 08:00',
        truck: 'Camion',
        size: 'Large',
        dist: '680 km',
        price: '22,000 DZD',
        status: 'Accepted',
      ),
      DriverMissionItem(
        id: 'M-006',
        client: 'Amina Bouzid',
        from: 'Oran',
        to: 'Constantine',
        date: '26 Jul 10:30',
        truck: 'Fourgon',
        size: 'Short',
        dist: '510 km',
        price: '17,500 DZD',
        status: 'Accepted',
      ),
      DriverMissionItem(
        id: 'M-007',
        client: 'Youcef Hamidi',
        from: 'Setif',
        to: 'Algiers',
        date: '24 Jul 14:00',
        truck: 'Harbina',
        size: 'Medium',
        dist: '310 km',
        price: '13,500 DZD',
        status: 'In Progress',
      ),
      DriverMissionItem(
        id: 'M-008',
        client: 'Karim Sahli',
        from: 'Annaba',
        to: 'Blida',
        date: '22 Jul 09:00',
        truck: 'Camion',
        size: 'Small',
        dist: '450 km',
        price: '16,000 DZD',
        status: 'Completed',
      ),
      DriverMissionItem(
        id: 'M-009',
        client: 'Nadia Merah',
        from: 'Bejaia',
        to: 'Oran',
        date: '20 Jul 11:30',
        truck: 'Fourgon',
        size: 'Long',
        dist: '620 km',
        price: '20,500 DZD',
        status: 'Completed',
      ),
      DriverMissionItem(
        id: 'M-010',
        client: 'Samir Touati',
        from: 'Tizi Ouzou',
        to: 'Setif',
        date: '18 Jul 07:00',
        truck: 'Harbina',
        size: 'Short',
        dist: '250 km',
        price: '9,000 DZD',
        status: 'Completed',
      ),
    ]);
  }

  void _listenCustomerMissions() {
    MissionRepository.instance.addListener(() {
      for (final cm in MissionRepository.instance.missions) {
        final existingIdx = _missions.indexWhere((m) => m.id == cm.id);
        String mappedStatus;
        switch (cm.status) {
          case MissionStatus.pending:
          case MissionStatus.searching:
            mappedStatus = 'Available';
            break;
          case MissionStatus.accepted:
            mappedStatus = 'Accepted';
            break;
          case MissionStatus.inProgress:
            mappedStatus = 'In Progress';
            break;
          case MissionStatus.completed:
            mappedStatus = 'Completed';
            break;
          case MissionStatus.cancelled:
            continue;
        }

        if (existingIdx != -1) {
          _missions[existingIdx].status = mappedStatus;
        } else {
          _missions.insert(
            0,
            DriverMissionItem(
              id: cm.id,
              client: cm.order.phoneNumber.isNotEmpty
                  ? 'Client (${cm.order.phoneNumber})'
                  : 'Customer',
              from: cm.order.pickup.isNotEmpty ? cm.order.pickup : 'Algiers',
              to: cm.order.delivery.isNotEmpty ? cm.order.delivery : 'Oran',
              date: '${cm.order.manualDate} ${cm.order.manualTime}'.trim().isNotEmpty
                  ? '${cm.order.manualDate} ${cm.order.manualTime}'.trim()
                  : 'Today',
              truck: cm.order.truckType.isNotEmpty ? cm.order.truckType : 'Camion',
              size: cm.order.truckModel.isNotEmpty ? cm.order.truckModel : 'Standard',
              dist: cm.order.distance ?? '100 km',
              price: cm.order.estimatedPrice.isNotEmpty
                  ? cm.order.estimatedPrice
                  : '10,000 DZD',
              status: mappedStatus,
            ),
          );
        }
      }
      notifyListeners();
    });
  }

  /// Driver accepts the mission: moves status from Available → In Progress.
  void acceptMission(String id) {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _missions[idx].status = 'In Progress';
      MissionRepository.instance.updateStatus(id, MissionStatus.inProgress);
      notifyListeners();
    }
  }

  /// Driver starts the mission: moves status from Accepted → In Progress.
  void startMission(String id) {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _missions[idx].status = 'In Progress';
      MissionRepository.instance.updateStatus(id, MissionStatus.inProgress);
      notifyListeners();
    }
  }

  /// Driver completes the mission: moves status to 'Completed'.
  void completeMission(String id) {
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _missions[idx].status = 'Completed';
      MissionRepository.instance.updateStatus(id, MissionStatus.completed);
      notifyListeners();
    }
  }

  DriverMissionItem? findById(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }
}
