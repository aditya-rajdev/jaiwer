import 'package:flutter/material.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Suresh Kumar');
  final _phoneCtrl = TextEditingController(text: '+91 91234 56789');

  String _selectedRole = 'Sales & Billing';
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

  void _submitAddWorker() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    final newWorker = WorkerModel(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      role: _selectedRole,
      status: 'Active',
      joinDate: 'Today',
      permissions: _assignedPermissions,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Worker added successfully!'),
        backgroundColor: Color(0xFF247A4B),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, newWorker);
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
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2D4EE),
                        shape: BoxShape.circle,
                        border: Border.all(color: _border, width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: _primary, size: 60),
                    ),
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _primary,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
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

              const SizedBox(height: 24),

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
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone Number is required';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter a valid 10-digit phone number';
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
                child: ElevatedButton(
                  onPressed: _submitAddWorker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Add Worker', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
