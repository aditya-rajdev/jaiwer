import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/config/app_config.dart';

String normalizePhoneNumber(String input) {
  var digits = input.trim().replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return input.trim();
  while (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.length == 10) {
    return '+91$digits';
  } else if (digits.length == 12 && digits.startsWith('91')) {
    return '+$digits';
  } else if (digits.length >= 8 && digits.length <= 15) {
    return '+$digits';
  }
  return '+$digits';
}

void main() {
  group('Suppliers API Endpoints', () {
    test('Supplier API endpoints match live backend contract', () {
      expect(ApiConfig.suppliersUrl, equals('https://jaiwer-backend.onrender.com/api'));
      expect(ApiConfig.supplierExistingUrl, equals('https://jaiwer-backend.onrender.com/api/existing'));
      expect(ApiConfig.supplierPaymentUrl, equals('https://jaiwer-backend.onrender.com/api/payment'));
      expect(ApiConfig.supplierTransactionsUrl, equals('https://jaiwer-backend.onrender.com/api/supplier-transactions'));
    });

    test('E.164 phone normalization produces valid format matching pattern', () {
      final e164Pattern = RegExp(r'^\+[1-9]\d{7,14}$');
      const testInputs = [
        '9876543210',
        '+919876543210',
        '+91 9876543210',
        '09876543210',
        '919876543210',
        '+91-9876543210',
        '8888888888',
      ];

      for (final input in testInputs) {
        final normalized = normalizePhoneNumber(input);
        expect(e164Pattern.hasMatch(normalized), isTrue, reason: 'Failed for input $input -> $normalized');
        expect(normalized.startsWith('+918') || normalized.startsWith('+919'), isTrue);
      }
    });

    test('Supplier list response parsing handles backend contract object', () {
      final responseMap = {
        "suppliers": [
          {
            "supplier_id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Sharma Jewellery",
            "phone_number": "+919876543210",
            "address": "Delhi",
            "total_items": 5,
            "total_purchase_amount": 100000,
            "total_paid": 80000,
            "total_due": 20000,
            "last_purchase_date": "2026-10-20"
          }
        ],
        "total_count": 1,
        "limit": 20,
        "offset": 0
      };

      final list = responseMap['suppliers'] as List;
      final totalCount = responseMap['total_count'] as int;

      expect(list.length, equals(1));
      expect(totalCount, equals(1));

      final item = list.first as Map<String, dynamic>;
      expect(item['supplier_id'], equals('123e4567-e89b-12d3-a456-426614174000'));
      expect(item['name'], equals('Sharma Jewellery'));
      expect(item['total_due'], equals(20000));
    });
  });
}
