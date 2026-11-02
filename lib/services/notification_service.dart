import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../firebase_options.dart';
import '../features/customers/presentation/screens/customer_details_screen.dart';
import '../features/customers/presentation/screens/customers_list_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/metal_rates/presentation/screens/metal_rates_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FCM Background] Message ID: ${message.messageId}');
    debugPrint('[FCM Background] Message Title: ${message.notification?.title}');

    // If message is data-only (no system notification created automatically by FCM), display local notification
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title']?.toString() ?? 'JewelSetu Notification';
      final body = message.data['body']?.toString() ?? '';

      final localNotifications = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        'jewelsetu_high_importance_channel',
        'JewelSetu High Priority Alerts',
        channelDescription:
            'High priority shop, ledger, and customer notifications with sound and vibration.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      await localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(android: androidDetails),
        payload: jsonEncode(message.data),
      );
    }
  } catch (e) {
    debugPrint('[FCM Background Error] Exception handling background message: $e');
  }
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _initialized = false;

  static const String _channelId = 'jewelsetu_high_importance_channel';
  static const String _channelName = 'JewelSetu High Priority Alerts';
  static const String _channelDesc =
      'High priority shop, ledger, and customer notifications with sound and vibration.';

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 500, 200, 500]);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _setupLocalNotifications();

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await requestPermission();
      await _initFcmToken();

      _setupForegroundHandler();
      _setupNotificationTapHandlers();
      debugPrint('[FCM Service] Initialization completed successfully.');
    } catch (e) {
      debugPrint('[FCM Service Error] Error during initialization: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[FCM Permission] Authorization Status: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('[FCM Permission Error] Error requesting notification permissions: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          '[FCM Local Tap] Notification tapped with payload: ${response.payload}',
        );
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(jsonDecode(response.payload!));
            handleNotificationNavigation(data);
          } catch (e) {
            debugPrint('[FCM Local Tap Error] Error parsing payload: $e');
          }
        }
      },
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
      );
      await androidImplementation.createNotificationChannel(channel);
      debugPrint('[FCM Local] Notification channel created: $_channelId');
    }
  }

  Future<void> _initFcmToken() async {
    try {
      // ignore: deprecated_member_use
      final token = await _fcm.getToken();
      final hasToken = token != null && token.isNotEmpty;
      debugPrint('[FCM Token] Token generated successfully: $hasToken');

      if (hasToken) {
        await _storage.write(key: 'fcm_token', value: token);
      }

      // ignore: deprecated_member_use
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM Token] Token refreshed.');
        await _storage.write(key: 'fcm_token', value: newToken);
      });
    } catch (e) {
      debugPrint('[FCM Token Error] Error retrieving FCM Token: $e');
    }
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString() ?? 'JewelSetu Notification';
      final body = notification?.body ?? message.data['body']?.toString() ?? '';

      debugPrint('[FCM Foreground] Message received. ID: ${message.messageId}, Title: $title');

      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _vibrationPattern,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  void _setupNotificationTapHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[FCM Background Tap] Notification tapped: ID=${message.messageId}',
      );
      handleNotificationNavigation(message.data);
    });

    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          '[FCM Terminated Tap] App launched via Notification: ID=${message.messageId}',
        );
        handleNotificationNavigation(message.data);
      }
    });
  }

  void handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('[FCM Navigation] Payload data: $data');

    final screen = data['screen']?.toString().toLowerCase();
    final type = data['notification_type']?.toString().toLowerCase();

    if (screen == 'metal_rates' || type == 'metal_rate_update') {
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => const MetalRatesScreen(),
        ),
      );
    } else if (screen == 'customers_list' || type == 'customer_ledger') {
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => const CustomersListScreen(),
        ),
      );
    } else if (screen == 'customer_details' || type == 'payment_received') {
      final name = data['customer_name']?.toString() ?? 'Customer';
      final phone = data['phone']?.toString() ?? '';
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => CustomerDetailsScreen(
            customer: CustomerDetailsData(
              name: name,
              phone: phone,
              initials: name.isNotEmpty ? name[0].toUpperCase() : 'C',
              total: 0,
              baki: 0,
              items: 0,
            ),
          ),
        ),
      );
    } else {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
        (route) => false,
      );
    }
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: 'fcm_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'fcm_token');
  }
}
