import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'connectivity_service.dart';

class PendingOperation {
  PendingOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.status = 'pending',
    this.attempts = 0,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'].toString(),
      type: json['type'].toString(),
      endpoint: json['endpoint'].toString(),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['created_at'].toString()),
      status: json['status']?.toString() ?? 'pending',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String type;
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  String status;
  int attempts;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'endpoint': endpoint,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'attempts': attempts,
      };
}

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  static const String _queueKey = 'offline_sync_queue';
  SharedPreferences? _prefs;
  bool _isSyncing = false;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();

    ConnectivityService.instance.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingOperations();
      }
    });
  }

  Future<void> enqueueOperation({
    required String type,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    await initialize();
    final queue = await getPendingOperations();

    final op = PendingOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      endpoint: endpoint,
      payload: payload,
      createdAt: DateTime.now(),
    );

    queue.add(op);
    await _saveQueue(queue);
    debugPrint('[SyncService] Operation enqueued: ${op.type} (ID: ${op.id})');

    if (ConnectivityService.instance.isOnline) {
      syncPendingOperations();
    }
  }

  Future<List<PendingOperation>> getPendingOperations() async {
    await initialize();
    final raw = _prefs?.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => PendingOperation.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[SyncService Error] Error reading queue: $e');
    }
    return [];
  }

  Future<void> _saveQueue(List<PendingOperation> queue) async {
    await initialize();
    final encoded = jsonEncode(queue.map((op) => op.toJson()).toList());
    await _prefs?.setString(_queueKey, encoded);
  }

  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await getPendingOperations();
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('[SyncService] Syncing ${queue.length} pending operations...');
      final remaining = <PendingOperation>[];

      for (final op in queue) {
        if (!ConnectivityService.instance.isOnline) {
          remaining.add(op);
          continue;
        }

        try {
          op.attempts += 1;
          final uri = Uri.parse(op.endpoint);

          final response = await ApiClient.instance.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Operation-ID': op.id, // Idempotency header
            },
            body: jsonEncode(op.payload),
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            debugPrint('[SyncService] Operation ${op.id} synchronized successfully.');
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            debugPrint('[SyncService] Session unauthorized during sync. Retaining queue.');
            remaining.add(op);
            break;
          } else if (response.statusCode >= 400 && response.statusCode < 500) {
            debugPrint('[SyncService] Client error HTTP ${response.statusCode} for op ${op.id}. Removing failed op.');
          } else {
            remaining.add(op);
          }
        } catch (e) {
          debugPrint('[SyncService Error] Failed to sync op ${op.id}: $e');
          remaining.add(op);
        }
      }

      await _saveQueue(remaining);
    } finally {
      _isSyncing = false;
    }
  }
}
