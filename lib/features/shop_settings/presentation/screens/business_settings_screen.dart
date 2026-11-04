import 'package:flutter/material.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);

  String _currency = 'INR (₹)';
  String _weightUnit = 'Grams (g)';
  String _gstRate = '3% (Standard Jewellery)';

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
        title: const Text('Business Settings', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _settingDropdownRow('Currency', _currency, ['INR (₹)', 'USD (\$)'], (v) => setState(() => _currency = v!)),
                  const Divider(color: _border, height: 24),
                  _settingDropdownRow('Weight Unit', _weightUnit, ['Grams (g)', 'Tola', 'Carat (ct)'], (v) => setState(() => _weightUnit = v!)),
                  const Divider(color: _border, height: 24),
                  _settingDropdownRow('Default GST Rate', _gstRate, ['3% (Standard Jewellery)', '1.5%', '0% (Exempt)'], (v) => setState(() => _gstRate = v!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingDropdownRow(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
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
