import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_config.dart';
import '../../../../services/api_client.dart';
import 'edit_shop_details_screen.dart';
import 'manage_workers_screen.dart';
import 'roles_permissions_screen.dart';
import 'business_settings_screen.dart';
import 'backup_sync_screen.dart';
import 'subscription_screen.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  static const _storage = FlutterSecureStorage();

  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);
  static const Color _green = Color(0xFF16B85A);

  String _shopName = 'Sharma Jewellers';
  String _shopType = 'Gold • Silver • Diamond';
  String _shopId = 'JS-784561';
  int _workerCount = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      final storedShopName = await _storage.read(key: 'shop_name');
      final storedShopType = await _storage.read(key: 'shop_type');
      final storedShopId = await _storage.read(key: 'shop_id');

      // Try fetching from GET /shop-profile
      try {
        final response = await ApiClient.instance.get(
          Uri.parse('${ApiConfig.baseUrl}/shop-profile'),
          headers: const {'Accept': 'application/json'},
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final name = decoded['shop_name']?.toString();
            if (name != null && name.trim().isNotEmpty) {
              _shopName = name.trim();
              await _storage.write(key: 'shop_name', value: _shopName);
            }
          }
        }
      } catch (_) {}

      // Count local workers
      final prefs = await SharedPreferences.getInstance();
      final workersJson = prefs.getString('shop_workers_list');
      if (workersJson != null && workersJson.isNotEmpty) {
        final List decodedList = jsonDecode(workersJson);
        _workerCount = decodedList.length;
      }

      if (!mounted) return;
      setState(() {
        if (storedShopName != null && storedShopName.trim().isNotEmpty) {
          _shopName = storedShopName.trim();
        }
        if (storedShopType != null && storedShopType.trim().isNotEmpty) {
          _shopType = storedShopType.trim();
        }
        if (storedShopId != null && storedShopId.trim().isNotEmpty) {
          _shopId = storedShopId.trim();
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyShopId() {
    Clipboard.setData(ClipboardData(text: _shopId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop ID copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openEditShopDetails() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const EditShopDetailsScreen(),
      ),
    );
    if (updated == true && mounted) {
      await _loadShopData();
    }
  }

  Future<void> _openManageWorkers() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ManageWorkersScreen(),
      ),
    );
    if (mounted) {
      await _loadShopData();
    }
  }

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
        title: const Column(
          children: [
            Text('Shop Settings', style: TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Manage your shop, team and preferences', style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Top Shop Card
                  InkWell(
                    onTap: _openEditShopDetails,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF46134C), Color(0xFF26002F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: _primary, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _shopName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2F8E8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.circle, color: _green, size: 7),
                                          SizedBox(width: 4),
                                          Text('Active', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(_shopType, style: const TextStyle(color: Color(0xFFD3C5DA), fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Settings Menu List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        _menuRow(
                          icon: Icons.store_outlined,
                          title: 'Shop Details',
                          subtitle: 'Name, address, GST, contact, etc.',
                          onTap: _openEditShopDetails,
                        ),
                        const Divider(height: 1, color: _border),
                        _menuRow(
                          icon: Icons.people_outline_rounded,
                          title: 'Manage Workers',
                          subtitle: 'Add, edit, remove & set permissions',
                          badgeCount: _workerCount,
                          onTap: _openManageWorkers,
                        ),
                        const Divider(height: 1, color: _border),
                        _menuRow(
                          icon: Icons.shield_outlined,
                          title: 'Roles & Permissions',
                          subtitle: 'Create roles and manage access',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RolesPermissionsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: _border),
                        _menuRow(
                          icon: Icons.settings_outlined,
                          title: 'Business Settings',
                          subtitle: 'Currency, weight unit, tax (GST), etc.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BusinessSettingsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: _border),
                        _menuRow(
                          icon: Icons.cloud_done_outlined,
                          title: 'Backup & Sync',
                          subtitle: 'Offline data & cloud sync',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BackupSyncScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: _border),
                        _menuRow(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Subscription',
                          subtitle: 'Plan, billing and renewal',
                          badgeText: 'Active',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SubscriptionScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Copy Shop ID Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2D4EE)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Shop ID: $_shopId',
                            style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: _copyShopId,
                          icon: const Icon(Icons.copy_rounded, color: _primary, size: 20),
                          tooltip: 'Copy Shop ID',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? badgeCount,
    String? badgeText,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _primary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            if (badgeCount != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E7C4),
                  shape: BoxShape.circle,
                ),
                child: Text('$badgeCount', style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: _green, size: 6),
                    const SizedBox(width: 4),
                    Text(badgeText, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, color: _primary, size: 24),
          ],
        ),
      ),
    );
  }
}
