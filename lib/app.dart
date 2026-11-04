import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/onboarding/presentation/screens/role_selection_screen.dart';
import 'services/notification_service.dart';

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

class _AuthGateState extends State<AuthGate> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _checkSession();
  }

  Future<bool> _checkSession() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null || accessToken.trim().isEmpty) return false;

      // Decode JWT payload locally to check expiration without network dependency
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
              debugPrint('[AuthGate] JWT access token expired locally.');
              return false;
            }
          }
        }
      } catch (e) {
        debugPrint('[AuthGate] JWT local decode error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Session check failed: $e');
      return false;
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
