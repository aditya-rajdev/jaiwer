import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../config/app_config.dart';
import '../../../../services/api_client.dart';
import 'manage_workers_screen.dart';
import 'roles_permissions_screen.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);
  static const Color _text = Color(0xFF29232D);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Suresh Kumar');
  final _phoneCtrl = TextEditingController(text: '+91 91234 56789');

  String _selectedRole = 'Sales & Billing';
  bool _isSaving = false;

  List<String> _assignedPermissions = [
    'Dashboard',
    'Customers',
    'Payments',
    'Gold Rate',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _normalizePhoneNumber(String input) {
    var digits = input.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return input.trim();
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) {
      return '+91$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    } else if (digits.length >= 8 && digits.length <= 15) {
      return '+$digits';
    }
    return '+$digits';
  }

  bool _isValidE164(String phone) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone);

  Future<void> _openSetPermissions() async {
    final updatedPerms = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute<List<String>>(
        builder: (_) => RolesPermissionsScreen(
          selectedRole: _selectedRole,
          initialPermissions: _assignedPermissions,
          isWorkerSpecific: true,
        ),
      ),
    );

    if (updatedPerms != null) {
      setState(() {
        _assignedPermissions = updatedPerms;
      });
    }
  }

  Future<void> _submitAddWorker() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final formattedPhone = _normalizePhoneNumber(_phoneCtrl.text);
    final name = _nameCtrl.text.trim();

    setState(() => _isSaving = true);

    try {
      final payload = {'phone_number': formattedPhone};
      final uri = Uri.parse(ApiConfig.ownerWorkersUrl);

      final response = await ApiClient.instance.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } on FormatException {
        responseData = null;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final id = responseData is Map ? (responseData['id'] ?? '').toString() : 'w_${DateTime.now().millisecondsSinceEpoch}';
        final status = responseData is Map ? (responseData['status'] ?? 'approved').toString() : 'Active';

        final newWorker = WorkerModel(
          id: id.isNotEmpty ? id : 'w_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          phone: formattedPhone,
          role: _selectedRole,
          status: status.toLowerCase() == 'approved' ? 'Active' : status,
          joinDate: 'Today',
          permissions: _assignedPermissions,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker linked successfully via POST /owner/workers!'),
            backgroundColor: Color(0xFF247A4B),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, newWorker);
        return;
      }

      final serverMessage = responseData is Map
          ? (responseData['detail'] ?? responseData['message'] ?? responseData['error'])?.toString()
          : null;

      String errorMessage;
      if (response.statusCode == 404) {
        errorMessage = 'Worker account not found for $formattedPhone. Please ask the worker to register on JAIWER first as a "Worker" account.';
      } else if (response.statusCode == 401) {
        errorMessage = 'Session expired or non-owner account. Only shop owners can add workers.';
      } else if (response.statusCode == 422) {
        errorMessage = 'Invalid phone number format. Enter E.164 phone number e.g. +919876543210.';
      } else {
        errorMessage = serverMessage ?? 'Could not link worker (HTTP ${response.statusCode}).';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding worker: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: const Text('Add Worker', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              // Photo Avatar Header
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2D4EE),
                        shape: BoxShape.circle,
                        border: Border.all(color: _border, width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: _primary, size: 55),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _primary,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Worker photo picker ready')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info Guidance Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2D4EE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Important: The worker must already have a registered JAIWER account with this phone number (account_type = worker).',
                        style: TextStyle(fontSize: 11, color: _text, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Form Inputs
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person_outline, color: _primary),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (E.164) *',
                  hintText: '+919876543210',
                  prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone Number is required';
                  final norm = _normalizePhoneNumber(v);
                  if (!_isValidE164(norm)) return 'Enter valid phone number e.g. +919876543210';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role *',
                  prefixIcon: const Icon(Icons.workspace_premium_outlined, color: _primary),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Sales & Billing', child: Text('Sales & Billing')),
                  DropdownMenuItem(value: 'Inventory Manager', child: Text('Inventory Manager')),
                  DropdownMenuItem(value: 'View Only', child: Text('View Only')),
                  DropdownMenuItem(value: 'Shop Manager', child: Text('Shop Manager')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedRole = v;
                      _assignedPermissions = switch (v) {
                        'Inventory Manager' => ['Dashboard', 'Inventory', 'Suppliers', 'Gold Rate'],
                        'View Only' => ['Dashboard', 'Gold Rate'],
                        'Shop Manager' => ['Dashboard', 'Customers', 'Payments', 'Inventory', 'Suppliers', 'Gold Rate', 'Reports & Export'],
                        _ => ['Dashboard', 'Customers', 'Payments', 'Gold Rate'],
                      };
                    });
                  }
                },
              ),

              const SizedBox(height: 22),

              // Permissions Customization Section
              const Text('Permissions', style: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('You can customize permissions for this worker.', style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),

              InkWell(
                onTap: _openSetPermissions,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4ECFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.settings_outlined, color: _primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Set Permissions', style: TextStyle(color: _primary, fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('Configure module access', style: TextStyle(color: _muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _primary, size: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitAddWorker,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                  label: Text(
                    _isSaving ? 'Linking Worker...' : 'Add Worker (POST /owner/workers)',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
