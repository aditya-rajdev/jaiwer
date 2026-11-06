import 'package:flutter/material.dart';
import 'notification_service.dart';

class ToastService {
  ToastService._internal();
  static final ToastService instance = ToastService._internal();

  void showSuccess(String message) {
    _showToast(
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF247A4B),
    );
  }

  void showError(String message) {
    _showToast(
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFFB42318),
    );
  }

  void showWarning(String message) {
    _showToast(
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: const Color(0xFFD49A3A),
    );
  }

  void showInfo(String message) {
    _showToast(
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: const Color(0xFF2B1038),
    );
  }

  void _showToast({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final context = NotificationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
