import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../features/onboarding/presentation/screens/role_selection_screen.dart';
import 'notification_service.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final http.Client _client = http.Client();

  Completer<bool>? _refreshCompleter;

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    return _sendRequest(
      method: 'GET',
      url: url,
      headers: headers,
      timeout: timeout,
    );
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    return _sendRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
      encoding: encoding,
      timeout: timeout,
    );
  }

  Future<http.Response> _sendRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required Duration timeout,
    bool isRetry = false,
  }) async {
    final reqHeaders = Map<String, String>.from(headers ?? {});
    if (!reqHeaders.containsKey('Authorization')) {
      final token = await _storage.read(key: 'access_token');
      if (token != null && token.trim().isNotEmpty) {
        reqHeaders['Authorization'] = 'Bearer ${token.trim()}';
      }
    }

    http.Response response;
    try {
      response = await _executeHttp(method, url, reqHeaders, body, encoding).timeout(timeout);
    } catch (e) {
      rethrow;
    }

    if (response.statusCode == 401 && !isRetry && !url.path.contains('/auth/')) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newToken = await _storage.read(key: 'access_token');
        if (newToken != null && newToken.trim().isNotEmpty) {
          reqHeaders['Authorization'] = 'Bearer ${newToken.trim()}';
        }
        return _sendRequest(
          method: method,
          url: url,
          headers: reqHeaders,
          body: body,
          encoding: encoding,
          timeout: timeout,
          isRetry: true,
        );
      } else {
        await _handleSessionExpired();
      }
    }

    return response;
  }

  Future<http.Response> _executeHttp(
    String method,
    Uri url,
    Map<String, String> headers,
    Object? body,
    Encoding? encoding,
  ) {
    if (method.toUpperCase() == 'POST') {
      return _client.post(url, headers: headers, body: body, encoding: encoding);
    }
    return _client.get(url, headers: headers);
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshCompleter != null) {
      debugPrint('[ApiClient] Waiting for active token refresh operation...');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        debugPrint('[ApiClient] Refresh token missing from storage.');
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }

      final refreshUri = Uri.parse(ApiConfig.refreshAuthUrl);
      debugPrint('[ApiClient] Requesting token refresh via POST $refreshUri');

      final response = await _client
          .post(
            refreshUri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[ApiClient] Token refresh HTTP status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final newAccessToken = decoded['access_token']?.toString();
          final newRefreshToken = decoded['refresh_token']?.toString();

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await _storage.write(key: 'access_token', value: newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _storage.write(key: 'refresh_token', value: newRefreshToken);
            }
            debugPrint('[ApiClient] Token refresh succeeded. Tokens updated securely.');
            _refreshCompleter!.complete(true);
            _refreshCompleter = null;
            return true;
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[ApiClient] Refresh token expired or rejected by server.');
      }

      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    } on TimeoutException {
      debugPrint('[ApiClient] Refresh request timed out.');
      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      rethrow;
    } catch (e) {
      debugPrint('[ApiClient Error] Token refresh exception: $e');
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      _refreshCompleter = null;
      return false;
    }
  }

  Future<void> _handleSessionExpired() async {
    debugPrint('[ApiClient] Session expired. Clearing keys and redirecting to login...');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_type');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_phone');
    await _storage.delete(key: 'account_type');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'owner_reference_id');
    await _storage.delete(key: 'shop_name');

    final navigator = NotificationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }
}
