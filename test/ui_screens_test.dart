import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:orizzonte/boss/boss_driver_detail_page.dart';
import 'package:orizzonte/boss/boss_mission_detail_page.dart';
import 'package:orizzonte/negotiation/negotiation_page.dart';
import 'package:orizzonte/services/api_service.dart';

/// Canned backend responses used to render the screens for visual proof.
class _FakeClient extends http.BaseClient {
  static final List<int> _png = base64.decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  static const Map<String, dynamic> driverDetail = {
    'user_id': 21,
    'full_name': 'Karim Benali',
    'username': 'karim.driver',
    'phone': '+213 555 12 34 56',
    'status': 'pending_review',
    'vehicle_plate': '12 AB 345',
    'documents': {
      'selfie': {'uploaded': true},
      'id_card_front': {'uploaded': true},
      'id_card_back': {'uploaded': true},
      'driving_license': {'uploaded': true},
      'vehicle_registration': {'uploaded': false},
    },
  };

  static const Map<String, dynamic> mission = {
    'id': 42,
    'status': 'pending',
    'shipment_type': 'Furniture',
    'phone_number': '+213 660 11 22 33',
    'truck_type': 'camion',
    'size': 'large',
    'category': 'household',
    'capacity': 3500,
    'departure_latitude': 36.753812,
    'departure_longitude': 3.058756,
    'arrival_latitude': 36.751999,
    'arrival_longitude': 3.061123,
    'distance': 12.4,
    'date': '2026-11-22',
    'time': '09:30',
    'workers': 2,
    'price': 67500,
    'negotiable': true,
    'client': {
      'id': 7,
      'full_name': 'Alice Mansouri',
      'username': 'alice',
      'email': 'alice@example.com',
    },
    'assigned_employee': {'id': 21, 'full_name': 'Karim Benali'},
  };

  static Map<String, dynamic> get negotiation => {
        'id': 9,
        'mission_id': 42,
        'status': 'open',
        'currency': 'DZD',
        'initial_price': 70000,
        'current_amount': 67500,
        'min_amount': 60000,
        'max_amount': 80000,
        'min_fare': 55000,
        'max_offers': 3,
        'min_step': 500,
        'offer_count': 2,
        'is_final': false,
        'your_turn': true,
        'offers': [
          {
            'id': 31,
            'sequence': 1,
            'amount': 70000,
            'author_role': 'client',
            'is_final': false,
            'created_at': '2026-11-19T09:00:00Z',
          },
          {
            'id': 32,
            'sequence': 2,
            'amount': 67500,
            'author_role': 'driver',
            'is_final': false,
            'created_at': '2026-11-19T09:05:00Z',
          },
        ],
        'calibrated': false,
        'config_version': 1,
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 24))
            .toIso8601String(),
      };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    if (path.contains('/documents/')) {
      return http.StreamedResponse(
        Stream.value(_png),
        200,
        headers: {'content-type': 'image/png'},
        request: request,
      );
    }
    dynamic body;
    if (path == '/api/drivers/21/') {
      body = driverDetail;
    } else if (path == '/api/missions/employee/21/') {
      body = <dynamic>[];
    } else if (path == '/api/missions/all/') {
      body = <String, dynamic>{'results': <dynamic>[mission]};
    } else if (path == '/api/missions/42/negotiation/') {
      body = negotiation;
    } else {
      body = <String, dynamic>{'detail': 'Unexpected test request: $path'};
    }
    final bytes = utf8.encode(json.encode(body));
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

Future<void> _pumpAndSettle(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(MaterialApp(home: widget));
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Poppins is not bundled as a test asset; disable runtime fetching so the
    // shared appPop() helper renders the default font in these golden tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('boss driver detail screenshot', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final api = ApiService(client: _FakeClient());
    await _pumpAndSettle(
      tester,
      BossDriverDetailPage(driverId: 21, driverName: 'Karim Benali', api: api),
    );

    expect(find.text('Karim Benali'), findsWidgets);
    expect(find.text('Driving license'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    await expectLater(
      find.byType(BossDriverDetailPage),
      matchesGoldenFile('goldens/boss_driver_detail.png'),
    );
  });

  testWidgets('boss mission detail screenshot', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final api = ApiService(client: _FakeClient());
    await _pumpAndSettle(
      tester,
      BossMissionDetailPage(missionId: 42, api: api),
    );

    expect(find.text('Alice Mansouri'), findsOneWidget);
    expect(find.text('Assign driver'), findsWidgets);
    await expectLater(
      find.byType(BossMissionDetailPage),
      matchesGoldenFile('goldens/boss_mission_detail.png'),
    );
  });

  testWidgets('negotiation screenshot', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final api = ApiService(client: _FakeClient());
    await _pumpAndSettle(
      tester,
      NegotiationPage(missionId: 42, api: api),
    );

    expect(find.text('Your turn'), findsOneWidget);
    expect(find.text('Offer timeline'), findsOneWidget);
    expect(find.text('Send offer'), findsOneWidget);
    await expectLater(
      find.byType(NegotiationPage),
      matchesGoldenFile('goldens/negotiation.png'),
    );
  });
}
