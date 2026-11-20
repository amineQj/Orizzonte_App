import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:orizzonte/services/routing_service.dart';

void main() {
  group('RoutingService & Haversine distance tests', () {
    test('Haversine distance calculates reasonable distance between known points', () {
      // Algiers (approx 36.7538, 3.0588) to Oran (approx 35.6987, -0.6349) ~ 350-400 km
      const algiers = LatLng(36.7538, 3.0588);
      const oran = LatLng(35.6987, -0.6349);

      final distance = RoutingService.haversineDistance(algiers, oran);
      expect(distance, greaterThan(340.0));
      expect(distance, lessThan(420.0));
    });

    test('RouteResult formats distance and duration correctly', () {
      const result = RouteResult(
        distanceKm: 15.482,
        durationMinutes: 16.2,
        points: [LatLng(36.75, 3.05), LatLng(36.70, 3.10)],
        isRoadRoute: true,
      );

      expect(result.formattedDistance, '15.48 km');
      expect(result.formattedDuration(), '~16 min');
    });

    test('RouteResult formats longer duration in hours and minutes', () {
      const result = RouteResult(
        distanceKm: 120.0,
        durationMinutes: 95.0,
        points: [],
        isRoadRoute: true,
      );

      expect(result.formattedDuration(), '~1 h 35 min');
    });

    test('RoutingService getRoute parses an OSRM response without the network', () async {
      final client = _OsrmClient();
      const start = LatLng(36.7525, 3.0420);
      const end = LatLng(36.7450, 3.0600);

      final result = await RoutingService.getRoute(
        start: start,
        end: end,
        client: client,
      );
      expect(result.distanceKm, greaterThan(0.0));
      expect(result.isRoadRoute, isTrue);
      expect(result.points, isNotEmpty);
    });
  });
}

class _OsrmClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({
      'code': 'Ok',
      'routes': [
        {
          'distance': 1234.0,
          'duration': 567.0,
          'geometry': {
            'coordinates': [
              [3.0420, 36.7525],
              [3.0600, 36.7450],
            ],
          },
        },
      ],
    });
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}
