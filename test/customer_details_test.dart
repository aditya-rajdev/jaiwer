import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Customer Details Phone Normalization', () {
    String displayPhone(String raw) {
      var trimmed = raw.trim();
      if (trimmed.isEmpty) return 'No phone number';
      while (trimmed.startsWith('+91') ||
          trimmed.startsWith('+ 91') ||
          (trimmed.startsWith('91') &&
              trimmed.replaceAll(RegExp(r'[^0-9]'), '').length > 10)) {
        if (trimmed.startsWith('+91')) {
          trimmed = trimmed.substring(3).trim();
        } else if (trimmed.startsWith('+ 91')) {
          trimmed = trimmed.substring(4).trim();
        } else if (trimmed.startsWith('91')) {
          trimmed = trimmed.substring(2).trim();
        }
      }
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) {
        return '+91 $digits';
      }
      return '+91 $digits';
    }

    String e164Phone(String raw) {
      var trimmed = raw.trim();
      while (trimmed.startsWith('+91') ||
          trimmed.startsWith('+ 91') ||
          (trimmed.startsWith('91') &&
              trimmed.replaceAll(RegExp(r'[^0-9]'), '').length > 10)) {
        if (trimmed.startsWith('+91')) {
          trimmed = trimmed.substring(3).trim();
        } else if (trimmed.startsWith('+ 91')) {
          trimmed = trimmed.substring(4).trim();
        } else if (trimmed.startsWith('91')) {
          trimmed = trimmed.substring(2).trim();
        }
      }
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) return '+91$digits';
      return '+$digits';
    }

    test('Prevents duplicate +91 in phone display', () {
      expect(displayPhone('+91 +917011938465'), equals('+91 7011938465'));
      expect(displayPhone('+917011938465'), equals('+91 7011938465'));
      expect(displayPhone('7011938465'), equals('+91 7011938465'));
    });

    test('Generates clean E.164 phone for call and SMS', () {
      expect(e164Phone('+91 +917011938465'), equals('+917011938465'));
      expect(e164Phone('7011938465'), equals('+917011938465'));
    });
  });
}
