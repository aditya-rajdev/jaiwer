import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/onboarding/presentation/screens/role_selection_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/sync_manager.dart';

class JewelSetuApp extends StatelessWidget {
  const JewelSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'JewelSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late Future<bool> _sessionFuture;
  Future<bool>? _inFlightCheckSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SyncManager.instance.initialize();
    _sessionFuture = _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _inFlightCheckSession == null) {
      debugPrint('[AuthGate] App resumed from background. Verifying session...');
      if (mounted) {
        setState(() {
          _sessionFuture = _checkSession();
        });
      }
    }
  }

  Future<bool> _checkSession() {
    if (_inFlightCheckSession != null) {
      debugPrint('[AuthGate] Reusing in-flight session check Future.');
      return _inFlightCheckSession!;
    }
    _inFlightCheckSession = _executeCheckSession().whenComplete(() {
      _inFlightCheckSession = null;
    });
    return _inFlightCheckSession!;
  }

  Future<bool> _executeCheckSession() async {
    final startEpoch = ApiClient.instance.sessionEpoch;

    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (ApiClient.instance.sessionEpoch != startEpoch) return false;

      final refreshToken = await _storage.read(key: 'refresh_token');
      if (ApiClient.instance.sessionEpoch != startEpoch) return false;

      if (accessToken == null || accessToken.trim().isEmpty) {
        if (refreshToken == null || refreshToken.trim().isEmpty) {
          return false;
        }
        final refreshed = await ApiClient.instance.refreshAccessToken();
        if (ApiClient.instance.sessionEpoch != startEpoch) return false;
        if (refreshed) return true;
        final remainingRefreshToken = await _storage.read(key: 'refresh_token');
        if (ApiClient.instance.sessionEpoch != startEpoch) return false;
        return remainingRefreshToken != null && remainingRefreshToken.trim().isNotEmpty;
      }

      bool isAccessTokenExpired = false;
      try {
        final parts = accessToken.split('.');
        if (parts.length == 3) {
          final normalized = base64Url.normalize(parts[1]);
          final payloadString = utf8.decode(base64Url.decode(normalized));
          final payload = jsonDecode(payloadString);
          if (payload is Map && payload['exp'] != null) {
            final expSeconds = (payload['exp'] as num).toInt();
            final expDate = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
            if (DateTime.now().isAfter(expDate)) {
              isAccessTokenExpired = true;
            }
          }
        }
      } catch (e) {
        debugPrint('[AuthGate] JWT local decode error: $e');
      }

      if (ApiClient.instance.sessionEpoch != startEpoch) return false;

      if (isAccessTokenExpired) {
        debugPrint('[AuthGate] Access token expired locally. Attempting background token refresh...');
        if (refreshToken != null && refreshToken.trim().isNotEmpty) {
          final refreshed = await ApiClient.instance.refreshAccessToken();
          if (ApiClient.instance.sessionEpoch != startEpoch) return false;
          if (refreshed) {
            return true;
          }
          final remainingRefreshToken = await _storage.read(key: 'refresh_token');
          if (ApiClient.instance.sessionEpoch != startEpoch) return false;
          if (remainingRefreshToken != null && remainingRefreshToken.trim().isNotEmpty) {
            debugPrint('[AuthGate] Refresh failed due to network/offline. Retaining session.');
            return true;
          }
        }
        return false;
      }

      if (ApiClient.instance.sessionEpoch != startEpoch) return false;
      return true;
    } catch (e) {
      debugPrint('Session check failed: $e');
      if (ApiClient.instance.sessionEpoch != startEpoch) return false;
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (ApiClient.instance.sessionEpoch != startEpoch) return false;
      return refreshToken != null && refreshToken.trim().isNotEmpty;
    }
  }

  void _retry() {
    setState(() {
      _sessionFuture = _checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFFCF7),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF35113F),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFFCF7),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to check your login session.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return DashboardScreen();
        }

        return const RoleSelectionScreen();
      },
    );
  }
}
