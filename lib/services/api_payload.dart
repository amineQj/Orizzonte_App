import '../order_model.dart';

/// Maps the app's free-form [OrderData] (built by the multi-step order flow)
/// onto the strict enums and numeric fields expected by the Django backend.
class ApiPayload {
  ApiPayload._();

  static const truckTypes = {'small', 'medium', 'large', 'extra_large'};
  static const categories = {'open', 'closed', 'refrigerated', 'flatbed'};
  static const sizes = {'small', 'medium', 'big'};
  static const vehicleClasses = {'standard', 'van', 'truck'};

  static String truckType(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('extra') || v.contains('xl') || v.contains('20t')) {
      return 'extra_large';
    }
    if (v.contains('camion') || v.contains('truck') || v.contains('large') ||
        v.contains('15t') || v.contains('10t')) {
      return 'large';
    }
    if (v.contains('harbina') || v.contains('medium') || v.contains('5t') ||
        v.contains('3.5t')) {
      return 'medium';
    }
    return 'small';
  }

  static String size(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('large') || v.contains('big') || v.contains('20t') ||
        v.contains('15t')) {
      return 'big';
    }
    if (v.contains('medium') || v.contains('5t') || v.contains('3.5t')) {
      return 'medium';
    }
    return 'small';
  }

  static String category(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('chemical') || v.contains('chimique')) return 'flatbed';
    if (v.contains('refriger') || v.contains('froid')) return 'refrigerated';
    if (v.contains('commercial') || v.contains('appliance')) return 'closed';
    return 'open';
  }

  static String vehicleClass(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('camion') || v.contains('truck') || v.contains('large') ||
        v.contains('porte') || v.contains('20t') || v.contains('15t')) {
      return 'truck';
    }
    if (v.contains('fourgon') || v.contains('harbina') || v.contains('van') ||
        v.contains('medium')) {
      return 'van';
    }
    return 'standard';
  }

  static int capacity(String weight) {
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(weight);
    if (m == null) return 1;
    final v = double.tryParse(m.group(1) ?? '') ?? 1;
    return v < 1 ? 1 : v.round();
  }

  static double? distanceKm(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (m == null) return null;
    return double.tryParse(m.group(1) ?? '');
  }

  static String date(OrderData o) {
    if (o.manualDate.trim().isNotEmpty) return o.manualDate.trim();
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String time(OrderData o) {
    if (o.manualTime.trim().isNotEmpty) return o.manualTime.trim();
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// The backend declares GPS fields as `DecimalField(max_digits=9,
  /// decimal_places=6)`. Device GPS values frequently carry 10+ decimals,
  /// which makes DRF reject the payload with
  /// "Ensure that there are no more than 6 decimal places."
  ///
  /// Round to exactly 6 places *before* the value is JSON-serialised. The API
  /// contract is unchanged — we still send a number, just a rounded one.
  static double coordinate(double? value) =>
      num.parse((value ?? 0.0).toStringAsFixed(6)).toDouble();

  static double _coord(Map<String, double>? coords, String key) =>
      coordinate(coords?[key]);

  /// Shared fields for estimate and confirm requests.
  static Map<String, dynamic> common(OrderData o) {
    final payload = <String, dynamic>{
      'truck_type': truckType(o.truckType),
      'category': category(o.category),
      'capacity': capacity(o.weight),
      'size': size(o.truckModel.isNotEmpty ? o.truckModel : o.truckType),
      'departure_latitude': _coord(o.pickupCoords, 'lat'),
      'departure_longitude': _coord(o.pickupCoords, 'lng'),
      'arrival_latitude': _coord(o.deliveryCoords, 'lat'),
      'arrival_longitude': _coord(o.deliveryCoords, 'lng'),
      'date': date(o),
      'time': time(o),
      'workers': o.helpers.clamp(0, 5),
      // Opt in to the new pricing engine so a quote_id is issued.
      'vehicle_class': vehicleClass(o.truckType),
      'helpers': o.helpers,
    };
    final distance = distanceKm(o.distance);
    if (distance != null && distance > 0) {
      payload['distance'] = distance.toStringAsFixed(2);
    }
    return payload;
  }

  static Map<String, dynamic> estimate(OrderData o) => common(o);

  static Map<String, dynamic> confirm(
    OrderData o, {
    String? quoteId,
    bool negotiable = false,
  }) {
    final payload = common(o);
    payload['shipment_type'] =
        o.shipmentType.trim().isEmpty ? 'house_moving' : o.shipmentType.trim();
    payload['phone_number'] = o.phoneNumber.trim();
    payload['negotiable'] = negotiable;
    if (quoteId != null && quoteId.isNotEmpty) {
      payload['quote_id'] = quoteId;
    }
    return payload;
  }
}
