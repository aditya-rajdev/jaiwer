import 'package:flutter_test/flutter_test.dart';

void main() {
  group('New Customer Rate Per Gram Parsing', () {
    test('Rate per gram entered parses to double value', () {
      const input = '6,200';
      final rateStr = input.trim().replaceAll(',', '');
      final rateVal = rateStr.isNotEmpty ? double.tryParse(rateStr) : null;

      expect(rateVal, equals(6200.0));
    });

    test('Rate per gram blank parses to null', () {
      const input = '';
      final rateStr = input.trim().replaceAll(',', '');
      final rateVal = rateStr.isNotEmpty ? double.tryParse(rateStr) : null;

      expect(rateVal, isNull);
    });
  });
}
