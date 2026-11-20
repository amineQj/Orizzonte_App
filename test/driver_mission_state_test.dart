import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:orizzonte/models/api_models.dart';
import 'package:orizzonte/services/api_service.dart';
import 'package:orizzonte/services/driver_mission_filters.dart';
import 'package:orizzonte/services/driver_mission_store.dart';
import 'package:orizzonte/services/driver_verification_state.dart';

class _MissionClient extends http.BaseClient {
  Map<String, dynamic> responseBody = const {};
  String? lastPath;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastPath = request.url.path;
    return http.StreamedResponse(
      Stream.value(utf8.encode(json.encode(responseBody))),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}

Map<String, dynamic> _missionJson({
  required int id,
  required String status,
  required String displayStatus,
  String? pickupAddress,
  String? dropoffAddress,
}) =>
    {
      'id': id,
      'status': status,
      'display_status': displayStatus,
      'departure_latitude': '36.7538',
      'departure_longitude': '3.0588',
      'arrival_latitude': '35.6962',
      'arrival_longitude': '-0.6400',
      'distance': '137.5',
      'price': '15000.00',
      'pickup_address': ?pickupAddress,
      'dropoff_address': ?dropoffAddress,
    };

Map<String, String> _row({
  required String truck,
  required String price,
  required String dist,
  required String date,
}) =>
    {
      'truck': truck,
      'price': price,
      'dist': dist,
      'date': date,
    };

void main() {
  group('DriverMissionStore lifecycle (C12)', () {
    test('accept/start/complete take status from the backend response', () async {
      final client = _MissionClient();
      final store = DriverMissionStore.withApi(
        ApiService(client: client, baseUrl: 'http://test'),
      );
      store.seedForTest([
        Mission.fromJson(_missionJson(
          id: 1,
          status: 'pending',
          displayStatus: 'available',
        )),
      ]);

      client.responseBody = _missionJson(
        id: 1,
        status: 'accepted',
        displayStatus: 'taken',
      );
      expect(await store.acceptMission('1'), isTrue);
      expect(store.allMissions.single.status, 'Accepted');
      expect(client.lastPath, '/api/missions/1/accept/');

      client.responseBody = _missionJson(
        id: 1,
        status: 'in_progress',
        displayStatus: 'in_progress',
      );
      expect(await store.startMission('1'), isTrue);
      expect(store.allMissions.single.status, 'In Progress');

      client.responseBody = _missionJson(
        id: 1,
        status: 'completed',
        displayStatus: 'completed',
      );
      expect(await store.completeMission('1'), isTrue);
      expect(store.allMissions.single.status, 'Completed');
    });

    test('taken never collapses into in_progress', () {
      final taken = Mission.fromJson(_missionJson(
        id: 2,
        status: 'accepted',
        displayStatus: 'taken',
      ));
      final started = Mission.fromJson(_missionJson(
        id: 3,
        status: 'in_progress',
        displayStatus: 'in_progress',
      ));
      expect(DriverMissionStore.statusFromBackend(taken), 'Accepted');
      expect(DriverMissionStore.statusFromBackend(started), 'In Progress');
    });
  });

  group('Mission address display (m7)', () {
    test('uses backend address text when present', () {
      final mission = Mission.fromJson(_missionJson(
        id: 4,
        status: 'pending',
        displayStatus: 'available',
        pickupAddress: '12 Rue Didouche, Alger',
        dropoffAddress: 'Aéroport Houari Boumediene',
      ));
      final item = DriverMissionStore.fromBackendMission(mission);
      expect(item.from, '12 Rue Didouche, Alger');
      expect(item.to, 'Aéroport Houari Boumediene');
      expect(item.dist, '137.5 km');
    });

    test('falls back to labels instead of raw coordinates', () {
      final mission = Mission.fromJson(_missionJson(
        id: 5,
        status: 'pending',
        displayStatus: 'available',
      ));
      final labels = DriverMissionStore.addressLabels(mission);
      expect(labels.from, 'Pickup');
      expect(labels.to, 'Drop-off');
      final item = DriverMissionStore.fromBackendMission(mission);
      expect(item.from, isNot(contains('36.7538')));
      expect(item.to, isNot(contains('35.6962')));
      expect(item.dist, contains('km'));
    });
  });

  group('DriverMissionFilters (M4)', () {
    final rows = [
      _row(
          truck: 'camion',
          price: '12,500 DZD net',
          dist: '150 km',
          date: '2026-11-20 09:00'),
      _row(
          truck: 'fourgon',
          price: '18,000 DZD',
          dist: '450 km',
          date: '2026-11-19 09:00'),
      _row(
          truck: 'camion',
          price: '25,000 DZD',
          dist: '700 km',
          date: '2026-11-21 09:00'),
    ];

    test('filters by vehicle, price and distance', () {
      expect(
        const DriverMissionFilters(vehicleType: 'Camion').apply(rows),
        hasLength(2),
      );
      expect(
        const DriverMissionFilters(priceRange: '> 20,000').apply(rows),
        hasLength(1),
      );
      expect(
        const DriverMissionFilters(distanceRange: '200 - 400 km').apply(rows),
        isEmpty,
      );
    });

    test('sorts by price and date', () {
      final byPriceDesc =
          const DriverMissionFilters(sortBy: 'Price ↓').apply(rows);
      expect(byPriceDesc.first['price'], '25,000 DZD');
      final byDate = const DriverMissionFilters().apply(rows);
      expect(byDate.first['date'], '2026-11-19 09:00');
    });
  });

  group('Persisted verification decisions (C5)', () {
    test('accepts only decisions for the current documents version', () {
      final results = <String, dynamic>{
        'selfie': {
          'final_decision': 'ACCEPT',
          'quality_status': 'GOOD',
          'reason_codes': ['ok'],
          'documents_version': 4,
        },
      };
      final current = readPersistedDecision(results, 'selfie', 4);
      expect(current, isNotNull);
      expect(current!.passedFor(4), isTrue);
      expect(current.reasons, 'ok');
      expect(readPersistedDecision(results, 'selfie', 5), isNull);
    });

    test('REJECT is not a passing decision', () {
      final rejected = DriverVerificationDecision.fromBackend('selfie', {
        'final_decision': 'REJECT',
        'quality_status': 'BLURRY',
        'documents_version': 4,
      });
      expect(rejected.rejected, isTrue);
      expect(rejected.passedFor(4), isFalse);
    });
  });
}
