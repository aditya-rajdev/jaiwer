import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../config/app_config.dart';
import '../../../../services/api_client.dart';
import '../../../../services/shop_context_service.dart';

class EditShopDetailsScreen extends StatefulWidget {
  const EditShopDetailsScreen({super.key});

  @override
  State<EditShopDetailsScreen> createState() => _EditShopDetailsScreenState();
}

class _EditShopDetailsScreenState extends State<EditShopDetailsScreen> {
  static const _storage = FlutterSecureStorage();

  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Raj Jewellery');
  final _branchCtrl = TextEditingController(text: 'Patna Main Branch');
  final _gstCtrl = TextEditingController(text: '10AAAAA0000A1Z5');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _addressCtrl = TextEditingController(text: 'Boring Road, Patna, Bihar – 800001');

  String _shopType = 'Gold, Silver & Diamond';
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    try {
      final currentShop = ShopContextService.instance.currentShop;
      if (currentShop != null) {
        _nameCtrl.text = currentShop.name;
        _branchCtrl.text = currentShop.branch;
        _addressCtrl.text = currentShop.address;
        _phoneCtrl.text = currentShop.phone;
        _gstCtrl.text = currentShop.gstin;
      } else {
        final name = await _storage.read(key: 'shop_name');
        final phone = await _storage.read(key: 'user_phone');
        final address = await _storage.read(key: 'shop_address');
        final gst = await _storage.read(key: 'shop_gstin');

        if (name != null && name.trim().isNotEmpty) _nameCtrl.text = name.trim();
        if (phone != null && phone.trim().isNotEmpty) _phoneCtrl.text = phone.trim();
        if (address != null && address.trim().isNotEmpty) _addressCtrl.text = address.trim();
        if (gst != null && gst.trim().isNotEmpty) _gstCtrl.text = gst.trim();
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveShopDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final name = _nameCtrl.text.trim();
    final branch = _branchCtrl.text.trim();
    final gst = _gstCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    try {
      final currentShop = ShopContextService.instance.currentShop;
      final shopId = currentShop?.id ?? 'shop_patna';

      final updatedShop = ShopModel(
        id: shopId,
        name: name,
        branch: branch,
        address: address,
        phone: phone,
        gstin: gst,
        isPrimary: currentShop?.isPrimary ?? true,
      );

      await ShopContextService.instance.switchShop(updatedShop.id);
      await _storage.write(key: 'shop_name', value: updatedShop.displayName);
      await _storage.write(key: 'shop_address', value: address);
      await _storage.write(key: 'shop_gstin', value: gst);

      try {
        final payload = {
          'shop_name': updatedShop.displayName,
          'shop_address': address,
          'gstin': gst.isNotEmpty ? gst : null,
        };
        await ApiClient.instance.post(
          Uri.parse('${ApiConfig.baseUrl}/shop-profile'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop branch details saved successfully!'),
          backgroundColor: Color(0xFF247A4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving shop details: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBranchName = ShopContextService.instance.currentShop?.displayName ?? 'Active Shop';

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
            const Text('Edit Shop Details', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(activeBranchName, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    // Shop Avatar Header
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0D6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD2A04A), width: 2),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: _primary, size: 48),
                              ),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: _primary,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Shop logo picker ready')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameCtrl.text.isEmpty ? 'Raj Jewellery' : '${_nameCtrl.text} (${_branchCtrl.text})',
                            style: const TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(_shopType, style: const TextStyle(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Input Form Fields
                    TextFormField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Shop Name *',
                        prefixIcon: const Icon(Icons.store_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _branchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Branch Name *',
                        prefixIcon: const Icon(Icons.business_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Branch name is required' : null,
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _shopType,
                      decoration: InputDecoration(
                        labelText: 'Shop Type',
                        prefixIcon: const Icon(Icons.category_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Gold, Silver & Diamond', child: Text('Gold, Silver & Diamond')),
                        DropdownMenuItem(value: 'Gold & Diamond', child: Text('Gold & Diamond')),
                        DropdownMenuItem(value: 'Silver Jewellery', child: Text('Silver Jewellery')),
                        DropdownMenuItem(value: 'Retail Jewellery', child: Text('Retail Jewellery')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _shopType = v);
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _gstCtrl,
                      decoration: InputDecoration(
                        labelText: 'GST Number (Optional)',
                        prefixIcon: const Icon(Icons.receipt_long_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.location_on_outlined, color: _primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveShopDetails,
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Branch Details',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
