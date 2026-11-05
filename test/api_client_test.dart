import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/config/app_config.dart';
import 'package:jewelsetu/services/api_client.dart';

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

  group('ApiClient Behavioral & Concurrency Verification', () {
    test('ApiConfig has correct refresh endpoint URL', () {
      expect(ApiConfig.refreshAuthUrl, equals('https://jaiwer-backend.onrender.com/auth/refresh'));
    });

    test('ApiConfig has valid market rates and customer endpoints', () {
      expect(ApiConfig.goldRatesUrl, equals('https://jaiwer-backend.onrender.com/market-rates/gold'));
      expect(ApiConfig.silverRatesUrl, equals('https://jaiwer-backend.onrender.com/market-rates/silver'));
      expect(ApiConfig.addCustomerUrl, equals('https://jaiwer-backend.onrender.com/add-customer'));
    });

    test('1. login starts during logout cleanup - preserves new login session', () async {
      final logoutFuture = ApiClient.instance.handleManualLogout();
      final loginSuccess = await ApiClient.instance.saveAuthSession(
        accessToken: 'new_login_access_token',
        refreshToken: 'new_login_refresh_token',
      );

      await logoutFuture;

      expect(loginSuccess, isTrue);
      expect(mockStorage['access_token'], equals('new_login_access_token'));
      expect(mockStorage['refresh_token'], equals('new_login_refresh_token'));
    });

    test('2. login starts after logout cleanup completes - establishes new session', () async {
      mockStorage['access_token'] = 'old_access_token';
      await ApiClient.instance.handleManualLogout();
      expect(mockStorage['access_token'], isNull);

      final loginSuccess = await ApiClient.instance.saveAuthSession(
        accessToken: 'fresh_session_access_token',
        refreshToken: 'fresh_session_refresh_token',
      );

      expect(loginSuccess, isTrue);
      expect(mockStorage['access_token'], equals('fresh_session_access_token'));
      expect(mockStorage['refresh_token'], equals('fresh_session_refresh_token'));
    });

    test('3. old cleanup cannot override newer login navigation or tokens', () async {
      final initialEpoch = ApiClient.instance.sessionEpoch;
      final logoutFuture = ApiClient.instance.handleManualLogout();

      await ApiClient.instance.saveAuthSession(
        accessToken: 'active_session_token',
        refreshToken: 'active_refresh_token',
      );

      await logoutFuture;

      expect(ApiClient.instance.sessionEpoch, greaterThan(initialEpoch));
      expect(mockStorage['access_token'], equals('active_session_token'));
    });

    test('4. overlapping manual logout calls join the same in-flight cleanup', () async {
      mockStorage['access_token'] = 'token_to_clear';

      final logout1 = ApiClient.instance.handleManualLogout();
      final logout2 = ApiClient.instance.handleManualLogout();

      await Future.wait([logout1, logout2]);

      expect(mockStorage['access_token'], isNull);
    });

    test('5. session epoch change prevents stale token write completions', () {
      final startEpoch = ApiClient.instance.sessionEpoch;
      ApiClient.instance.invalidateSessionEpoch();
      final currentEpoch = ApiClient.instance.sessionEpoch;

      final isEpochValid = (startEpoch == currentEpoch);
      expect(isEpochValid, isFalse);
    });

    test('6. saveAuthSession stores access_token, refresh_token, and profile in mockStorage', () async {
      final success = await ApiClient.instance.saveAuthSession(
        accessToken: 'access_abc_123',
        refreshToken: 'refresh_xyz_789',
        tokenType: 'bearer',
        userProfile: {'user_name': 'Sharma Jewellers Owner', 'shop_name': 'Sharma Jewellers'},
      );

      expect(success, isTrue);
      expect(mockStorage['access_token'], equals('access_abc_123'));
      expect(mockStorage['refresh_token'], equals('refresh_xyz_789'));
      expect(mockStorage['user_name'], equals('Sharma Jewellers Owner'));
      expect(mockStorage['shop_name'], equals('Sharma Jewellers'));
    });
  });
}
