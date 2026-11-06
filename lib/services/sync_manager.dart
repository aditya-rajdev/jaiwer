import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'shop_context_service.dart';
import 'toast_service.dart';

class OutboxItem {
  OutboxItem({
    required this.id,
    required this.type,
    required this.shopId,
    required this.ownerUserId,
    required this.idempotencyKey,
    required this.payload,
    required this.createdAt,
    this.status = 'pending',
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String type; // add_customer, add_customer_item, add_supplier, add_payment
  final String shopId;
  final String ownerUserId;
  final String idempotencyKey;
  final Map<String, dynamic> payload;
  final String createdAt;
  String status; // pending, syncing, synced, failed_permanent
  int retryCount;
  String? lastError;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'shopId': shopId,
        'ownerUserId': ownerUserId,
        'idempotencyKey': idempotencyKey,
        'payload': payload,
        'createdAt': createdAt,
        'status': status,
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory OutboxItem.fromJson(Map<String, dynamic> json) => OutboxItem(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        shopId: (json['shopId'] ?? '').toString(),
        ownerUserId: (json['ownerUserId'] ?? '').toString(),
        idempotencyKey: (json['idempotencyKey'] ?? json['id'] ?? '').toString(),
        payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : {},
        createdAt: (json['createdAt'] ?? '').toString(),
        status: (json['status'] ?? 'pending').toString(),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        lastError: json['lastError']?.toString(),
      );
}

class SyncManager extends ChangeNotifier {
  SyncManager._internal();
  static final SyncManager instance = SyncManager._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  List<OutboxItem> _outbox = [];
  final Map<String, String> _localToServerIdMap = {};
  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySub;

  List<OutboxItem> get pendingItems {
    final activeShopId = ShopContextService.instance.selectedShopId;
    return _outbox.where((item) => item.shopId == activeShopId && item.status == 'pending').toList();
  }

  int get pendingCount => pendingItems.length;

  Future<void> initialize() async {
    await _loadOutbox();
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        processOutbox();
      }
    });
    if (ConnectivityService.instance.isOnline) {
      processOutbox();
    }
  }

  Future<void> _loadOutbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('offline_sync_outbox');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        _outbox = decoded.map((e) => OutboxItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      final mapStr = prefs.getString('local_to_server_id_map');
      if (mapStr != null && mapStr.isNotEmpty) {
        final Map decodedMap = jsonDecode(mapStr);
        _localToServerIdMap.clear();
        decodedMap.forEach((k, v) => _localToServerIdMap[k.toString()] = v.toString());
      }
    } catch (e) {
      debugPrint('[SyncManager] Error loading outbox: $e');
    }
    notifyListeners();
  }

  Future<void> _saveOutbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_outbox.map((e) => e.toJson()).toList());
      await prefs.setString('offline_sync_outbox', jsonStr);

      final mapStr = jsonEncode(_localToServerIdMap);
      await prefs.setString('local_to_server_id_map', mapStr);
    } catch (e) {
      debugPrint('[SyncManager] Error saving outbox: $e');
    }
    notifyListeners();
  }

  Future<void> queueOperation({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final activeShopId = ShopContextService.instance.selectedShopId;
    final currentOwnerId = await _storage.read(key: 'user_id') ?? 'owner_default';
    final now = DateTime.now();

    final item = OutboxItem(
      id: 'local_${now.millisecondsSinceEpoch}',
      type: type,
      shopId: activeShopId,
      ownerUserId: currentOwnerId,
      idempotencyKey: 'idem_${now.millisecondsSinceEpoch}_${payload.hashCode}',
      payload: payload,
      createdAt: now.toIso8601String(),
    );

    _outbox.add(item);
    await _saveOutbox();

    ToastService.instance.showInfo('Saved on this phone. Sync pending.');

    if (ConnectivityService.instance.isOnline) {
      processOutbox();
    }
  }

  Future<void> processOutbox() async {
    if (_isSyncing) return;
    if (!ConnectivityService.instance.isOnline) return;

    final currentOwnerId = await _storage.read(key: 'user_id') ?? 'owner_default';

    // Filter pending items belonging to current owner account
    final pending = _outbox.where((i) => i.status == 'pending' && i.ownerUserId == currentOwnerId).toList();
    if (pending.isEmpty) return;

    // Dependency-aware ordering: add_customer / add_supplier first before item/payment operations
    pending.sort((a, b) {
      const typePriority = {
        'add_customer': 1,
        'add_supplier': 2,
        'add_customer_item': 3,
        'add_payment': 4,
      };
      final pA = typePriority[a.type] ?? 99;
      final pB = typePriority[b.type] ?? 99;
      return pA.compareTo(pB);
    });

    _isSyncing = true;
    notifyListeners();

    int syncedCount = 0;

    for (final item in pending) {
      item.status = 'syncing';
      await _saveOutbox();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Shop-ID': item.shopId,
        'X-Idempotency-Key': item.idempotencyKey,
      };

      try {
        bool success = false;
        dynamic responseData;

        if (item.type == 'add_customer') {
          final res = await ApiClient.instance.post(
            Uri.parse('${ApiConfig.baseUrl}/add-customer'),
            headers: headers,
            body: jsonEncode(item.payload),
          );
          if (res.statusCode >= 200 && res.statusCode < 300) {
            success = true;
            try { responseData = jsonDecode(res.body); } catch (_) {}
            if (responseData is Map && responseData['customer'] is Map) {
              final serverCustId = responseData['customer']['id']?.toString();
              if (serverCustId != null) _localToServerIdMap[item.id] = serverCustId;
            }
          } else if (res.statusCode == 422 || res.statusCode == 400) {
            item.status = 'failed_permanent';
            item.lastError = 'Validation failed (HTTP ${res.statusCode})';
          }
        } else if (item.type == 'add_customer_item') {
          final res = await ApiClient.instance.post(
            Uri.parse(ApiConfig.existingCustomerUrl),
            headers: headers,
            body: jsonEncode(item.payload),
          );
          if (res.statusCode >= 200 && res.statusCode < 300) {
            success = true;
          } else if (res.statusCode == 422 || res.statusCode == 400) {
            item.status = 'failed_permanent';
            item.lastError = 'Validation failed (HTTP ${res.statusCode})';
          }
        } else if (item.type == 'add_supplier') {
          final res = await ApiClient.instance.post(
            Uri.parse('${ApiConfig.baseUrl}/api/suppliers'),
            headers: headers,
            body: jsonEncode(item.payload),
          );
          if (res.statusCode >= 200 && res.statusCode < 300) {
            success = true;
          } else if (res.statusCode == 422 || res.statusCode == 400) {
            item.status = 'failed_permanent';
            item.lastError = 'Validation failed (HTTP ${res.statusCode})';
          }
        } else if (item.type == 'add_payment') {
          final res = await ApiClient.instance.post(
            Uri.parse(ApiConfig.supplierPaymentUrl),
            headers: headers,
            body: jsonEncode(item.payload),
          );
          if (res.statusCode >= 200 && res.statusCode < 300) {
            success = true;
          } else if (res.statusCode == 422 || res.statusCode == 400) {
            item.status = 'failed_permanent';
            item.lastError = 'Validation failed (HTTP ${res.statusCode})';
          }
        }

        if (success) {
          item.status = 'synced';
          syncedCount++;
        } else if (item.status != 'failed_permanent') {
          item.status = 'pending';
          item.retryCount++;
        }
      } catch (e) {
        item.status = 'pending';
        item.retryCount++;
        item.lastError = e.toString();
      }

      await _saveOutbox();
    }

    _isSyncing = false;
    _outbox.removeWhere((i) => i.status == 'synced');
    await _saveOutbox();

    if (syncedCount > 0) {
      ToastService.instance.showSuccess('Your offline entries are now synced');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
