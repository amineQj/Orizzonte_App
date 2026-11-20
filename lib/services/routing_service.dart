import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Represents the calculated route details between two points.
class RouteResult {
  final double distanceKm;
  final double? durationMinutes;
  final List<LatLng> points;
  final bool isRoadRoute;

  const RouteResult({
    required this.distanceKm,
    this.durationMinutes,
    this.points = const [],
    required this.isRoadRoute,
  });

  /// Formatted distance string (e.g. "12.34 km").
  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} km';

  /// Formatted duration string (e.g. "~15 min" or "~1 h 12 min").
  String? formattedDuration({String Function(String en, String ar, String fr)? t}) {
    if (durationMinutes == null) return null;
    final totalMinutes = durationMinutes!.round();
    if (totalMinutes < 1) {
      return t != null ? '< 1 ${t('min', 'دقيقة', 'min')}' : '< 1 min';
    }
    if (totalMinutes < 60) {
      final unit = t != null ? t('min', 'دقيقة', 'min') : 'min';
      return '~$totalMinutes $unit';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final hUnit = t != null ? t('h', 'ساعة', 'h') : 'h';
    final mUnit = t != null ? t('min', 'دقيقة', 'min') : 'min';
    if (mins == 0) return '~$hours $hUnit';
    return '~$hours $hUnit $mins $mUnit';
  }
}

/// Routing engine service that queries OSRM (Open Source Routing Machine)
/// to calculate real road route distance, trip duration, and geometry.
/// Automatically falls back to great-circle (Haversine) calculation if offline.
class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Calculates driving route between [start] and [end].
  /// Uses OSRM driving profile. If unavailable, falls back to Haversine.
  static Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng end,
    Duration timeout = const Duration(seconds: 8),
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      // OSRM expects coordinates in {lon},{lat} order
      final url = Uri.parse(
        '$_osrmBaseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
      );

      final response = await httpClient.get(
        url,
        headers: {'User-Agent': 'OrizzonteApp/1.0'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final double durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;
          final distanceKm = distanceMeters / 1000.0;
          final durationMinutes = durationSeconds / 60.0;

          final List<LatLng> points = [];
          final geometry = route['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            for (final coord in coords) {
              if (coord is List && coord.length >= 2) {
                final lon = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                points.add(LatLng(lat, lon));
              }
            }
          }

          if (points.isEmpty) {
            points.addAll([start, end]);
          }

          return RouteResult(
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
            points: points,
            isRoadRoute: true,
          );
        }
      }
    } catch (_) {
      // Gracefully fall back to straight line on timeout or connection error
    } finally {
      if (ownsClient) httpClient.close();
    }

    final fallbackDist = haversineDistance(start, end);
    return RouteResult(
      distanceKm: fallbackDist,
      durationMinutes: null,
      points: [start, end],
      isRoadRoute: false,
    );
  }

  /// Haversine formula for spherical distance (in km).
  static double haversineDistance(LatLng p1, LatLng p2) {
    const double r = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) *
            cos(p2.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
