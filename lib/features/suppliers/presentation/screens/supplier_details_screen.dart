import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../services/api_client.dart';
import '../../../../services/cache_service.dart';
import '../../../customers/presentation/screens/new_customer_screen.dart';

class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({
    super.key,
    required this.supplierId,
    required this.supplierName,
    required this.supplierPhone,
  });

  final String supplierId;
  final String supplierName;
  final String supplierPhone;

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierItem {
  const _SupplierItem({
    required this.id,
    required this.itemName,
    required this.weightGrams,
    this.ratePerGram,
    required this.totalAmount,
    required this.amountPaid,
    required this.dueAmount,
    this.createdAt,
  });

  final String id;
  final String itemName;
  final double weightGrams;
  final double? ratePerGram;
  final double totalAmount;
  final double amountPaid;
  final double dueAmount;
  final DateTime? createdAt;
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  static const _purple = Color(0xFF35113F);
  static const _cream = Color(0xFFFFFAF2);
  static const _border = Color(0xFFEDE4D9);
  static const _muted = Color(0xFF718096);
  static const _green = Color(0xFF16B85A);
  static const _red = Color(0xFFE53935);

  int _tab = 0;

  List<_SupplierItem> _items = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _lastUpdatedTime;
  String? _error;

  String _address = 'Address not added';
  int _totalPurchase = 0;
  int _totalPaid = 0;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadSupplierDetails();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    return _toDouble(value).round();
  }

  String _displayPhone(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return 'No phone number';
    while (trimmed.startsWith('+91') ||
        trimmed.startsWith('+ 91') ||
        (trimmed.startsWith('91') &&
            trimmed.replaceAll(RegExp(r'[^0-9]'), '').length > 10)) {
      if (trimmed.startsWith('+91')) {
        trimmed = trimmed.substring(3).trim();
      } else if (trimmed.startsWith('+ 91')) {
        trimmed = trimmed.substring(4).trim();
      } else if (trimmed.startsWith('91')) {
        trimmed = trimmed.substring(2).trim();
      }
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+91 $digits';
    return '+91 $digits';
  }

  String _e164Phone(String raw) {
    var trimmed = raw.trim();
    while (trimmed.startsWith('+91') ||
        trimmed.startsWith('+ 91') ||
        (trimmed.startsWith('91') &&
            trimmed.replaceAll(RegExp(r'[^0-9]'), '').length > 10)) {
      if (trimmed.startsWith('+91')) {
        trimmed = trimmed.substring(3).trim();
      } else if (trimmed.startsWith('+ 91')) {
        trimmed = trimmed.substring(4).trim();
      } else if (trimmed.startsWith('91')) {
        trimmed = trimmed.substring(2).trim();
      }
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+$digits';
    return '+$digits';
  }

  Future<void> _callSupplier() async {
    final phone = _e164Phone(widget.supplierPhone);
    if (phone.isEmpty || phone == '+') {
      _message('This supplier has no phone number.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (!await launchUrl(uri)) {
        _message('Could not open the phone app.');
      }
    } catch (_) {
      _message('Could not open the phone app.');
    }
  }

  Future<void> _messageSupplier() async {
    final phone = _e164Phone(widget.supplierPhone);
    if (phone.isEmpty || phone == '+') {
      _message('This supplier has no phone number.');
      return;
    }
    final uri = Uri(scheme: 'sms', path: phone);
    try {
      if (!await launchUrl(uri)) {
        _message('Could not open the messaging app.');
      }
    } catch (_) {
      _message('Could not open the messaging app.');
    }
  }

  Future<void> _loadSupplierDetails() async {
    final id = widget.supplierId.trim();
    if (id.isEmpty) return;

    final cacheKey = 'cache_supplier_details_$id';
    final cached = await CacheService.instance.getCacheData(cacheKey);
    final timestamp = await CacheService.instance.getCacheTimestamp(cacheKey);

    if (cached != null && cached is Map<String, dynamic>) {
      _applyDecodedData(cached);
      if (mounted) {
        setState(() {
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

    try {
      final response = await ApiClient.instance.get(
        Uri.parse('${ApiConfig.suppliersUrl}/$id'),
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          await CacheService.instance.saveCache(cacheKey, decoded);
          _applyDecodedData(decoded);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expired or access denied. Please sign in again.');
      } else {
        throw Exception('Could not fetch supplier data (${response.statusCode}).');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOffline = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_items.isNotEmpty || _totalPurchase > 0) {
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

  void _applyDecodedData(Map<String, dynamic> decoded) {
    final suppMap = decoded['supplier'];
    if (suppMap is Map && suppMap['address'] != null) {
      final addr = suppMap['address'].toString().trim();
      if (addr.isNotEmpty) {
        _address = addr;
      }
    }

    final summaryMap = decoded['summary'];
    if (summaryMap is Map) {
      _totalPurchase = _toInt(summaryMap['total_purchase_amount'] ?? summaryMap['total_purchase'] ?? summaryMap['total_amount']);
      _totalPaid = _toInt(summaryMap['total_paid']);
      _balance = _toInt(summaryMap['total_due'] ?? summaryMap['amount_owed'] ?? summaryMap['baki'] ?? summaryMap['due_amount']);
    }

    final itemsList = decoded['items'];
    if (itemsList is List) {
      _items = itemsList.whereType<Map>().map((map) {
        final m = Map<String, dynamic>.from(map);
        final id = (m['item_id'] ?? m['id'] ?? '').toString();
        final name = (m['item_name'] ?? 'Jewellery Item').toString();
        final weight = _toDouble(m['weight_grams']);
        final rate = m['rate_per_gram'] != null ? _toDouble(m['rate_per_gram']) : null;
        final total = _toDouble(m['total_amount']);
        final paid = _toDouble(m['amount_paid']);
        final due = _toDouble(m['due_amount']);

        DateTime? createdAt;
        if (m['created_at'] != null) {
          createdAt = DateTime.tryParse(m['created_at'].toString());
        }

        return _SupplierItem(
          id: id,
          itemName: name,
          weightGrams: weight,
          ratePerGram: rate,
          totalAmount: total,
          amountPaid: paid,
          dueAmount: due,
          createdAt: createdAt,
        );
      }).toList();
    }
  }

  String _money(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final last = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$last';
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

  Future<void> _addNewEntry() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NewCustomerScreen(isSupplier: true),
      ),
    );
    if (mounted && result == true) {
      await _loadSupplierDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.supplierName;
    final initials = _initials(name);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _purple),
        ),
        title: const Text('Supplier Details', style: TextStyle(color: _purple, fontSize: 21, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _message('Edit supplier is demo-only for now'),
            child: const Text('Edit', style: TextStyle(color: _purple, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            if (_isOffline) OfflineBanner(lastUpdated: _lastUpdatedTime),
            _card(
              child: Row(children: [
                CircleAvatar(
                  radius: 37,
                  backgroundColor: const Color(0xFFF8E4C8),
                  child: Text(initials, style: const TextStyle(color: _purple, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _purple, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_displayPhone(widget.supplierPhone), style: const TextStyle(color: _muted, fontSize: 13)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: _purple, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _roundAction(Icons.call_rounded, const Color(0xFFF2ECFA), _purple, _callSupplier),
                const SizedBox(width: 6),
                _roundAction(Icons.chat_rounded, const Color(0xFFE0F7E8), _green, _messageSupplier),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _summaryCard(Icons.shopping_bag_rounded, 'Total Purchase', '₹ ${_money(_totalPurchase)}', const Color(0xFFD49A3A), const Color(0xFFFFF0D6))),
              const SizedBox(width: 8),
              Expanded(child: _summaryCard(Icons.check_circle_rounded, 'Total Paid', '₹ ${_money(_totalPaid)}', _green, const Color(0xFFE2F8E8))),
              const SizedBox(width: 8),
              Expanded(child: _summaryCard(Icons.account_balance_wallet_rounded, 'Balance', '₹ ${_money(_balance)}', _red, const Color(0xFFFFE6E6))),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _tabButton('Transactions', 0),
              _tabButton('Items (${_items.length})', 1),
              _tabButton('Details', 2),
            ]),
            Container(height: 1, color: _border),
            const SizedBox(height: 10),
            if (_isLoading) ...[
              const SkeletonTransactionList(count: 3),
            ] else if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: _red, size: 36),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.body, fontSize: 13)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadSupplierDetails,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                      style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ] else if (_tab == 0) ...[
              if (_items.isEmpty)
                _emptyState('No transaction records found for this supplier.')
              else
                for (final item in _items) _buildItemRow(item),
            ] else if (_tab == 1) ...[
              if (_items.isEmpty)
                _emptyState('No items found for this supplier.')
              else
                for (final item in _items) _buildItemRow(item),
            ] else ...[
              _card(
                child: Column(
                  children: [
                    _detailRow('Supplier Name', name),
                    const Divider(color: _border),
                    _detailRow('Phone Number', _displayPhone(widget.supplierPhone)),
                    const Divider(color: _border),
                    _detailRow('Address', _address),
                    const Divider(color: _border),
                    _detailRow('Total Items', '${_items.length}'),
                    const Divider(color: _border),
                    _detailRow('Supplier Type', 'Jewellery Supplier'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: _cream,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _message('Record Payment form will be connected next'),
                icon: const Icon(Icons.currency_rupee_rounded),
                label: const Text('Record Payment', maxLines: 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFFC8B2DD)),
                  backgroundColor: const Color(0xFFF4ECFB),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addNewEntry,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Entry', maxLines: 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildItemRow(_SupplierItem item) {
    final date = item.createdAt ?? DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();

    final rateText = item.ratePerGram != null && item.ratePerGram! > 0
        ? 'Rate: ₹ ${_money(item.ratePerGram!.round())}/g'
        : 'Rate: —';
    final metaText = 'Weight: ${item.weightGrams.toStringAsFixed(1)} g';

    return _transactionItem(
      day,
      month,
      year,
      item.itemName,
      metaText,
      rateText,
      item.totalAmount.round(),
      item.amountPaid.round(),
      item.dueAmount.round(),
    );
  }

  Widget _emptyState(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.inventory_2_outlined, color: _muted, size: 40),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _tabButton(String title, int index) => Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _tab == index ? _purple : Colors.transparent, width: 2),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: _tab == index ? _purple : _muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: child,
      );

  Widget _summaryCard(IconData icon, String title, String value, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 16, backgroundColor: bg, child: Icon(icon, size: 17, color: color)),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(color: color == _red ? _red : (color == _green ? _green : _purple), fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _roundAction(IconData icon, Color bg, Color fg, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: CircleAvatar(radius: 22, backgroundColor: bg, child: Icon(icon, color: fg, size: 21)),
      );

  Widget _transactionItem(String day, String month, String year, String title, String meta, String rate, int total, int paid, int balance) => Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF2ECFA), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(day, style: const TextStyle(color: _purple, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(month, style: const TextStyle(color: _muted, fontSize: 11)),
                  Text(year, style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(meta, style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(rate, style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹ ${_money(total)}', style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('Paid: ₹ ${_money(paid)}', style: const TextStyle(color: _green, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Baki: ₹ ${_money(balance)}', style: const TextStyle(color: _red, fontSize: 12)),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, color: _purple, size: 24),
          ],
        ),
      );

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 13))),
            Text(value, style: const TextStyle(color: _purple, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
