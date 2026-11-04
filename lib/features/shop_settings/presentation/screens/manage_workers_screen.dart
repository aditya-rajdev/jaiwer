import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import 'add_worker_screen.dart';
import 'worker_details_screen.dart';

class WorkerModel {
  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.joinDate,
    required this.permissions,
  });

  final String id;
  String name;
  String phone;
  String role;
  String status; // 'Active' or 'Inactive'
  String joinDate;
  List<String> permissions;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'W';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'status': status,
        'joinDate': joinDate,
        'permissions': permissions,
      };

  factory WorkerModel.fromJson(Map<String, dynamic> json) => WorkerModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Worker').toString(),
        phone: (json['phone'] ?? '').toString(),
        role: (json['role'] ?? 'Sales & Billing').toString(),
        status: (json['status'] ?? 'Active').toString(),
        joinDate: (json['joinDate'] ?? '20 Oct 2026').toString(),
        permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ??
            ['Dashboard', 'Customers', 'Payments', 'Gold Rate'],
      );
}

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _muted = Color(0xFF718096);
  static const Color _green = Color(0xFF16B85A);
  static const Color _red = Color(0xFFE53935);

  List<WorkerModel> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('shop_workers_list');

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(jsonStr);
        _workers = decoded.map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item))).toList();
      } catch (_) {
        _workers = _defaultWorkers();
      }
    } else {
      _workers = _defaultWorkers();
      await _saveWorkersLocally();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<WorkerModel> _defaultWorkers() {
    return [
      WorkerModel(
        id: 'w_1',
        name: 'Vikash Kumar',
        phone: '+91 91234 56789',
        role: 'Sales & Billing',
        status: 'Active',
        joinDate: '20 Oct 2026',
        permissions: ['Dashboard', 'Customers', 'Payments', 'Gold Rate'],
      ),
      WorkerModel(
        id: 'w_2',
        name: 'Rohit Singh',
        phone: '+91 98765 43210',
        role: 'Inventory Manager',
        status: 'Active',
        joinDate: '15 Sep 2026',
        permissions: ['Dashboard', 'Inventory', 'Suppliers', 'Gold Rate'],
      ),
      WorkerModel(
        id: 'w_3',
        name: 'Ankit Kumar',
        phone: '+91 95555 12345',
        role: 'View Only',
        status: 'Inactive',
        joinDate: '01 Aug 2026',
        permissions: ['Dashboard', 'Gold Rate'],
      ),
    ];
  }

  Future<void> _saveWorkersLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_workers.map((w) => w.toJson()).toList());
    await prefs.setString('shop_workers_list', jsonStr);
  }

  int get _totalWorkers => _workers.length;
  int get _activeWorkers => _workers.where((w) => w.status.toLowerCase() == 'active').length;
  int get _inactiveWorkers => _workers.where((w) => w.status.toLowerCase() != 'active').length;

  Future<void> _openAddWorker() async {
    final newWorker = await Navigator.of(context).push<WorkerModel>(
      MaterialPageRoute<WorkerModel>(
        builder: (_) => const AddWorkerScreen(),
      ),
    );

    if (newWorker != null) {
      setState(() {
        _workers.add(newWorker);
      });
      await _saveWorkersLocally();
    }
  }

  Future<void> _openWorkerDetails(WorkerModel worker) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkerDetailsScreen(worker: worker),
      ),
    );

    if (updated == true) {
      await _loadWorkers();
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
            Text('Manage Workers', style: TextStyle(color: _primary, fontSize: 19, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Add team members and manage their access', style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddWorker,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            tooltip: 'Add Worker',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Summary Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.people_outline_rounded,
                          value: '$_totalWorkers',
                          label: 'Total Workers',
                          color: _primary,
                          bg: const Color(0xFFF4ECFB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '$_activeWorkers',
                          label: 'Active',
                          color: _green,
                          bg: const Color(0xFFE2F8E8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.block_rounded,
                          value: '$_inactiveWorkers',
                          label: 'Inactive',
                          color: _red,
                          bg: const Color(0xFFFFE6E6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Worker List
                  for (final worker in _workers) ...[
                    _workerCard(worker),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: bg,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _workerCard(WorkerModel worker) {
    final isActive = worker.status.toLowerCase() == 'active';

    return InkWell(
      onTap: () => _openWorkerDetails(worker),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: AppColors.heading.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF8E4C8),
              child: Text(
                worker.initials,
                style: const TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5C9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          worker.role,
                          style: const TextStyle(color: Color(0xFF482A12), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _primary, size: 26),
          ],
        ),
      ),
    );
  }
}
