import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FCM Init] Firebase initialized successfully.');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[FCM Init Error] Failed to initialize Firebase: $e');
  }

  try {
    await NotificationService.instance.initialize();
    debugPrint('[FCM Init] NotificationService initialized successfully.');
  } catch (e) {
    debugPrint('[FCM Init Error] Failed to initialize NotificationService: $e');
  }

  runApp(const JewelSetuApp());
}
