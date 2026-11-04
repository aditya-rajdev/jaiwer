import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._internal();
  static final CacheService instance = CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[CacheService] Initialization error: $e');
    }
  }

  Future<void> saveCache(String key, dynamic data) async {
    try {
      await initialize();
      if (_prefs == null) return;

      final payload = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });

      await _prefs!.setString(key, payload);
    } catch (e) {
      debugPrint('[CacheService Error] Failed to save cache for $key: $e');
    }
  }

  Future<dynamic> getCacheData(String key) async {
    try {
      await initialize();
      if (_prefs == null) return null;

      final raw = _prefs!.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded['data'];
      }
    } catch (e) {
      debugPrint('[CacheService Error] Failed to read cache for $key: $e');
    }
    return null;
  }

  Future<DateTime?> getCacheTimestamp(String key) async {
    try {
      await initialize();
      if (_prefs == null) return null;

      final raw = _prefs!.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['timestamp'] != null) {
        return DateTime.tryParse(decoded['timestamp'].toString());
      }
    } catch (e) {
      debugPrint('[CacheService Error] Failed to read timestamp for $key: $e');
    }
    return null;
  }

  Future<void> clearCache(String key) async {
    try {
      await initialize();
      await _prefs?.remove(key);
    } catch (_) {}
  }
}
