import 'package:flutter/material.dart';

import '../../../../services/connectivity_service.dart';

class BackupSyncScreen extends StatelessWidget {
  const BackupSyncScreen({super.key});

  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _green = Color(0xFF16B85A);

  @override
  Widget build(BuildContext context) {
    final isOnline = ConnectivityService.instance.isOnline;

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
        title: const Text('Backup & Sync', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: isOnline ? _green : Colors.amber.shade800,
                      size: 54,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOnline ? 'Cloud Sync Active' : 'Offline Mode Active',
                      style: const TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOnline
                          ? 'Your shop data is securely backed up to JAIWER Cloud.'
                          : 'Local changes will automatically sync when connectivity is restored.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
