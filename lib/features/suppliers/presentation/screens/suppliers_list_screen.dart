import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../services/api_client.dart';
import '../../../../services/cache_service.dart';
import '../../../customers/presentation/screens/new_customer_screen.dart';
import 'supplier_details_screen.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_Supplier> _suppliers = <_Supplier>[];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isOffline = false;
  String? _lastUpdatedTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadSuppliers() async {
    // 1. Read cached data first for instant offline/cache load
    final cached = await CacheService.instance.getCacheData('cache_suppliers');
    final timestamp = await CacheService.instance.getCacheTimestamp('cache_suppliers');

    if (cached != null) {
      final parsedCached = _parseSuppliersPayload(cached);
      if (mounted) {
        setState(() {
          _suppliers = parsedCached;
          _isLoading = false;
          _error = null;
          if (timestamp != null) {
            _lastUpdatedTime =
                '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
    }

    // 2. Fetch fresh backend data from GET /api?filter=$filterParam
    try {
      final filterParam = switch (_selectedFilter) {
        'With Baki' => 'baki',
        'Paid / Settled' => 'paid',
        _ => 'all',
      };

      final response = await ApiClient.instance.get(
        Uri.parse('${ApiConfig.suppliersUrl}?filter=$filterParam'),
        headers: const <String, String>{
          'Accept': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        await CacheService.instance.saveCache('cache_suppliers', decoded);

        final parsed = _parseSuppliersPayload(decoded);

        if (!mounted) return;
        setState(() {
          _suppliers = parsed;
          _isLoading = false;
          _isOffline = false;
          _error = null;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expired or access denied. Please sign in again.');
      } else {
        var message = 'Unable to load suppliers (${response.statusCode}).';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['detail'] != null) {
            message = body['detail'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;
      if (_suppliers.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _isOffline = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<_Supplier> _parseSuppliersPayload(dynamic decoded) {
    List rawList = [];
    if (decoded is Map<String, dynamic>) {
      final list = decoded['suppliers'];
      if (list is List) {
        rawList = list;
      }
    } else if (decoded is List) {
      rawList = decoded;
    }

    return rawList.whereType<Map>().map((row) {
      final map = Map<String, dynamic>.from(row);
      final name = (map['name'] ?? map['supplier_name'] ?? 'Unknown supplier').toString();
      final phone = (map['phone_number'] ?? '').toString();
      final owed = _toDouble(
        map['total_due'] ?? map['total_due_amount'] ?? map['amount_owed'] ?? map['baki'] ?? map['due_amount'],
      );
      final id = (map['supplier_id'] ?? map['id'] ?? '').toString();
      final initials = _initials(name);

      return _Supplier(
        id: id,
        name: name,
        phone: phone,
        amountOwed: owed,
        initials: initials,
      );
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<_Supplier> get _filteredSuppliers {
    final query = _searchController.text.trim().toLowerCase();
    final digitsQuery = query.replaceAll(RegExp(r'[^0-9]'), '');

    return _suppliers.where((supplier) {
      final phoneDigits = supplier.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final matchesSearch = supplier.name.toLowerCase().contains(query) ||
          (digitsQuery.isNotEmpty && phoneDigits.contains(digitsQuery));
      final matchesFilter = switch (_selectedFilter) {
        'With Baki' => supplier.amountOwed > 0,
        'Paid / Settled' => supplier.amountOwed <= 0,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _money(double amount) {
    final value = amount.round().toString();
    if (value.length <= 3) return value;
    final lastThree = value.substring(value.length - 3);
    var rest = value.substring(0, value.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$lastThree';
  }

  Future<void> _addSupplier() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NewCustomerScreen(isSupplier: true),
      ),
    );

    if (mounted) {
      await _loadSuppliers();
    }
  }

  String _e164Phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.trim().startsWith('+')) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return digits;
  }

  Future<void> _callSupplier(_Supplier supplier) async {
    final phone = _e164Phone(supplier.phone);
    if (phone.isEmpty) {
      _showActionError('This supplier has no phone number.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      _showActionError('Could not open the phone app.');
    }
  }

  Future<void> _messageSupplier(_Supplier supplier) async {
    final phone = _e164Phone(supplier.phone);
    if (phone.isEmpty) {
      _showActionError('This supplier has no phone number.');
      return;
    }
    final uri = Uri(scheme: 'sms', path: phone);
    if (!await launchUrl(uri)) {
      _showActionError('Could not open the messaging app.');
    }
  }

  void _showActionError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openSupplier(_Supplier supplier) async {
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuidRegExp.hasMatch(supplier.id)) {
      _showActionError('Invalid supplier ID.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SupplierDetailsScreen(
          supplierId: supplier.id,
          supplierName: supplier.name,
          supplierPhone: supplier.phone,
        ),
      ),
    );
    if (mounted) await _loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersToDisplay = _filteredSuppliers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
          color: AppColors.heading,
        ),
        title: const Text(
          'Suppliers',
          style: TextStyle(
            color: AppColors.heading,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh suppliers',
            onPressed: _loadSuppliers,
            icon: const Icon(Icons.refresh_rounded, size: 27),
            color: AppColors.heading,
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_isOffline) OfflineBanner(lastUpdated: _lastUpdatedTime),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search supplier by name or phone...',
                  hintStyle: const TextStyle(
                    color: AppColors.body,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 27,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: ['All', 'With Baki', 'Paid / Settled', 'Recent']
                    .map((filter) {
                  final selected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                        _loadSuppliers();
                      },
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.primary,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const SkeletonList()
                  : _error != null
                      ? _LoadError(
                          message: _error!,
                          onRetry: _loadSuppliers,
                        )
                      : suppliersToDisplay.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: AppColors.body,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No suppliers yet',
                                      style: TextStyle(
                                        color: AppColors.heading,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Add your first supplier to keep track of purchases and payments.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.body,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _loadSuppliers,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                                itemCount: suppliersToDisplay.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final supplier = suppliersToDisplay[index];
                                  return _SupplierTile(
                                    supplier: supplier,
                                    onTap: () => _openSupplier(supplier),
                                    onCall: () => _callSupplier(supplier),
                                    onMessage: () => _messageSupplier(supplier),
                                    formatMoney: _money,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSupplier,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Supplier',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Supplier {
  const _Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.amountOwed,
    required this.initials,
  });

  final String id;
  final String name;
  final String phone;
  final double amountOwed;
  final String initials;
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({
    required this.supplier,
    required this.onTap,
    required this.onCall,
    required this.onMessage,
    required this.formatMoney,
  });

  final _Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final isBaki = supplier.amountOwed > 0;
    final isJama = supplier.amountOwed < 0;
    final absAmount = supplier.amountOwed.abs();

    final badgeText = isBaki
        ? 'Baki'
        : isJama
            ? 'Jama'
            : 'Settled';

    final badgeColor = isBaki
        ? AppColors.error
        : isJama
            ? AppColors.success
            : AppColors.body;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
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
              backgroundColor: const Color(0xFFF3E7F8),
              child: Text(
                supplier.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.heading,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier.phone.isEmpty
                        ? 'No phone number'
                        : supplier.phone,
                    style: const TextStyle(
                      color: AppColors.body,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹ ${formatMoney(absAmount)}',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.phone_outlined, size: 20),
              color: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onMessage,
              icon: const Icon(Icons.message_outlined, size: 20),
              color: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load suppliers',
              style: TextStyle(
                color: AppColors.heading,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.body),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
