import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manage_workers_screen.dart';

class WorkerDetailsScreen extends StatefulWidget {
  const WorkerDetailsScreen({super.key, required this.worker});

  final WorkerModel worker;

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);
  static const Color _green = Color(0xFF16B85A);
  static const Color _red = Color(0xFFE53935);

  int _selectedTab = 0;
  late WorkerModel _worker;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
  }

  Future<void> _updateWorkerInStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('shop_workers_list');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(jsonStr);
        final list = decoded.map((e) => WorkerModel.fromJson(Map<String, dynamic>.from(e))).toList();
        final index = list.indexWhere((w) => w.id == _worker.id);
        if (index != -1) {
          list[index] = _worker;
          await prefs.setString('shop_workers_list', jsonEncode(list.map((w) => w.toJson()).toList()));
        }
      } catch (_) {}
    }
  }

  Future<void> _toggleStatus() async {
    final isActive = _worker.status.toLowerCase() == 'active';
    final action = isActive ? 'Deactivate' : 'Activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('$action Worker'),
        content: Text('Are you sure you want to $action ${_worker.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isActive ? _red : _green),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _worker.status = isActive ? 'Inactive' : 'Active';
      });
      await _updateWorkerInStorage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worker is now ${_worker.status}')),
      );
    }
  }

  Future<void> _changeRole() async {
    final roles = ['Sales & Billing', 'Inventory Manager', 'View Only', 'Shop Manager'];
    final newRole = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('Change Worker Role', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
        children: roles
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogCtx, r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(r, style: const TextStyle(fontSize: 16, color: _primary)),
                  ),
                ))
            .toList(),
      ),
    );

    if (newRole != null && newRole != _worker.role && mounted) {
      setState(() {
        _worker.role = newRole;
        _worker.permissions = switch (newRole) {
          'Inventory Manager' => ['Dashboard', 'Inventory', 'Suppliers', 'Gold Rate'],
          'View Only' => ['Dashboard', 'Gold Rate'],
          'Shop Manager' => ['Dashboard', 'Customers', 'Payments', 'Inventory', 'Suppliers', 'Gold Rate', 'Reports & Export'],
          _ => ['Dashboard', 'Customers', 'Payments', 'Gold Rate'],
        };
      });
      await _updateWorkerInStorage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $newRole')),
      );
    }
  }

  Future<void> _editWorker() async {
    final nameCtrl = TextEditingController(text: _worker.name);
    final phoneCtrl = TextEditingController(text: _worker.phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Worker Details', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _worker.name = nameCtrl.text.trim();
        _worker.phone = phoneCtrl.text.trim();
      });
      await _updateWorkerInStorage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker details updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _worker.status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
        ),
        title: const Text('Worker Details', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _primary),
            onSelected: (val) {
              if (val == 'edit') _editWorker();
              if (val == 'role') _changeRole();
              if (val == 'status') _toggleStatus();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
              const PopupMenuItem(value: 'role', child: Text('Change Role')),
              PopupMenuItem(value: 'status', child: Text(isActive ? 'Deactivate Worker' : 'Activate Worker')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFF8E4C8),
                          child: Text(
                            _worker.initials,
                            style: const TextStyle(color: _primary, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _worker.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFE2F8E8) : const Color(0xFFFFE6E6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, color: isActive ? _green : _red, size: 6),
                                        const SizedBox(width: 4),
                                        Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(color: isActive ? _green : _red, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.workspace_premium_outlined, color: _primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(_worker.role, style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, color: _muted, size: 15),
                                  const SizedBox(width: 4),
                                  Text(_worker.phone, style: const TextStyle(color: _muted, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tabs Header
                  Row(
                    children: [
                      _tabButton('Overview', 0),
                      _tabButton('Permissions (${_worker.permissions.length})', 1),
                    ],
                  ),
                  Container(height: 1, color: _border),

                  const SizedBox(height: 16),

                  if (_selectedTab == 0) ...[
                    // Overview Tab Content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          _detailRow(Icons.calendar_month_outlined, 'Join Date', _worker.joinDate),
                          const Divider(color: _border, height: 20),
                          _detailRow(Icons.workspace_premium_outlined, 'Role', _worker.role),
                          const Divider(color: _border, height: 20),
                          _detailRowWidget(
                            Icons.check_circle_outline,
                            'Status',
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFFE2F8E8) : const Color(0xFFFFE6E6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(color: isActive ? _green : _red, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Accessible Modules Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.grid_view_rounded, color: _primary, size: 20),
                              SizedBox(width: 8),
                              Text('Accessible Modules', style: TextStyle(color: _primary, fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _worker.permissions.map((p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4ECFB),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2D4EE)),
                              ),
                              child: Text(p, style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Permissions Tab Content
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          for (final mod in [
                            'Dashboard',
                            'Customers',
                            'Payments',
                            'Inventory',
                            'Suppliers',
                            'Gold Rate',
                            'Reports & Export',
                            'Shop Settings',
                            'Manage Workers',
                            'Financial Correction (Edit / Delete / Restore)'
                          ]) ...[
                            _permissionItemRow(mod, _worker.permissions.contains(mod)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Action Bar (3 buttons)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: _background,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editWorker,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        backgroundColor: const Color(0xFFF4ECFB),
                        side: const BorderSide(color: Color(0xFFE2D4EE)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _changeRole,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Change Role'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        backgroundColor: const Color(0xFFF4ECFB),
                        side: const BorderSide(color: Color(0xFFE2D4EE)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleStatus,
                      icon: Icon(isActive ? Icons.power_settings_new_rounded : Icons.check_circle_outline, size: 18),
                      label: Text(isActive ? 'Deactivate' : 'Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? const Color(0xFFFFE6E6) : const Color(0xFFE2F8E8),
                        foregroundColor: isActive ? _red : _green,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

  Widget _tabButton(String label, int index) => Expanded(
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _selectedTab == index ? _primary : Colors.transparent, width: 2),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _selectedTab == index ? _primary : _muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

  Widget _detailRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _detailRowWidget(IconData icon, String label, Widget widget) => Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const Spacer(),
          widget,
        ],
      );

  Widget _permissionItemRow(String name, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: isEnabled ? _green : _muted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isEnabled ? _primary : _muted,
                fontSize: 14,
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isEnabled ? const Color(0xFFE2F8E8) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isEnabled ? 'Allowed' : 'Denied',
              style: TextStyle(
                color: isEnabled ? _green : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
