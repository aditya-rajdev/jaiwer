import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _statusController.stream;

  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(results);
      _statusController.add(_isOnline);

      _connectivity.onConnectivityChanged
          .listen((List<ConnectivityResult> results) async {
        final hasNet = _hasConnection(results);
        if (hasNet) {
          final reachable = await checkBackendServerReachable();
          _isOnline = reachable;
        } else {
          _isOnline = false;
        }
        _statusController.add(_isOnline);
      });
    } catch (e) {
      debugPrint('[ConnectivityService] Initialization error: $e');
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }

  Future<bool> checkBackendServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
