import 'package:flutter_test/flutter_test.dart';
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

    test('RoutingService getRoute fetches road route from OSRM', () async {
      // Coordinates close to each other in Algiers
      const start = LatLng(36.7525, 3.0420);
      const end = LatLng(36.7450, 3.0600);

      final result = await RoutingService.getRoute(start: start, end: end);
      expect(result.distanceKm, greaterThan(0.0));
      expect(result.points.isNotEmpty, true);
    });
  });
}
