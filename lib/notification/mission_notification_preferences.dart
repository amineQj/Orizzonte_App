import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Driver notification preferences.
///
/// Persisted locally with the already bundled `shared_preferences` package so
/// the driver's choices survive app restarts.
class MissionNotificationPreferences {
  static const _storageKey = 'mission_notification_preferences_v1';

  /// Master switch: are mission notifications enabled at all?
  bool enabled;

  /// Selected wilaya codes (from [regions]). Empty = all regions.
  final Set<String> selectedRegionCodes;

  /// Selected truck family id (e.g. 'camion'). Null = any vehicle type.
  String? truckId;

  /// Selected size id inside [truckId]. Null = any size.
  String? truckSizeId;

  /// Notification schedule (minutes since midnight).
  int startMinute;
  int endMinute;

  /// When true, the schedule is ignored and notifications are always allowed.
  bool alwaysReceive;

  MissionNotificationPreferences({
    this.enabled = true,
    Set<String>? selectedRegionCodes,
    this.truckId,
    this.truckSizeId,
    this.startMinute = 8 * 60,
    this.endMinute = 18 * 60,
    this.alwaysReceive = false,
  }) : selectedRegionCodes = selectedRegionCodes ?? <String>{};

  /// A copy used as the working state of the settings page.
  MissionNotificationPreferences copy() => MissionNotificationPreferences(
    enabled: enabled,
    selectedRegionCodes: Set.of(selectedRegionCodes),
    truckId: truckId,
    truckSizeId: truckSizeId,
    startMinute: startMinute,
    endMinute: endMinute,
    alwaysReceive: alwaysReceive,
  );

  bool get hasRegionFilter => selectedRegionCodes.isNotEmpty;

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'regions': selectedRegionCodes.toList(growable: false),
    'truckId': truckId,
    'truckSizeId': truckSizeId,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'alwaysReceive': alwaysReceive,
  };

  factory MissionNotificationPreferences.fromJson(Map<String, Object?> json) {
    final regions = (json['regions'] as List<dynamic>? ?? const [])
        .cast<String>();
    return MissionNotificationPreferences(
      enabled: json['enabled'] as bool? ?? true,
      selectedRegionCodes: regions.toSet(),
      truckId: json['truckId'] as String?,
      truckSizeId: json['truckSizeId'] as String?,
      startMinute: json['startMinute'] as int? ?? 8 * 60,
      endMinute: json['endMinute'] as int? ?? 18 * 60,
      alwaysReceive: json['alwaysReceive'] as bool? ?? false,
    );
  }
}

class MissionNotificationPreferencesStore {
  MissionNotificationPreferencesStore._();
  static final instance = MissionNotificationPreferencesStore._();

  MissionNotificationPreferences? _cached;

  Future<MissionNotificationPreferences> load() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(MissionNotificationPreferences._storageKey);
    if (raw == null) {
      _cached = MissionNotificationPreferences();
    } else {
      try {
        _cached = MissionNotificationPreferences.fromJson(
          jsonDecode(raw) as Map<String, Object?>,
        );
      } catch (_) {
        _cached = MissionNotificationPreferences();
      }
    }
    return _cached!;
  }

  Future<void> save(MissionNotificationPreferences preferences) async {
    _cached = preferences;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      MissionNotificationPreferences._storageKey,
      jsonEncode(preferences.toJson()),
    );
  }
}
