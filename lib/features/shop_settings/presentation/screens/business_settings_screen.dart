import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/shop_context_service.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);

  String _currency = 'INR (₹)';
  String _weightUnit = 'Grams (g)';
  String _gstRate = '3% (Standard Jewellery)';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ShopContextService.instance.addListener(_onShopContextChanged);
    _loadShopBusinessSettings();
  }

  @override
  void dispose() {
    ShopContextService.instance.removeListener(_onShopContextChanged);
    super.dispose();
  }

  void _onShopContextChanged() {
    if (mounted) {
      _loadShopBusinessSettings();
    }
  }

  String get _shopSettingsKey {
    final shopId = ShopContextService.instance.selectedShopId;
    return 'shop_${shopId}_business_settings';
  }

  Future<void> _loadShopBusinessSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_shopSettingsKey);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _currency = decoded['currency'] ?? 'INR (₹)';
          _weightUnit = decoded['weightUnit'] ?? 'Grams (g)';
          _gstRate = decoded['gstRate'] ?? '3% (Standard Jewellery)';
        }
      } catch (_) {}
    } else {
      // Default settings for Gaya vs Patna branch
      final shopId = ShopContextService.instance.selectedShopId;
      if (shopId.contains('gaya')) {
        _currency = 'INR (₹)';
        _weightUnit = 'Grams (g)';
        _gstRate = '1.5%';
      } else {
        _currency = 'INR (₹)';
        _weightUnit = 'Grams (g)';
        _gstRate = '3% (Standard Jewellery)';
      }
      await _saveShopBusinessSettings();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _saveShopBusinessSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'currency': _currency,
      'weightUnit': _weightUnit,
      'gstRate': _gstRate,
    };
    await prefs.setString(_shopSettingsKey, jsonEncode(data));
  }

  @override
  Widget build(BuildContext context) {
    final currentShop = ShopContextService.instance.currentShop;
    final activeBranchName = currentShop?.displayName ?? 'Active Shop';

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
        title: Column(
          children: [
            const Text('Business Settings', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(activeBranchName, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2D4EE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: _primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Configuring Settings for: $activeBranchName',
                            style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        _settingDropdownRow(
                          'Currency',
                          _currency,
                          ['INR (₹)', 'USD (\$)'],
                          (v) async {
                            if (v != null) {
                              setState(() => _currency = v);
                              await _saveShopBusinessSettings();
                            }
                          },
                        ),
                        const Divider(color: _border, height: 24),
                        _settingDropdownRow(
                          'Weight Unit',
                          _weightUnit,
                          ['Grams (g)', 'Tola', 'Carat (ct)'],
                          (v) async {
                            if (v != null) {
                              setState(() => _weightUnit = v);
                              await _saveShopBusinessSettings();
                            }
                          },
                        ),
                        const Divider(color: _border, height: 24),
                        _settingDropdownRow(
                          'Default GST Rate',
                          _gstRate,
                          ['3% (Standard Jewellery)', '1.5%', '0% (Exempt)'],
                          (v) async {
                            if (v != null) {
                              setState(() => _gstRate = v);
                              await _saveShopBusinessSettings();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _settingDropdownRow(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            fillColor: _background,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          ),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
