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
  Completer<void>? _storageChain;
  Future<void>? _activeCleanupFuture;
  int _sessionEpoch = 0;
  DateTime? _lastFailedRefreshTime;

  int get sessionEpoch => _sessionEpoch;

  void invalidateSessionEpoch() {
    _sessionEpoch++;
    debugPrint('[ApiClient] Session epoch invalidated -> $_sessionEpoch');
  }

  Future<T> _synchronizedStorage<T>(Future<T> Function() action) async {
    final previous = _storageChain;
    final current = Completer<void>();
    _storageChain = current;

    if (previous != null) {
      try {
        await previous.future;
      } catch (_) {}
    }

    try {
      return await action();
    } finally {
      current.complete();
    }
  }

  Future<bool> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    Map<String, String>? userProfile,
  }) async {
    invalidateSessionEpoch();
    final startEpoch = _sessionEpoch;

    return await _synchronizedStorage(() async {
      if (_sessionEpoch != startEpoch) {
        debugPrint('[ApiClient] Session epoch changed before saving auth session. Aborting.');
        return false;
      }

      await _storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }
      if (tokenType != null && tokenType.isNotEmpty) {
        await _storage.write(key: 'token_type', value: tokenType);
      }

      if (userProfile != null) {
        for (final entry in userProfile.entries) {
          if (entry.value.trim().isNotEmpty) {
            await _storage.write(key: entry.key, value: entry.value.trim());
          }
        }
      }

      if (_sessionEpoch != startEpoch) {
        debugPrint('[ApiClient] Session epoch changed during saving auth session. Cleaning up keys.');
        await _clearAllStorageKeys();
        return false;
      }

      return true;
    });
  }

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
    String? requestToken;

    if (!reqHeaders.containsKey('Authorization')) {
      final token = await _storage.read(key: 'access_token');
      if (token != null && token.trim().isNotEmpty) {
        requestToken = token.trim();
        reqHeaders['Authorization'] = 'Bearer $requestToken';
      }
    } else {
      final rawAuth = reqHeaders['Authorization'] ?? '';
      if (rawAuth.startsWith('Bearer ')) {
        requestToken = rawAuth.substring(7).trim();
      }
    }

    http.Response response;
    try {
      response = await _executeHttp(method, url, reqHeaders, body, encoding).timeout(timeout);
    } catch (e) {
      rethrow;
    }

    if (response.statusCode == 401 && !isRetry && !url.path.contains('/auth/')) {
      final currentToken = await _storage.read(key: 'access_token');
      if (currentToken != null &&
          currentToken.trim().isNotEmpty &&
          requestToken != null &&
          currentToken.trim() != requestToken) {
        debugPrint('[ApiClient] Access token was already refreshed by another request. Retrying request with latest token.');
        reqHeaders['Authorization'] = 'Bearer ${currentToken.trim()}';
        return _sendRequest(
          method: method,
          url: url,
          headers: reqHeaders,
          body: body,
          encoding: encoding,
          timeout: timeout,
          isRetry: true,
        );
      }

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
        final hasRefreshToken = await _storage.read(key: 'refresh_token');
        if (hasRefreshToken == null || hasRefreshToken.trim().isEmpty) {
          await _handleSessionExpired();
        }
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

    if (_lastFailedRefreshTime != null) {
      final diff = DateTime.now().difference(_lastFailedRefreshTime!);
      if (diff.inSeconds < 5) {
        debugPrint('[ApiClient] Cooldown active after failed refresh attempt. Skipping network call.');
        return false;
      }
    }

    final startEpoch = _sessionEpoch;
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
        if (_sessionEpoch != startEpoch) {
          debugPrint('[ApiClient] Manual logout occurred while refresh was on the wire. Discarding tokens.');
          _refreshCompleter!.complete(false);
          _refreshCompleter = null;
          return false;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final newAccessToken = decoded['access_token']?.toString();
          final newRefreshToken = decoded['refresh_token']?.toString();
          final tokenType = decoded['token_type']?.toString();

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            final saved = await _synchronizedStorage(() async {
              if (_sessionEpoch != startEpoch) {
                return false;
              }
              await _storage.write(key: 'access_token', value: newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await _storage.write(key: 'refresh_token', value: newRefreshToken);
              }
              if (tokenType != null && tokenType.isNotEmpty) {
                await _storage.write(key: 'token_type', value: tokenType);
              }
              if (_sessionEpoch != startEpoch) {
                await _clearAllStorageKeys();
                return false;
              }
              return true;
            });

            if (saved) {
              _lastFailedRefreshTime = null;
              debugPrint('[ApiClient] Token refresh succeeded. Tokens updated securely.');
              _refreshCompleter!.complete(true);
              _refreshCompleter = null;
              return true;
            }
          }
        }
      } else if (response.statusCode == 401) {
        if (_sessionEpoch != startEpoch) {
          debugPrint('[ApiClient] Stale 401 refresh response received after session epoch changed. Discarding stale 401.');
          _refreshCompleter!.complete(false);
          _refreshCompleter = null;
          return false;
        }
        debugPrint('[ApiClient] Refresh token explicitly rejected by backend (401). Clearing session.');
        await _handleSessionExpired();
      } else {
        if (_sessionEpoch != startEpoch) {
          _refreshCompleter!.complete(false);
          _refreshCompleter = null;
          return false;
        }
        debugPrint('[ApiClient] Refresh token request returned HTTP ${response.statusCode}. Preserving session credentials.');
        _lastFailedRefreshTime = DateTime.now();
      }

      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    } on TimeoutException {
      debugPrint('[ApiClient] Refresh request timed out. Preserving session.');
      _lastFailedRefreshTime = DateTime.now();
      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    } catch (e) {
      debugPrint('[ApiClient Error] Token refresh exception: $e. Preserving session.');
      _lastFailedRefreshTime = DateTime.now();
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      _refreshCompleter = null;
      return false;
    }
  }

  Future<void> handleManualLogout() async {
    await _handleSessionExpired();
  }

  Future<void> _clearAllStorageKeys() async {
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
  }

  Future<void> _handleSessionExpired() {
    if (_activeCleanupFuture != null) {
      debugPrint('[ApiClient] Session expiration cleanup already in progress. Joining in-flight operation...');
      return _activeCleanupFuture!;
    }

    _activeCleanupFuture = _executeSessionExpired().whenComplete(() {
      _activeCleanupFuture = null;
    });

    return _activeCleanupFuture!;
  }

  Future<void> _executeSessionExpired() async {
    invalidateSessionEpoch();
    final cleanupEpoch = _sessionEpoch;
    debugPrint('[ApiClient] Executing session expired cleanup...');

    await _synchronizedStorage(() async {
      await _clearAllStorageKeys();
    });

    if (_sessionEpoch != cleanupEpoch) {
      debugPrint('[ApiClient] A new login or session started during cleanup. Aborting logout navigation.');
      return;
    }

    final navigator = NotificationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }
}
