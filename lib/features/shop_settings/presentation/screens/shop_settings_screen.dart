import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_config.dart';
import '../../../../services/api_client.dart';
import '../../../../services/shop_context_service.dart';
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

  String _shopName = 'Raj Jewellery';
  String _shopType = 'Gold • Silver • Diamond';
  String _shopId = 'JS-784561';
  int _workerCount = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ShopContextService.instance.addListener(_onShopContextChanged);
    _loadShopData();
  }

  @override
  void dispose() {
    ShopContextService.instance.removeListener(_onShopContextChanged);
    super.dispose();
  }

  void _onShopContextChanged() {
    if (mounted) {
      setState(() {
        final current = ShopContextService.instance.currentShop;
        if (current != null) {
          _shopName = current.displayName;
        }
      });
    }
  }

  Future<void> _loadShopData() async {
    try {
      await ShopContextService.instance.initialize();
      final current = ShopContextService.instance.currentShop;

      final storedShopName = await _storage.read(key: 'shop_name');
      final storedShopType = await _storage.read(key: 'shop_type');
      final storedShopId = await _storage.read(key: 'selected_shop_id');

      try {
        final response = await ApiClient.instance.get(
          Uri.parse('${ApiConfig.baseUrl}/shop-profile'),
          headers: const {'Accept': 'application/json'},
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final name = decoded['shop_name']?.toString();
            if (name != null && name.trim().isNotEmpty && current == null) {
              _shopName = name.trim();
              await _storage.write(key: 'shop_name', value: _shopName);
            }
          }
        }
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      final workersJson = prefs.getString('shop_workers_list');
      if (workersJson != null && workersJson.isNotEmpty) {
        final List decodedList = jsonDecode(workersJson);
        _workerCount = decodedList.length;
      }

      if (!mounted) return;
      setState(() {
        if (current != null) {
          _shopName = current.displayName;
        } else if (storedShopName != null && storedShopName.trim().isNotEmpty) {
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

  Future<void> _showAddShopSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: 'Raj Jewellery');
    final branchCtrl = TextEditingController(text: 'Gaya Branch');
    final addressCtrl = TextEditingController(text: 'GB Road, Gaya, Bihar');
    final phoneCtrl = TextEditingController(text: '+91 91234 56789');
    final gstinCtrl = TextEditingController(text: '10AAAAA0000A1Z6');
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add New Shop / Branch', style: TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w800)),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close_rounded, color: _primary),
                        ),
                      ],
                    ),
                    const Divider(color: _border),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Shop Name *',
                        prefixIcon: const Icon(Icons.storefront_rounded, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: branchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Branch Name *',
                        hintText: 'e.g. Gaya Branch / Boring Road Branch',
                        prefixIcon: const Icon(Icons.business_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Branch Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Address *',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: gstinCtrl,
                      decoration: InputDecoration(
                        labelText: 'GSTIN (Optional)',
                        prefixIcon: const Icon(Icons.badge_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);

                                final newShop = ShopModel(
                                  id: 'shop_${DateTime.now().millisecondsSinceEpoch}',
                                  name: nameCtrl.text.trim(),
                                  branch: branchCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  gstin: gstinCtrl.text.trim(),
                                  isPrimary: false,
                                );

                                await ShopContextService.instance.addNewShop(newShop);

                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Switched to new shop: ${newShop.displayName}'),
                                      backgroundColor: const Color(0xFF247A4B),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add_business_rounded, color: Colors.white),
                        label: Text(
                          isSaving ? 'Adding Shop...' : 'Add & Switch to Shop',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    branchCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    gstinCtrl.dispose();
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
    final shops = ShopContextService.instance.shops;
    final currentShopId = ShopContextService.instance.selectedShopId;

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
                  // Top Shop Header Card
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

                  const SizedBox(height: 22),

                  // My Shops Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Shops / Branches', style: TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.w800)),
                      TextButton.icon(
                        onPressed: _showAddShopSheet,
                        icon: const Icon(Icons.add_circle_outline_rounded, color: _primary, size: 20),
                        label: const Text('+ Add Shop', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Multi-Shop Branch List Cards
                  for (final shop in shops) ...[
                    _buildShopBranchCard(
                      shop: shop,
                      isSelected: shop.id == currentShopId,
                      onTap: () async {
                        final rootCtx = context;
                        final shopName = shop.displayName;
                        await ShopContextService.instance.switchShop(shop.id);
                        if (!rootCtx.mounted) return;
                        ScaffoldMessenger.of(rootCtx).showSnackBar(
                          SnackBar(
                            content: Text('Switched to $shopName'),
                            backgroundColor: const Color(0xFF247A4B),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 18),

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
                            'Active Shop ID: $currentShopId',
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

  Widget _buildShopBranchCard({
    required ShopModel shop,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2EAFB) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? _primary : _border, width: isSelected ? 1.8 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? _primary : const Color(0xFFFFF0D6),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, color: isSelected ? Colors.white : const Color(0xFFB8860B), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _primary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F8E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: _green, size: 13),
                              SizedBox(width: 4),
                              Text('Active', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(shop.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('GSTIN: ${shop.gstin}', style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? _primary : _muted,
              size: 22,
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
