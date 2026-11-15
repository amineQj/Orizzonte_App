import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'mission_notification_preferences.dart';
import 'notification_catalog.dart';

/// Contract for the server-side mission push pipeline.
///
/// The current project has no backend yet, so the real "mission appeared while
/// the app is closed" path cannot be completed. The client side exposes this
/// interface so the server integration (Firebase Cloud Messaging + an API that
/// decides which drivers to notify) can be plugged in later without touching
/// the UI.
abstract class MissionPushBackend {
  /// Registers this device token for a driver so the server can target them.
  Future<void> registerDeviceToken({
    required String deviceToken,
    required String driverId,
  });

  /// Pushes the driver's notification preferences to the server so the
  /// server-side matching uses the same filters.
  Future<void> syncPreferences(MissionNotificationPreferences preferences);

  /// Asks the server to deliver a real push notification to [driverId]
  /// (used by the "Test notification" button when a backend is available).
  Future<void> sendTestPush({required String driverId});
}

class UnimplementedMissionPushBackend implements MissionPushBackend {
  const UnimplementedMissionPushBackend();

  @override
  Future<void> registerDeviceToken({
    required String deviceToken,
    required String driverId,
  }) async {
    throw UnsupportedError(
      'Remote push notifications are not wired yet. A backend exposing '
      'registerDeviceToken() (e.g. Firebase Cloud Messaging) is required.',
    );
  }

  @override
  Future<void> syncPreferences(
    MissionNotificationPreferences preferences,
  ) async {
    throw UnsupportedError(
      'Remote push notifications are not wired yet. A backend exposing '
      'syncPreferences() is required to apply these filters server-side.',
    );
  }

  @override
  Future<void> sendTestPush({required String driverId}) async {
    throw UnsupportedError(
      'Remote test push is not available yet. Send FCM test messages from the '
      'Firebase console instead.',
    );
  }
}

/// Represents a single mission that could trigger a notification.
class MissionCandidate {
  /// Free-form region text (mission departure area) e.g. "Algiers".
  final String regionText;

  /// Truck family the mission requires, e.g. "Camion".
  final String truckType;

  /// Truck size the mission requires, e.g. "Large".
  final String truckSize;

  /// Whether the mission is still open/eligible for new drivers.
  final bool eligible;

  const MissionCandidate({
    this.regionText = '',
    this.truckType = '',
    this.truckSize = '',
    this.eligible = true,
  });
}

/// Why a notification was (or was not) sent.
enum NotificationFilter {
  region,
  vehicle,
  schedule,
  osPermission,
  disabled,
  notEligible,
}

/// Client-side notification orchestration.
///
/// Responsibilities:
///  * Initialise the local notification channel (Android).
///  * Check / request the OS notification permission.
///  * Show an immediate test notification (works while the app is in the
///    foreground or background; used to verify the setup).
///  * Decide, given a mission and the driver preferences, whether it should
///    trigger a notification (`shouldNotify` / `blockingFilter`).
///
/// REAL push notifications while the app is killed REQUIRE a backend:
/// see [MissionPushBackend] and the README notes below. This service mirrors
/// the checks the backend must also perform, and exposes them here so the app
/// behaves consistently when it is running.
class MissionNotificationService {
  MissionNotificationService._();
  static final instance = MissionNotificationService._();

  /// Server integration. Swap with a real implementation once a backend exists.
  final MissionPushBackend backend = const UnimplementedMissionPushBackend();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool? _osNotificationsEnabled;

  /// Payload of the last notification the user tapped, if any.
  String? lastTappedNotificationPayload;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          lastTappedNotificationPayload = response.payload;
        },
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'mission_notifications',
          'Mission notifications',
          description: 'Notifications when a mission matches your preferences',
          importance: Importance.high,
        ),
      );
      _osNotificationsEnabled =
          await android?.areNotificationsEnabled() ?? false;
    } else {
      _osNotificationsEnabled = true;
    }
    _initialized = true;
  }

  /// Cached OS-level notification permission for this app.
  bool? get osNotificationsEnabled => _osNotificationsEnabled;

  /// Asks the user for the notification permission (Android 13+ shows the
  /// system dialog). Returns true when notifications are allowed.
  Future<bool> requestPermission() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission();
      if (granted == null) {
        _osNotificationsEnabled =
            await android.areNotificationsEnabled() ?? false;
      } else {
        _osNotificationsEnabled = granted;
      }
      return _osNotificationsEnabled ?? false;
    }
    return true;
  }

  /// Re-reads the OS permission (catches the user turning notifications off
  /// in the system settings while the app is open).
  Future<bool> refreshPermissionStatus() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _osNotificationsEnabled =
          await android?.areNotificationsEnabled() ?? false;
    } else {
      _osNotificationsEnabled = true;
    }
    return _osNotificationsEnabled ?? false;
  }

  /// Shows an immediate notification so the driver can verify that
  /// notifications are working, regardless of real missions.
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mission_notifications',
        'Mission notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      id: 9001,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'mission_notifications_test',
    );
  }

  // ---------------------------------------------------------------------------
  // Matching logic
  // ---------------------------------------------------------------------------

  /// Checks every condition of the notification pipeline.
  ///
  ///  1. Master switch enabled
  ///  2. OS notification permission available
  ///  3. Mission region matches the selected regions (if any)
  ///  4. Driver truck can handle the mission
  ///  5. Current time inside the notification schedule
  ///  6. Mission still eligible
  ///
  /// Returns the first blocking condition, or null when a notification
  /// should be sent.
  NotificationFilter? blockingFilter({
    required MissionCandidate mission,
    required MissionNotificationPreferences prefs,
    required bool osPermissionGranted,
    DateTime? at,
  }) {
    if (!prefs.enabled) return NotificationFilter.disabled;
    if (!osPermissionGranted) return NotificationFilter.osPermission;
    if (!_regionMatches(mission, prefs)) return NotificationFilter.region;
    if (!_vehicleMatches(mission, prefs)) return NotificationFilter.vehicle;
    if (!_withinSchedule(prefs, at ?? DateTime.now())) {
      return NotificationFilter.schedule;
    }
    if (!mission.eligible) return NotificationFilter.notEligible;
    return null;
  }

  /// Convenience wrapper around [blockingFilter].
  bool shouldNotify({
    required MissionCandidate mission,
    required MissionNotificationPreferences prefs,
    required bool osPermissionGranted,
    DateTime? at,
  }) =>
      blockingFilter(
        mission: mission,
        prefs: prefs,
        osPermissionGranted: osPermissionGranted,
        at: at,
      ) ==
      null;

  bool _regionMatches(
    MissionCandidate mission,
    MissionNotificationPreferences prefs,
  ) {
    if (!prefs.hasRegionFilter) return true;
    if (mission.regionText.trim().isEmpty) return true;
    final region = regionForCity(mission.regionText);
    if (region == null) return true; // unknown region: do not block
    return prefs.selectedRegionCodes.contains('${region.code}');
  }

  bool _vehicleMatches(
    MissionCandidate mission,
    MissionNotificationPreferences prefs,
  ) {
    final preferredTruck = prefs.truckId;
    if (preferredTruck == null) return true;
    if (mission.truckType.trim().toLowerCase() !=
        preferredTruck.toLowerCase()) {
      return false;
    }
    final preferredSize = _sizeRank(prefs.truckSizeId);
    if (preferredSize == null) return true;
    return _missionSizeRank(mission.truckSize) <= preferredSize;
  }

  int? _sizeRank(String? sizeId) {
    if (sizeId == null) return null;
    for (final family in truckFamilies) {
      for (final size in family.sizes) {
        if (size.id == sizeId) return size.rank;
      }
    }
    return null;
  }

  int _missionSizeRank(String size) {
    final s = size.trim().toLowerCase();
    if (s.isEmpty || s == 'short' || s == 'small') return 1;
    if (s == 'medium' || s == 'mid') return 2;
    return 3; // long / large / anything bigger
  }

  bool _withinSchedule(MissionNotificationPreferences prefs, DateTime now) {
    if (prefs.alwaysReceive) {
      return true;
    }
    final nowMinute = now.hour * 60 + now.minute;
    final start = prefs.startMinute;
    final end = prefs.endMinute;
    if (start == end) return true; // full day
    if (start < end) return nowMinute >= start && nowMinute <= end;
    // Overnight window, e.g. 22:00 -> 06:00.
    return nowMinute >= start || nowMinute <= end;
  }
}
