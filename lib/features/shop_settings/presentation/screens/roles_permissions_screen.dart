import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RolesPermissionsScreen extends StatefulWidget {
  const RolesPermissionsScreen({
    super.key,
    this.selectedRole = 'Sales & Billing',
    this.initialPermissions,
    this.isWorkerSpecific = false,
  });

  final String selectedRole;
  final List<String>? initialPermissions;
  final bool isWorkerSpecific;

  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);

  late String _currentRole;
  final Map<String, bool> _permissionsMap = {};

  final List<Map<String, dynamic>> _modules = [
    {'name': 'Dashboard', 'icon': Icons.grid_view_rounded},
    {'name': 'Customers', 'icon': Icons.people_outline_rounded},
    {'name': 'Payments', 'icon': Icons.payment_outlined},
    {'name': 'Inventory', 'icon': Icons.all_inbox_outlined},
    {'name': 'Suppliers', 'icon': Icons.local_shipping_outlined},
    {'name': 'Gold Rate', 'icon': Icons.diamond_outlined},
    {'name': 'Reports & Export', 'icon': Icons.description_outlined},
    {'name': 'Shop Settings', 'icon': Icons.settings_outlined},
    {'name': 'Manage Workers', 'icon': Icons.group_outlined},
    {'name': 'Financial Correction\n(Edit / Delete / Restore)', 'icon': Icons.shield_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _currentRole = widget.selectedRole;
    _initializePermissions();
  }

  void _initializePermissions() {
    final activeSet = (widget.initialPermissions ?? _defaultRolePermissions(_currentRole)).toSet();

    for (final mod in _modules) {
      final name = mod['name'].toString();
      _permissionsMap[name] = activeSet.contains(name) || activeSet.contains(name.replaceAll('\n', ' '));
    }
  }

  List<String> _defaultRolePermissions(String role) {
    return switch (role) {
      'Inventory Manager' => ['Dashboard', 'Inventory', 'Suppliers', 'Gold Rate'],
      'View Only' => ['Dashboard', 'Gold Rate'],
      'Shop Manager' => ['Dashboard', 'Customers', 'Payments', 'Inventory', 'Suppliers', 'Gold Rate', 'Reports & Export'],
      _ => ['Dashboard', 'Customers', 'Payments', 'Gold Rate'],
    };
  }

  void _resetToDefault() {
    final defaults = _defaultRolePermissions(_currentRole).toSet();
    setState(() {
      for (final mod in _modules) {
        final name = mod['name'].toString();
        _permissionsMap[name] = defaults.contains(name) || defaults.contains(name.replaceAll('\n', ' '));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions reset to default!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _savePermissions() async {
    final enabledList = _permissionsMap.entries
        .where((e) => e.value)
        .map((e) => e.key.replaceAll('\n', ' '))
        .toList();

    if (widget.isWorkerSpecific) {
      Navigator.pop(context, enabledList);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'role_permissions_$_currentRole';
    await prefs.setStringList(key, enabledList);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role permissions saved successfully!'),
        backgroundColor: Color(0xFF247A4B),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, enabledList);
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
        title: const Text('Role & Permissions', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                children: [
                  // Role Selector Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                          child: const Icon(Icons.group_outlined, color: _primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _currentRole,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                              style: const TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.w700),
                              items: const [
                                DropdownMenuItem(value: 'Sales & Billing', child: Text('Sales & Billing')),
                                DropdownMenuItem(value: 'Inventory Manager', child: Text('Inventory Manager')),
                                DropdownMenuItem(value: 'View Only', child: Text('View Only')),
                                DropdownMenuItem(value: 'Shop Manager', child: Text('Shop Manager')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _currentRole = v;
                                    _initializePermissions();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Custom role name edit ready')),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, color: _primary, size: 20),
                          tooltip: 'Edit Role Name',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('Set what this role can do in the app.', style: TextStyle(color: _muted, fontSize: 12)),
                  ),
                  const SizedBox(height: 14),

                  // Permission Toggles Card List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _modules.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: _border),
                          _permissionToggleRow(_modules[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: const BoxDecoration(
                color: _background,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetToDefault,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: Color(0xFFC8B2DD)),
                        backgroundColor: const Color(0xFFF4ECFB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Reset', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _savePermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Permissions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionToggleRow(Map<String, dynamic> mod) {
    final name = mod['name'].toString();
    final icon = mod['icon'] as IconData;
    final isEnabled = _permissionsMap[name] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            activeThumbColor: _primary,
            activeTrackColor: const Color(0xFFC8B2DD),
            onChanged: (val) {
              setState(() {
                _permissionsMap[name] = val;
              });
            },
          ),
        ],
      ),
    );
  }
}
