import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/services/sync_manager.dart';

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

  group('SyncManager Outbox & Isolation Verification', () {
    test('OutboxItem serializes and deserializes correctly', () {
      final item = OutboxItem(
        id: 'sync_100',
        type: 'add_customer',
        shopId: 'shop_patna',
        ownerUserId: 'user_owner_1',
        idempotencyKey: 'idem_key_100',
        payload: {'name': 'Kunal Verma', 'phone_number': '+917011938465'},
        createdAt: '2026-10-31T10:00:00Z',
      );

      final json = item.toJson();
      final reconstructed = OutboxItem.fromJson(json);

      expect(reconstructed.id, equals('sync_100'));
      expect(reconstructed.type, equals('add_customer'));
      expect(reconstructed.shopId, equals('shop_patna'));
      expect(reconstructed.ownerUserId, equals('user_owner_1'));
      expect(reconstructed.idempotencyKey, equals('idem_key_100'));
      expect(reconstructed.payload['name'], equals('Kunal Verma'));
    });

    test('OutboxItem preserves idempotencyKey across retries', () {
      final item = OutboxItem(
        id: 'sync_200',
        type: 'add_payment',
        shopId: 'shop_patna',
        ownerUserId: 'user_owner_1',
        idempotencyKey: 'idem_stable_key_200',
        payload: {'amount': 1500},
        createdAt: '2026-10-31T10:00:00Z',
        retryCount: 2,
      );

      item.retryCount++;
      expect(item.idempotencyKey, equals('idem_stable_key_200'));
      expect(item.retryCount, equals(3));
    });
  });
}
