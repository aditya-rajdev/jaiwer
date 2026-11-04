import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/config/app_config.dart';

void main() {
  group('ApiConfig & Refresh Contract', () {
    test('ApiConfig has correct refresh endpoint URL', () {
      expect(ApiConfig.refreshAuthUrl, equals('https://jaiwer-backend.onrender.com/auth/refresh'));
    });

    test('ApiConfig has valid market rates and customer endpoints', () {
      expect(ApiConfig.goldRatesUrl, equals('https://jaiwer-backend.onrender.com/market-rates/gold'));
      expect(ApiConfig.silverRatesUrl, equals('https://jaiwer-backend.onrender.com/market-rates/silver'));
      expect(ApiConfig.addCustomerUrl, equals('https://jaiwer-backend.onrender.com/add-customer'));
    });
  });
}
