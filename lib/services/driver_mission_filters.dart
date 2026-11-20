/// Local, deterministic filters for the driver's available-mission list.
///
/// The backend owns mission state and pricing; these filters only reorder and
/// hide rows already returned by `/api/missions/available/`.
class DriverMissionFilters {
  final String vehicleType;
  final String priceRange;
  final String distanceRange;
  final String sortBy;

  const DriverMissionFilters({
    this.vehicleType = 'All',
    this.priceRange = 'All',
    this.distanceRange = 'All',
    this.sortBy = 'Date',
  });

  bool get isActive =>
      vehicleType != 'All' ||
      priceRange != 'All' ||
      distanceRange != 'All' ||
      sortBy != 'Date';

  List<Map<String, String>> apply(List<Map<String, String>> missions) {
    final filtered = <Map<String, String>>[];
    for (final mission in missions) {
      if (_matchesVehicle(mission) &&
          _matchesPrice(mission) &&
          _matchesDistance(mission)) {
        filtered.add(mission);
      }
    }

    switch (sortBy) {
      case 'Price ↑':
        filtered.sort((a, b) => _number(a['price']).compareTo(_number(b['price'])));
        break;
      case 'Price ↓':
        filtered.sort((a, b) => _number(b['price']).compareTo(_number(a['price'])));
        break;
      case 'Distance':
        filtered.sort((a, b) => _number(a['dist']).compareTo(_number(b['dist'])));
        break;
      default:
        filtered.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
    }
    return filtered;
  }

  bool _matchesVehicle(Map<String, String> m) {
    if (vehicleType == 'All') return true;
    return (m['truck'] ?? '').toLowerCase() == vehicleType.toLowerCase();
  }

  bool _matchesPrice(Map<String, String> m) {
    if (priceRange == 'All') return true;
    final value = _number(m['price']);
    return switch (priceRange) {
      '< 10,000' => value < 10000,
      '10,000 - 15,000' => value >= 10000 && value <= 15000,
      '15,000 - 20,000' => value > 15000 && value <= 20000,
      '> 20,000' => value > 20000,
      _ => true,
    };
  }

  bool _matchesDistance(Map<String, String> m) {
    if (distanceRange == 'All') return true;
    final value = _number(m['dist']);
    return switch (distanceRange) {
      '< 200 km' => value < 200,
      '200 - 400 km' => value >= 200 && value <= 400,
      '400 - 600 km' => value > 400 && value <= 600,
      '> 600 km' => value > 600,
      _ => true,
    };
  }

  /// Strip currency separators/units from values such as `12,500 DZD net`
  /// or `135.2 km`. Unparseable values sort/filter as zero.
  static double _number(String? raw) {
    if (raw == null) return 0;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
