import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_client.dart';
import 'new_customer_screen.dart';
import 'customer_details_screen.dart';

/// Customer list backed by GET /customers.
/// The backend's current summary response provides customer_id, name,
/// phone_number and amount_owed. Total/item-count require a richer API response.
class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {

  final TextEditingController _searchController = TextEditingController();
  List<_Customer> _customers = <_Customer>[];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
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

  Future<void> _loadCustomers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiClient.instance.get(
        Uri.parse('${ApiConfig.baseUrl}/customers'),
        headers: <String, String>{
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List rawList = [];
        if (decoded is Map<String, dynamic>) {
          final customersList = decoded['customers'];
          if (customersList is List) {
            rawList = customersList;
          }
        } else if (decoded is List) {
          rawList = decoded;
        } else {
          throw const FormatException(
            'Unexpected customers response from server.',
          );
        }

        final parsed = rawList
            .whereType<Map>()
            .map((row) {
          final map = Map<String, dynamic>.from(row);
          final name = (map['name'] ?? 'Unknown customer').toString();
          final phone = (map['phone_number'] ?? '').toString();
          final owed = _toDouble(
            map['total_due_amount'] ?? map['amount_owed'] ?? map['baki'] ?? map['due_amount'],
          );
          final id = (map['customer_id'] ?? map['id'] ?? '').toString();
          final initials = _initials(name);

          return _Customer(
            id: id,
            name: name,
            phone: phone,
            amountOwed: owed,
            initials: initials,
          );
        })
            .toList();

        if (!mounted) return;
        setState(() {
          _customers = parsed;
          _isLoading = false;
          _error = null;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expired or access denied. Please sign in again.');
      } else {
        var message = 'Unable to load customers (${response.statusCode}).';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['detail'] != null) {
            message = body['detail'].toString();
          }
        } catch (_) {
          // Keep the status-code message when the response isn't JSON.
        }
        throw Exception(message);
      }
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<_Customer> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    final digitsQuery = query.replaceAll(RegExp(r'[^0-9]'), '');

    final list = _customers.where((customer) {
      final phoneDigits = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final matchesSearch = customer.name.toLowerCase().contains(query) ||
          (digitsQuery.isNotEmpty && phoneDigits.contains(digitsQuery));
      final matchesFilter = switch (_selectedFilter) {
        'With Baki' => customer.amountOwed > 0,
        'With Jama' => customer.amountOwed <= 0,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    if (_selectedFilter == 'Recent') {
      // The current API summary doesn't return created_at, so preserve server order.
      return list;
    }
    return list;
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

  Future<void> _addCustomer() async {
    // NewCustomerScreen returns true after a successful API creation.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NewCustomerScreen(),
      ),
    );

    // Always refresh on return as a safeguard, even if the form doesn't return true.
    if (mounted && result == true) {
      await _loadCustomers();
    } else if (mounted) {
      await _loadCustomers();
    }
  }

  String _e164Phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.trim().startsWith('+')) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return digits;
  }

  Future<void> _callCustomer(_Customer customer) async {
    final phone = _e164Phone(customer.phone);
    if (phone.isEmpty) {
      _showActionError('This customer has no phone number.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      _showActionError('Could not open the phone app.');
    }
  }

  Future<void> _messageCustomer(_Customer customer) async {
    final phone = _e164Phone(customer.phone);
    if (phone.isEmpty) {
      _showActionError('This customer has no phone number.');
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

  Future<void> _openCustomer(_Customer customer) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailsScreen(
          customer: CustomerDetailsData(
            id: customer.id,
            name: customer.name,
            phone: customer.phone,
            initials: customer.initials,
            total: customer.amountOwed.round(),
            baki: customer.amountOwed.round(),
            items: 0,
          ),
        ),
      ),
    );
    if (mounted) await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          color: AppColors.heading,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Customers (${_isLoading ? '…' : customers.length})',
          style: const TextStyle(
            color: AppColors.heading,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh customers',
            onPressed: _loadCustomers,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
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
                children: ['All', 'With Baki', 'With Jama', 'Recent']
                    .map((filter) {
                  final selected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
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
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _LoadError(
                message: _error!,
                onRetry: _loadCustomers,
              )
                  : customers.isEmpty
                  ? RefreshIndicator(
                onRefresh: _loadCustomers,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.people_outline_rounded,
                      size: 56,
                      color: AppColors.body,
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(
                          color: AppColors.body,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadCustomers,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(20, 2, 20, 96),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 8,
                    endIndent: 8,
                    color: AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerTile(
                      customer: customer,
                      bakiText: _money(customer.amountOwed),
                      onTap: () => _openCustomer(customer),
                      onCall: () => _callCustomer(customer),
                      onMessage: () => _messageCustomer(customer),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
    );
  }
}

class _Customer {
  const _Customer({
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

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.bakiText,
    required this.onTap,
    required this.onCall,
    required this.onMessage,
  });

  final _Customer customer;
  final String bakiText;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final phone = customer.phone.startsWith('+')
        ? customer.phone
        : customer.phone.isEmpty
        ? 'Phone not available'
        : '+${customer.phone}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 3),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF8E4C8),
              child: Text(
                customer.initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.heading,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.body,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onCall,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_outlined, size: 16, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('Call', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onMessage,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.message_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Message', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Customer ID: ${customer.id.isEmpty ? '—' : customer.id.substring(0, customer.id.length > 8 ? 8 : customer.id.length)}',
                    style: const TextStyle(
                      color: AppColors.body,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Baki',
                  style: TextStyle(color: AppColors.body, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '₹ $bakiText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: customer.amountOwed <= 0
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 25,
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
              'Could not load customers',
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
