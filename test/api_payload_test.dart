import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orizzonte/order_model.dart';
import 'package:orizzonte/services/api_payload.dart';

/// Regression: the backend's GPS fields are DecimalField(decimal_places=6).
/// Device coordinates with more decimals previously produced
/// "Ensure that there are no more than 6 decimal places."
int _decimalPlaces(num value) {
  final text = value.toString();
  if (!text.contains('.')) return 0;
  return text.split('.').last.length;
}

OrderData _orderWithCoordinates({
  required double departureLat,
  required double departureLng,
  required double arrivalLat,
  required double arrivalLng,
}) {
  return OrderData(
    pickupCoords: {'lat': departureLat, 'lng': departureLng},
    deliveryCoords: {'lat': arrivalLat, 'lng': arrivalLng},
  );
}

void main() {
  group('ApiPayload GPS coordinate rounding', () {
    test('common() rounds all four GPS fields to 6 decimal places', () {
      final payload = ApiPayload.common(_orderWithCoordinates(
        departureLat: 36.7538123456,
        departureLng: 3.0588123456,
        arrivalLat: 35.6987654321,
        arrivalLng: -0.6349123456,
      ));

      expect(payload['departure_latitude'], 36.753812);
      expect(payload['departure_longitude'], 3.058812);
      expect(payload['arrival_latitude'], 35.698765);
      expect(payload['arrival_longitude'], -0.634912);

      for (final key in [
        'departure_latitude',
        'departure_longitude',
        'arrival_latitude',
        'arrival_longitude',
      ]) {
        expect(
          _decimalPlaces(payload[key] as num),
          lessThanOrEqualTo(6),
          reason: '$key has more than 6 decimal places',
        );
      }
    });

    test('serialised JSON never contains more than 6 decimals for GPS fields', () {
      final payload = ApiPayload.common(_orderWithCoordinates(
        departureLat: 36.7538123456,
        departureLng: 3.0588123456,
        arrivalLat: 35.6987654321,
        arrivalLng: -0.6349123456,
      ));
      final encoded = json.encode(payload);

      expect(encoded, contains('"departure_latitude":36.753812'));
      expect(encoded, contains('"departure_longitude":3.058812'));
      expect(encoded, contains('"arrival_latitude":35.698765'));
      expect(encoded, contains('"arrival_longitude":-0.634912'));
    });

    test('confirm() uses the same rounded coordinates', () {
      final payload = ApiPayload.confirm(
        _orderWithCoordinates(
          departureLat: 36.7538123456,
          departureLng: 3.0588123456,
          arrivalLat: 35.6987654321,
          arrivalLng: -0.6349123456,
        ),
        quoteId: 'quote-1',
      );

      expect(payload['departure_latitude'], 36.753812);
      expect(payload['arrival_longitude'], -0.634912);
    });

    test('values already at 6 decimals are unchanged, missing ones default to 0', () {
      final exact = ApiPayload.common(_orderWithCoordinates(
        departureLat: 36.753812,
        departureLng: 3.058812,
        arrivalLat: 35.698765,
        arrivalLng: -0.634912,
      ));
      expect(exact['departure_latitude'], 36.753812);
      expect(exact['arrival_longitude'], -0.634912);

      final missing = ApiPayload.common(OrderData());
      for (final key in [
        'departure_latitude',
        'departure_longitude',
        'arrival_latitude',
        'arrival_longitude',
      ]) {
        expect(missing[key], 0.0);
      }
    });
  });
}
