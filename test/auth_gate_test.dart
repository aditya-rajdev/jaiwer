import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/app.dart';
import 'package:jewelsetu/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:jewelsetu/features/onboarding/presentation/screens/role_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> mockStorage = {};

  setUp(() {
    mockStorage.clear();
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      final args = methodCall.arguments as Map?;
      final key = args?['key']?.toString();
      final value = args?['value']?.toString();

      if (methodCall.method == 'read') {
        return key != null ? mockStorage[key] : null;
      }
      if (methodCall.method == 'readAll') {
        return mockStorage;
      }
      if (methodCall.method == 'write') {
        if (key != null && value != null) mockStorage[key] = value;
        return true;
      }
      if (methodCall.method == 'delete') {
        if (key != null) mockStorage.remove(key);
        return true;
      }
      if (methodCall.method == 'deleteAll') {
        mockStorage.clear();
        return true;
      }
      return null;
    });
  });

  group('AuthGate Widget & Lifecycle Verification', () {
    testWidgets('1. AuthGate renders RoleSelectionScreen when session is missing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
    });

    testWidgets('2. AuthGate renders DashboardScreen when valid session is present', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final exp = now + 3600;
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final payloadJson = jsonEncode({'exp': exp, 'user_id': 'user_123'});
      final payloadBase64 = base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
      mockStorage['access_token'] = '$header.$payloadBase64.signature';
      mockStorage['refresh_token'] = 'valid_refresh_token';

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('3. Expired token with refresh token present attempts refresh and retains offline session', (tester) async {
      final past = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final payloadJson = jsonEncode({'exp': past, 'user_id': 'user_123'});
      final payloadBase64 = base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
      mockStorage['access_token'] = '$header.$payloadBase64.signature';
      mockStorage['refresh_token'] = 'valid_offline_refresh_token';

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
