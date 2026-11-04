import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _green = Color(0xFF16B85A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
        ),
        title: const Text('Subscription', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Current Plan: ', style: TextStyle(color: _primary, fontSize: 16)),
                    const Text('JAIWER Premium', style: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE2F8E8), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Active', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24, color: _border),
                const Text('Features included:', style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _featureItem('Unlimited Customers & Suppliers'),
                _featureItem('Multi-Worker Role & Access Management'),
                _featureItem('Offline-First Sync & Auto Cloud Backup'),
                _featureItem('FCM Realtime Push Notifications'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF29232D), fontSize: 13))),
        ],
      ),
    );
  }
}
