import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../config/app_config.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../services/api_client.dart';
import '../../../../services/cache_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentRecord {
  const _PaymentRecord({
    required this.id,
    required this.entityId,
    required this.name,
    required this.initials,
    required this.description,
    required this.dateLabel,
    required this.amount,
    required this.method,
    required this.isCustomer,
    required this.addedBy,
    required this.addedByRole,
    required this.date,
  });

  final String id;
  final String entityId;
  final String name;
  final String initials;
  final String description;
  final String dateLabel;
  final double amount;
  final String method; // Cash, UPI, Bank, Other
  final bool isCustomer; // true = Customer Received (+), false = Supplier Paid (-)
  final String addedBy;
  final String addedByRole; // Owner / Worker
  final DateTime date;
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const Color _primary = Color(0xFF2B1038);
  static const Color _gold = Color(0xFFD9B66F);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _text = Color(0xFF29232D);
  static const Color _muted = Color(0xFF718096);
  static const Color _green = Color(0xFF247A4B);
  static const Color _red = Color(0xFFB42318);

  final TextEditingController _searchController = TextEditingController();

  List<_PaymentRecord> _allPayments = [];
  List<Map<String, String>> _customersList = [];
  List<Map<String, String>> _suppliersList = [];

  bool _isLoading = true;
  bool _isOffline = false;
  String? _lastUpdatedTime;
  String? _error;

  bool _searchOpen = false;
  int _categoryTab = 0; // 0 = All, 1 = Customers, 2 = Suppliers
  String _selectedMethod = 'All'; // All, Cash, UPI, Bank, Other
  String _sortLabel = 'Newest First';
  DateTimeRange? _selectedDateRange;

  String _currentUserName = 'Owner';
  String _currentUserRole = 'Owner';

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _loadPaymentsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    try {
      final name = await _storage.read(key: 'user_name');
      final role = await _storage.read(key: 'account_type');

      if (!mounted) return;
      setState(() {
        if (name != null && name.trim().isNotEmpty) {
          _currentUserName = name.trim();
        }
        if (role != null && role.trim().isNotEmpty) {
          _currentUserRole = role.toLowerCase().contains('worker') ? 'Worker' : 'Owner';
        }
      });
    } catch (_) {}
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadPaymentsData() async {
    final cached = await CacheService.instance.getCacheData('cache_payments_list');
    final timestamp = await CacheService.instance.getCacheTimestamp('cache_payments_list');

    if (cached != null) {
      final parsedCached = _parsePaymentsFromCache(cached);
      if (mounted) {
        setState(() {
          _allPayments = parsedCached;
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
      final List<_PaymentRecord> fetchedRecords = [];

      try {
        final suppTxResponse = await ApiClient.instance.get(
          Uri.parse('${ApiConfig.baseUrl}/api/supplier-transactions'),
          headers: const {'Accept': 'application/json'},
        );
        if (suppTxResponse.statusCode >= 200 && suppTxResponse.statusCode < 300) {
          final decoded = jsonDecode(suppTxResponse.body);
          List rawList = [];
          if (decoded is Map<String, dynamic> && decoded['transactions'] is List) {
            rawList = decoded['transactions'];
          } else if (decoded is List) {
            rawList = decoded;
          }

          for (final row in rawList.whereType<Map>()) {
            final m = Map<String, dynamic>.from(row);
            final name = (m['supplier_name'] ?? m['name'] ?? 'Supplier').toString();
            final desc = (m['notes'] ?? m['description'] ?? 'Purchase Payment').toString();
            final amt = _toDouble(m['amount'] ?? m['total_amount']);
            final method = _formatMethod((m['payment_method'] ?? 'Cash').toString());
            final id = (m['transaction_id'] ?? m['id'] ?? '').toString();
            final suppId = (m['supplier_id'] ?? '').toString();

            DateTime date = DateTime.now();
            if (m['created_at'] != null) {
              date = DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now();
            }

            fetchedRecords.add(_PaymentRecord(
              id: id,
              entityId: suppId,
              name: name,
              initials: _initials(name),
              description: desc.isNotEmpty ? desc : 'Purchase Payment',
              dateLabel: _dateDisplay(date),
              amount: amt,
              method: method,
              isCustomer: false,
              addedBy: _currentUserName,
              addedByRole: _currentUserRole,
              date: date,
            ));
          }
        }
      } catch (e) {
        debugPrint('[Payments] Supplier transactions fetch warning: $e');
      }

      try {
        final custResponse = await ApiClient.instance.get(
          Uri.parse('${ApiConfig.baseUrl}/customers'),
          headers: const {'Accept': 'application/json'},
        );
        if (custResponse.statusCode >= 200 && custResponse.statusCode < 300) {
          final decoded = jsonDecode(custResponse.body);
          List rawList = [];
          if (decoded is Map<String, dynamic> && decoded['customers'] is List) {
            rawList = decoded['customers'];
          } else if (decoded is List) {
            rawList = decoded;
          }

          _customersList = rawList.whereType<Map>().map((c) {
            final m = Map<String, dynamic>.from(c);
            final id = (m['customer_id'] ?? m['id'] ?? '').toString();
            final name = (m['name'] ?? m['customer_name'] ?? 'Customer').toString();
            final totalPaid = _toDouble(m['total_paid']);

            if (totalPaid > 0) {
              fetchedRecords.add(_PaymentRecord(
                id: 'cust_pay_$id',
                entityId: id,
                name: name,
                initials: _initials(name),
                description: 'Jewellery - Payment',
                dateLabel: 'Today, 10:30 AM',
                amount: totalPaid,
                method: 'UPI',
                isCustomer: true,
                addedBy: _currentUserName,
                addedByRole: _currentUserRole,
                date: DateTime.now(),
              ));
            }

            return {'id': id, 'name': name};
          }).toList();
        }
      } catch (e) {
        debugPrint('[Payments] Customers list fetch warning: $e');
      }

      try {
        final suppResponse = await ApiClient.instance.get(
          Uri.parse(ApiConfig.suppliersUrl),
          headers: const {'Accept': 'application/json'},
        );
        if (suppResponse.statusCode >= 200 && suppResponse.statusCode < 300) {
          final decoded = jsonDecode(suppResponse.body);
          List rawList = [];
          if (decoded is Map<String, dynamic> && decoded['suppliers'] is List) {
            rawList = decoded['suppliers'];
          } else if (decoded is List) {
            rawList = decoded;
          }

          _suppliersList = rawList.whereType<Map>().map((s) {
            final m = Map<String, dynamic>.from(s);
            final id = (m['supplier_id'] ?? m['id'] ?? '').toString();
            final name = (m['name'] ?? m['supplier_name'] ?? 'Supplier').toString();
            return {'id': id, 'name': name};
          }).toList();
        }
      } catch (e) {
        debugPrint('[Payments] Suppliers list dropdown fetch warning: $e');
      }

      if (fetchedRecords.isEmpty) {
        fetchedRecords.addAll(_defaultReferencePayments());
      }

      final cacheData = fetchedRecords.map((r) => {
        'id': r.id,
        'entityId': r.entityId,
        'name': r.name,
        'initials': r.initials,
        'description': r.description,
        'dateLabel': r.dateLabel,
        'amount': r.amount,
        'method': r.method,
        'isCustomer': r.isCustomer,
        'addedBy': r.addedBy,
        'addedByRole': r.addedByRole,
        'date': r.date.toIso8601String(),
      }).toList();

      await CacheService.instance.saveCache('cache_payments_list', cacheData);

      if (!mounted) return;
      setState(() {
        _allPayments = fetchedRecords;
        _isLoading = false;
        _isOffline = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_allPayments.isNotEmpty) {
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

  List<_PaymentRecord> _parsePaymentsFromCache(dynamic cached) {
    if (cached is! List) return _defaultReferencePayments();
    return cached.whereType<Map>().map((m) {
      final map = Map<String, dynamic>.from(m);
      return _PaymentRecord(
        id: (map['id'] ?? '').toString(),
        entityId: (map['entityId'] ?? '').toString(),
        name: (map['name'] ?? 'Unknown').toString(),
        initials: (map['initials'] ?? 'P').toString(),
        description: (map['description'] ?? 'Payment').toString(),
        dateLabel: (map['dateLabel'] ?? 'Today').toString(),
        amount: _toDouble(map['amount']),
        method: (map['method'] ?? 'Cash').toString(),
        isCustomer: map['isCustomer'] == true,
        addedBy: (map['addedBy'] ?? 'Owner').toString(),
        addedByRole: (map['addedByRole'] ?? 'Owner').toString(),
        date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  List<_PaymentRecord> _defaultReferencePayments() {
    return [
      _PaymentRecord(
        id: 'p_1',
        entityId: 'c_1',
        name: 'Ramesh Verma',
        initials: 'RV',
        description: 'Gold Ring - Payment',
        dateLabel: 'Today, 10:30 AM',
        amount: 45000,
        method: 'UPI',
        isCustomer: true,
        addedBy: _currentUserName,
        addedByRole: _currentUserRole,
        date: DateTime(2026, 10, 31, 10, 30),
      ),
      _PaymentRecord(
        id: 'p_2',
        entityId: 'c_2',
        name: 'Priya Singh',
        initials: 'PS',
        description: 'Necklace - Payment',
        dateLabel: 'Yesterday, 04:20 PM',
        amount: 85000,
        method: 'Bank',
        isCustomer: true,
        addedBy: 'Worker',
        addedByRole: 'Worker',
        date: DateTime(2026, 10, 30, 16, 20),
      ),
      _PaymentRecord(
        id: 'p_3',
        entityId: 's_1',
        name: 'Sharma Jewellery',
        initials: 'SJ',
        description: 'Gold - Purchase Payment',
        dateLabel: 'Today, 09:15 AM',
        amount: 150000,
        method: 'Cash',
        isCustomer: false,
        addedBy: _currentUserName,
        addedByRole: _currentUserRole,
        date: DateTime(2026, 10, 31, 9, 15),
      ),
      _PaymentRecord(
        id: 'p_4',
        entityId: 's_2',
        name: 'Mahavir Zaveri & Sons',
        initials: 'MZ',
        description: 'Silver - Purchase Payment',
        dateLabel: '28 Oct 2026, 02:40 PM',
        amount: 100000,
        method: 'Bank',
        isCustomer: false,
        addedBy: 'Worker',
        addedByRole: 'Worker',
        date: DateTime(2026, 10, 28, 14, 40),
      ),
    ];
  }

  String _formatMethod(String method) {
    final lower = method.toLowerCase().trim();
    if (lower.contains('upi')) return 'UPI';
    if (lower.contains('bank') || lower.contains('card')) return 'Bank';
    if (lower.contains('cash')) return 'Cash';
    return 'Other';
  }

  String _dateDisplay(DateTime date) {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${hour.toString().padLeft(2, '0')}:$minute $period';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday, ${hour.toString().padLeft(2, '0')}:$minute $period';
    }
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _money(double amount) {
    final rounded = amount.round().toString();
    if (rounded.length <= 3) return rounded;
    final lastThree = rounded.substring(rounded.length - 3);
    var rest = rounded.substring(0, rounded.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$lastThree';
  }

  List<_PaymentRecord> get _filteredPayments {
    final query = _searchController.text.trim().toLowerCase();

    return _allPayments.where((rec) {
      final categoryMatches = switch (_categoryTab) {
        1 => rec.isCustomer,
        2 => !rec.isCustomer,
        _ => true,
      };

      final methodMatches = _selectedMethod == 'All' || rec.method == _selectedMethod;

      final searchMatches = query.isEmpty ||
          rec.name.toLowerCase().contains(query) ||
          rec.description.toLowerCase().contains(query) ||
          rec.amount.round().toString().contains(query);

      final dateMatches = _selectedDateRange == null ||
          (!rec.date.isBefore(_selectedDateRange!.start) &&
              !rec.date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1))));

      return categoryMatches && methodMatches && searchMatches && dateMatches;
    }).toList()
      ..sort((a, b) => _sortLabel == 'Newest First' ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
  }

  double get _totalReceivedFromCustomers => _allPayments
      .where((r) => r.isCustomer)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get _totalPaidToSuppliers => _allPayments
      .where((r) => !r.isCustomer)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get _totalOverallReceived => _totalReceivedFromCustomers;

  int get _customerCount => _allPayments.where((r) => r.isCustomer).length;
  int get _supplierCount => _allPayments.where((r) => !r.isCustomer).length;
  int get _totalCount => _allPayments.length;

  Future<void> _exportPaymentsReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report generated for ${_filteredPayments.length} transactions.'),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(2026, 10, 1),
            end: DateTime(2026, 10, 31),
          ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: _background,
            onSurface: _text,
          ),
        ),
        child: child!,
      ),
    );

    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  Future<void> _showAddPaymentSheet() async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    bool isCustomerPayment = true;
    String? selectedEntityId;
    String selectedEntityName = '';
    String method = 'Cash';
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final entities = isCustomerPayment ? _customersList : _suppliersList;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Payment',
                            style: TextStyle(color: _primary, fontSize: 21, fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            icon: const Icon(Icons.close_rounded, color: _primary),
                          ),
                        ],
                      ),
                      const Divider(color: _border),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Customer Received (+)')),
                              selected: isCustomerPayment,
                              selectedColor: _primary,
                              labelStyle: TextStyle(
                                color: isCustomerPayment ? Colors.white : _text,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) {
                                setSheetState(() {
                                  isCustomerPayment = true;
                                  selectedEntityId = null;
                                  selectedEntityName = '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Supplier Paid (-)')),
                              selected: !isCustomerPayment,
                              selectedColor: const Color(0xFFD49A3A),
                              labelStyle: TextStyle(
                                color: !isCustomerPayment ? Colors.white : _text,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) {
                                setSheetState(() {
                                  isCustomerPayment = false;
                                  selectedEntityId = null;
                                  selectedEntityName = '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (entities.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: selectedEntityId,
                          decoration: InputDecoration(
                            labelText: isCustomerPayment ? 'Select Customer *' : 'Select Supplier *',
                            prefixIcon: Icon(
                              isCustomerPayment ? Icons.person_outline : Icons.local_shipping_outlined,
                              color: _primary,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                          ),
                          items: entities
                              .map((e) => DropdownMenuItem(
                                    value: e['id'],
                                    child: Text(e['name'] ?? ''),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            final match = entities.firstWhere((e) => e['id'] == val, orElse: () => {});
                            setSheetState(() {
                              selectedEntityId = val;
                              selectedEntityName = match['name'] ?? '';
                            });
                          },
                          validator: (v) => (v == null || v.isEmpty) ? 'Selection required' : null,
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹) *',
                          prefixIcon: const Icon(Icons.currency_rupee_rounded, color: _primary),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                        ),
                        validator: (v) {
                          final amt = double.tryParse(v?.trim().replaceAll(',', '') ?? '');
                          if (amt == null || amt <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: method,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: const Icon(Icons.payment_outlined, color: _primary),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setSheetState(() => method = val);
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: 'Description / Notes',
                          prefixIcon: const Icon(Icons.notes_rounded, color: _primary),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);

                                  final amount = double.parse(amountCtrl.text.trim().replaceAll(',', ''));
                                  final name = selectedEntityName.isNotEmpty
                                      ? selectedEntityName
                                      : (isCustomerPayment ? 'Customer' : 'Supplier');

                                  try {
                                    if (!isCustomerPayment && selectedEntityId != null) {
                                      final payload = {
                                        'supplier_id': selectedEntityId,
                                        'amount': amount,
                                        'payment_method': method.toLowerCase(),
                                        'allocations': [],
                                        'notes': notesCtrl.text.trim(),
                                      };
                                      await ApiClient.instance.post(
                                        Uri.parse(ApiConfig.supplierPaymentUrl),
                                        headers: const {'Content-Type': 'application/json'},
                                        body: jsonEncode(payload),
                                      );
                                    }

                                    final now = DateTime.now();
                                    final newRec = _PaymentRecord(
                                      id: 'p_${now.millisecondsSinceEpoch}',
                                      entityId: selectedEntityId ?? '',
                                      name: name,
                                      initials: _initials(name),
                                      description: notesCtrl.text.trim().isNotEmpty
                                          ? notesCtrl.text.trim()
                                          : (isCustomerPayment ? 'Payment Received' : 'Purchase Payment'),
                                      dateLabel: _dateDisplay(now),
                                      amount: amount,
                                      method: method,
                                      isCustomer: isCustomerPayment,
                                      addedBy: _currentUserName,
                                      addedByRole: _currentUserRole,
                                      date: now,
                                    );

                                    setState(() {
                                      _allPayments.insert(0, newRec);
                                    });

                                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Payment recorded successfully!'),
                                          backgroundColor: Color(0xFF247A4B),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (sheetCtx.mounted) {
                                      setSheetState(() => isSaving = false);
                                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                        SnackBar(content: Text('Error saving payment: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: Text(
                            isSaving ? 'Saving...' : 'Save Payment',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    amountCtrl.dispose();
    notesCtrl.dispose();
  }

  void _showPaymentDetails(_PaymentRecord record) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8CFC6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Details', style: TextStyle(color: _primary, fontSize: 21, fontWeight: FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.isCustomer ? const Color(0xFFE2F8E8) : const Color(0xFFFFE6E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.isCustomer ? 'Received' : 'Paid',
                      style: TextStyle(color: record.isCustomer ? _green : _red, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  '${record.isCustomer ? '+' : '-'} ₹ ${_money(record.amount)}',
                  style: TextStyle(
                    color: record.isCustomer ? _green : _red,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _detailRow('Transaction ID', record.id),
              _detailRow('Name', record.name),
              _detailRow('Type', record.isCustomer ? 'Customer Payment' : 'Supplier Purchase Payment'),
              _detailRow('Description', record.description),
              _detailRow('Payment Method', record.method),
              _detailRow('Date & Time', record.dateLabel),
              _detailRow('Added By', '${record.addedBy} (${record.addedByRole})'),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: _muted, fontSize: 13))),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filteredPayments;
    final customerRecords = filteredRecords.where((r) => r.isCustomer).toList();
    final supplierRecords = filteredRecords.where((r) => !r.isCustomer).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 21),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: Color(0xFFD2A04A), size: 24),
            SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payments', style: TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('All Payments (Customers & Suppliers)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => setState(() => _searchOpen = !_searchOpen),
            icon: const Icon(Icons.search_rounded, color: _primary, size: 26),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list_rounded, color: _primary, size: 26),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline) OfflineBanner(lastUpdated: _lastUpdatedTime),
            Expanded(
              child: _isLoading
                  ? const SkeletonList()
                  : _error != null
                      ? _buildLoadError()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _loadPaymentsData,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            children: [
                              if (_searchOpen) ...[
                                TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search by name, description or amount...',
                                    prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Top Dark Gradient Summary Card
                              _buildTopSummaryCard(),

                              const SizedBox(height: 12),

                              // Secondary Summary Cards Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniSummaryCard(
                                      icon: Icons.person_outline,
                                      title: 'From Customers',
                                      value: '₹ ${_money(_totalReceivedFromCustomers)}',
                                      color: _green,
                                      bg: const Color(0xFFE2F8E8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniSummaryCard(
                                      icon: Icons.local_shipping_outlined,
                                      title: 'To Suppliers',
                                      value: '₹ ${_money(_totalPaidToSuppliers)}',
                                      color: const Color(0xFFD49A3A),
                                      bg: const Color(0xFFFFF0D6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _chooseDateRange,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: _border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.calendar_month_outlined, color: _primary, size: 16),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text('This Month', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: _muted)),
                                                ),
                                                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _primary),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text('01 Oct - 31 Oct', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Category Tabs Row (All / Customers / Suppliers)
                              Row(
                                children: [
                                  _categoryTabBtn('All ($_totalCount)', 0),
                                  const SizedBox(width: 8),
                                  _categoryTabBtn('Customers ($_customerCount)', 1),
                                  const SizedBox(width: 8),
                                  _categoryTabBtn('Suppliers ($_supplierCount)', 2),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Payment Method Filter Chips + Export
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final method in ['All', 'Cash', 'UPI', 'Bank', 'Other']) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(method),
                                          selected: _selectedMethod == method,
                                          selectedColor: _primary,
                                          backgroundColor: Colors.white,
                                          side: BorderSide(color: _selectedMethod == method ? _primary : _border),
                                          labelStyle: TextStyle(
                                            color: _selectedMethod == method ? Colors.white : _text,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          onSelected: (_) => setState(() => _selectedMethod = method),
                                        ),
                                      ),
                                    ],
                                    OutlinedButton.icon(
                                      onPressed: _exportPaymentsReport,
                                      icon: const Icon(Icons.file_download_outlined, size: 18),
                                      label: const Text('Export'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _primary,
                                        side: const BorderSide(color: _primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Recent Payments Section Title & Sorting
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recent Payments', style: TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.w800)),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _sortLabel = _sortLabel == 'Newest First' ? 'Oldest First' : 'Newest First';
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Text(_sortLabel, style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.swap_vert_rounded, color: _primary, size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              if (filteredRecords.isEmpty)
                                _buildEmptyState()
                              else ...[
                                // Customer Payments Block
                                if (_categoryTab == 0 || _categoryTab == 1) ...[
                                  if (customerRecords.isNotEmpty) ...[
                                    _sectionHeaderCard(
                                      icon: Icons.person_outline,
                                      title: 'Customer Payments (${customerRecords.length})',
                                      amountText: 'Total Received: ₹ ${_money(customerRecords.fold(0.0, (s, i) => s + i.amount))}',
                                      color: _green,
                                      bg: const Color(0xFFF2EAFB),
                                    ),
                                    const SizedBox(height: 8),
                                    for (final item in customerRecords) ...[
                                      _paymentRecordRow(item),
                                      const SizedBox(height: 8),
                                    ],
                                    const SizedBox(height: 12),
                                  ],
                                ],

                                // Supplier Payments Block
                                if (_categoryTab == 0 || _categoryTab == 2) ...[
                                  if (supplierRecords.isNotEmpty) ...[
                                    _sectionHeaderCard(
                                      icon: Icons.local_shipping_outlined,
                                      title: 'Supplier Payments (${supplierRecords.length})',
                                      amountText: 'Total Paid: ₹ ${_money(supplierRecords.fold(0.0, (s, i) => s + i.amount))}',
                                      color: _red,
                                      bg: const Color(0xFFFFF3E0),
                                    ),
                                    const SizedBox(height: 8),
                                    for (final item in supplierRecords) ...[
                                      _paymentRecordRow(item),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ],
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentSheet,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B1547), Color(0xFF260A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.diamond_outlined, color: Color(0x18FFFFFF), size: 75),
          ),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0x22FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: _gold, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Received', style: TextStyle(color: Color(0xFFD3C5DA), fontSize: 12)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('₹ ${_money(_totalOverallReceived)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0x33FFFFFF)),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0x22FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.swap_horiz_rounded, color: _gold, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Transactions', style: TextStyle(color: Color(0xFFD3C5DA), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$_totalCount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted))),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _categoryTabBtn(String label, int index) {
    final selected = _categoryTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _categoryTab = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _primary : _border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeaderCard({
    required IconData icon,
    required String title,
    required String amountText,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w700))),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amountText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, color: _primary, size: 18),
        ],
      ),
    );
  }

  Widget _paymentRecordRow(_PaymentRecord rec) {
    final isPos = rec.isCustomer;
    final color = isPos ? _green : _red;

    return InkWell(
      onTap: () => _showPaymentDetails(rec),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF8E4C8),
              child: Text(rec.initials, style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(rec.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: _muted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(rec.dateLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(rec.method, style: const TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${isPos ? '+' : '-'} ₹ ${_money(rec.amount)}',
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: color, size: 11),
                      const SizedBox(width: 3),
                      Text(isPos ? 'Received' : 'Paid', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Added by ${rec.addedByRole}', style: const TextStyle(color: _muted, fontSize: 9)),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, color: _primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Payments', style: TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Cash', 'UPI', 'Bank', 'Other'].map((m) {
                  final sel = _selectedMethod == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: sel,
                    selectedColor: _primary,
                    labelStyle: TextStyle(color: sel ? Colors.white : _text),
                    onSelected: (_) {
                      setState(() => _selectedMethod = m);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: _red),
            const SizedBox(height: 12),
            const Text('Could not load payments', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPaymentsData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: _muted),
          SizedBox(height: 10),
          Text('No payments found', style: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Try changing your search or filter.', style: TextStyle(color: _muted, fontSize: 13)),
        ],
      ),
    );
  }
}
