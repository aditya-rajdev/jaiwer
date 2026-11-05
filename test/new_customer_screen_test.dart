import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> buildExistingCustomerPayload({
  required String phone,
  required String? receiver,
  required bool payPerItem,
  required double overallPaid,
  required String itemName,
  required double weight,
  required double? rate,
  required double totalAmount,
  required double itemPaid,
}) {
  final paymentMode = payPerItem ? 'item_wise' : 'total';
  const paymentMethod = 'cash';

  return <String, dynamic>{
    'phone_number': phone,
    if (receiver?.trim().isNotEmpty == true) 'receiver': receiver!.trim(),
    'payment_mode': paymentMode,
    'payment_method': paymentMethod,
    if (!payPerItem) 'total_payment': overallPaid,
    'items': [
      <String, dynamic>{
        'item_name': itemName,
        'weight_grams': weight,
        if (rate != null) 'rate_per_gram': rate,
        'total_amount': totalAmount,
        if (payPerItem) 'amount_paid': itemPaid,
      }
    ],
  };
}

void main() {
  group('New Customer & Existing Customer Payment Mode Payloads', () {
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

    test('Item-wise mode excludes total_payment and includes item-level amount_paid', () {
      final payload = buildExistingCustomerPayload(
        phone: '+919876543210',
        receiver: 'Rahul Sharma',
        payPerItem: true,
        overallPaid: 500,
        itemName: 'Gold Ring',
        weight: 5.0,
        rate: 1400.0,
        totalAmount: 7000.0,
        itemPaid: 600.0,
      );

      expect(payload['payment_mode'], equals('item_wise'));
      expect(payload.containsKey('total_payment'), isFalse, reason: 'total_payment must NOT be present in item_wise mode');
      expect(payload['receiver'], equals('Rahul Sharma'));

      final items = payload['items'] as List;
      final item = items.first as Map<String, dynamic>;
      expect(item['amount_paid'], equals(600.0));
    });

    test('Total mode includes total_payment and excludes item-level amount_paid', () {
      final payload = buildExistingCustomerPayload(
        phone: '+919876543210',
        receiver: null,
        payPerItem: false,
        overallPaid: 2000.0,
        itemName: 'Gold Chain',
        weight: 10.0,
        rate: 6000.0,
        totalAmount: 60000.0,
        itemPaid: 0.0,
      );

      expect(payload['payment_mode'], equals('total'));
      expect(payload['total_payment'], equals(2000.0));
      expect(payload.containsKey('receiver'), isFalse);

      final items = payload['items'] as List;
      final item = items.first as Map<String, dynamic>;
      expect(item.containsKey('amount_paid'), isFalse, reason: 'amount_paid must NOT be present in total mode');
    });
  });
}
