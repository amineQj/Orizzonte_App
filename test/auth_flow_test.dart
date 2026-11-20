import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:orizzonte/auth_flow.dart';
import 'package:orizzonte/models/api_models.dart';
import 'package:orizzonte/services/api_service.dart';
import 'package:orizzonte/services/auth_service.dart';

/// Canned auth response used by both signup and resend tests.
class _RecordingClient extends http.BaseClient {
  _RecordingClient({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
  Uri? lastUrl;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(json.encode(body))),
      statusCode,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

AuthService _authFor(_RecordingClient client) =>
    AuthService(api: ApiService(client: client));

String _spanText(InlineSpan span) {
  if (span is! TextSpan) return '';
  return '${span.text ?? ''}${span.children?.map(_spanText).join() ?? ''}';
}

/// Matches plain Text and split RichText spans (used for the email line and
/// the resend countdown).
Finder _containsText(String value) => find.byWidgetPredicate(
      (widget) =>
          (widget is Text && (widget.data ?? '').contains(value)) ||
          (widget is RichText && _spanText(widget.text).contains(value)),
    );

/// Auth screens are tall ListViews; give the test view enough room so every
/// field and the resend row are built instead of staying lazily offstage.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Map<String, dynamic> _signupBody() => {
      'message': 'Account created successfully. A verification email has been sent.',
      'user': {
        'id': 7,
        'username': 'ada',
        'email': 'ada@example.com',
        'role': 'driver',
        'email_verified': false,
        'date_joined': '2026-11-19T00:00:00Z',
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real signup / resend contracts', () {
    test('signup posts role to /api/signup/ and returns no tokens', () async {
      final client = _RecordingClient(statusCode: 201, body: _signupBody());

      final response =
          await _authFor(client).signup('ada@example.com', 'Strong!123', 'driver');

      expect(client.lastUrl!.path, '/api/signup/');
      expect(client.lastHeaders!['Authorization'], isNull);
      final sent = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(sent['username'], 'ada');
      expect(sent['email'], 'ada@example.com');
      expect(sent['password'], 'Strong!123');
      expect(sent['role'], 'driver');
      expect(response.accessToken, isEmpty);
      expect(response.refreshToken, isEmpty);
      expect(response.user.email, 'ada@example.com');
    });

    test('resend 429 keeps its status code and backend detail', () async {
      final client = _RecordingClient(
        statusCode: 429,
        body: {'detail': 'Too many requests.'},
      );

      expect(
        () => _authFor(client).resendVerification('ada@example.com'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.message, 'message', 'Too many requests.'),
        ),
      );
      expect(client.lastUrl!.path, '/api/resend-verification/');
    });
  });

  group('Flutter auth screens', () {
    testWidgets('signup calls the backend before showing check-email',
        (tester) async {
      _useTallView(tester);
      final client = _RecordingClient(statusCode: 201, body: _signupBody());
      String? capturedEmail;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignupScreen(
              onNext: (email) => capturedEmail = email,
              onLogin: () {},
              onBack: () {},
              role: 'driver',
              auth: _authFor(client),
            ),
          ),
        ),
      );

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(6));
      await tester.enterText(fields.at(0), 'Ada');
      await tester.enterText(fields.at(1), 'Lovelace');
      await tester.enterText(fields.at(2), 'ada@example.com');
      await tester.enterText(fields.at(3), '555000000');
      await tester.enterText(fields.at(4), 'Strong!123');
      await tester.enterText(fields.at(5), 'Strong!123');
      await tester.tap(_containsText('I agree to the'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account').last);
      await tester.pumpAndSettle();

      expect(capturedEmail, 'ada@example.com');
      expect(client.lastUrl!.path, '/api/signup/');
      expect(jsonDecode(client.lastBody!)['role'], 'driver');
    });

    testWidgets('check-email screen has no OTP entry and resends after cooldown',
        (tester) async {
      _useTallView(tester);
      final client = _RecordingClient(
        statusCode: 200,
        body: {
          'message': 'If an account exists with this email, '
              'a verification email has been sent.'
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckEmailScreen(
              email: 'ada@example.com',
              onLogin: () {},
              onBack: () {},
              auth: _authFor(client),
            ),
          ),
        ),
      );

      expect(find.text('Check your email'), findsOneWidget);
      expect(_containsText('ada@example.com'), findsOneWidget);
      expect(find.text('Demo code: 123456'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(_containsText('Resend link in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(find.text('Resend link'), findsOneWidget);

      await tester.tap(find.text('Resend link'));
      await tester.pumpAndSettle();

      expect(client.lastUrl!.path, '/api/resend-verification/');
      expect(jsonDecode(client.lastBody!)['email'], 'ada@example.com');
      // The cooldown restarts after the request.
      expect(_containsText('Resend link in'), findsOneWidget);
    });

    testWidgets('check-email screen shows a clear message on 429',
        (tester) async {
      _useTallView(tester);
      final client = _RecordingClient(
        statusCode: 429,
        body: {'detail': 'Too many requests.'},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckEmailScreen(
              email: 'ada@example.com',
              onLogin: () {},
              onBack: () {},
              auth: _authFor(client),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resend link'));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many requests. Please wait before trying again.'),
        findsOneWidget,
      );
      expect(_containsText('Resend link in'), findsOneWidget);
    });

    testWidgets('auth flow has no forgot-password or reset entry points',
        (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthFlow(
            onSuccess: () {},
            onBossSuccess: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsNothing);
      expect(find.text('Reset Password'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2)); // email + password only
    });
  });
}
