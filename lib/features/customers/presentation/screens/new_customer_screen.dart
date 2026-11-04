import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../config/app_config.dart';
import '../../../../services/api_client.dart';

/// Add New Entry screen with support for multiple jewellery items.
/// Replace lib/features/customers/presentation/screens/new_customer_screen.dart.
class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({super.key, this.isSupplier = false});
  final bool isSupplier;

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _JewelleryItem {
  _JewelleryItem({
    String name = '',
    String weight = '',
    String rate = '',
    String paid = '0',
  })  : name = TextEditingController(text: name),
        weight = TextEditingController(text: weight),
        rate = TextEditingController(text: rate),
        totalController = TextEditingController(text: '0'),
        paidController = TextEditingController(text: paid) {
    this.weight.addListener(_onWeightOrRateChanged);
    this.rate.addListener(_onWeightOrRateChanged);
    totalController.addListener(_onTotalEdited);
    paidController.addListener(() => onChanged?.call());
    _updateCalculatedTotal();
  }
  final TextEditingController name;
  final TextEditingController weight;
  final TextEditingController rate;
  final TextEditingController totalController;
  final TextEditingController paidController;
  VoidCallback? onChanged;
  bool isAutoTotal = true;
  bool _updatingTotal = false;

  double get calculatedTotal =>
      (double.tryParse(weight.text.trim().replaceAll(',', '')) ?? 0) *
          (double.tryParse(rate.text.trim().replaceAll(',', '')) ?? 0);
  double get total => double.tryParse(totalController.text.trim().replaceAll(',', '')) ?? 0;
  double get paid => double.tryParse(paidController.text.trim().replaceAll(',', '')) ?? 0;
  double get balance => (total - paid).clamp(0, double.infinity).toDouble();

  void _onWeightOrRateChanged() {
    if (isAutoTotal) _updateCalculatedTotal();
    onChanged?.call();
  }
  void _updateCalculatedTotal() {
    _updatingTotal = true;
    totalController.text = calculatedTotal.toStringAsFixed(0);
    _updatingTotal = false;
  }
  void _onTotalEdited() {
    if (!_updatingTotal) isAutoTotal = false;
    onChanged?.call();
  }
  void recalculate() {
    isAutoTotal = true;
    _updateCalculatedTotal();
    onChanged?.call();
  }
  void dispose() {
    name.dispose();
    weight.dispose();
    rate.dispose();
    totalController.dispose();
    paidController.dispose();
  }
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  static const Color _purple = Color(0xFF35113F);
  static const Color _gold = Color(0xFFD2A04A);
  static const Color _cream = Color(0xFFFFFAF2);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _text = Color(0xFF292333);
  static const Color _muted = Color(0xFF8A858B);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _overallPaidController = TextEditingController(text: '0');
  final List<_JewelleryItem> _items = [];
  bool _payPerItem = true;
  DateTime? _reminderDate;
  bool _sendSmsReminder = false;
  String _language = 'English';

  // Backend expects E.164 format, e.g. +919876543210.
  String _normalizePhoneNumber(String input) {
    var phone = input.trim().replaceAll(RegExp(r'[\s()\-]'), '');
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      phone = '+91$phone';
    } else if (RegExp(r'^91[6-9]\d{9}$').hasMatch(phone)) {
      phone = '+$phone';
    }
    return phone;
  }

  bool _isValidE164(String phone) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone);

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.total);
  double get _overallPaid =>
      double.tryParse(_overallPaidController.text.trim().replaceAll(',', '')) ?? 0;
  double get _amountPaid => _payPerItem
      ? _items.fold(0, (sum, item) => sum + item.paid)
      : _overallPaid;
  double get _balance =>
      (_totalAmount - _amountPaid).clamp(0, double.infinity).toDouble();
  String _money(double amount) => amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  @override
  void initState() {
    super.initState();
    _items.add(_newItem());
    _overallPaidController.addListener(_refresh);
  }

  _JewelleryItem _newItem() {
    final item = _JewelleryItem();
    item.onChanged = _refresh;
    return item;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _addItem() => setState(() => _items.add(_newItem()));

  void _removeItem(int index) {
    if (_items.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required.')),
      );
      return;
    }
    setState(() => _items.removeAt(index).dispose());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _overallPaidController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select reminder date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple, onPrimary: Colors.white,
            surface: _cream, onSurface: _text,
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) setState(() => _reminderDate = selected);
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_payPerItem) {
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.paid < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enter a valid amount paid for item ${i + 1}.')),
          );
          return;
        }
        if (item.paid > item.total) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Amount paid for item ${i + 1} cannot exceed its total amount.',
              ),
            ),
          );
          return;
        }
      }
    } else {
      if (_overallPaid < 0 || _overallPaid > _totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total amount paid must be between ₹0 and the total amount.'),
          ),
        );
        return;
      }
    }

    if (_sendSmsReminder && _reminderDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a reminder date or turn off SMS reminder.',
          ),
        ),
      );
      return;
    }

    // This endpoint is confirmed for customers only. Do not send supplier
    // records to the customer endpoint.
    if (widget.isSupplier) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supplier API endpoint is not configured yet. No data was saved.',
          ),
        ),
      );
      return;
    }

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login session missing. Please log in again.'),
        ),
      );
      return;
    }

    final reminderDate = _reminderDate == null
        ? null
        : '${_reminderDate!.year.toString().padLeft(4, '0')}-'
        '${_reminderDate!.month.toString().padLeft(2, '0')}-'
        '${_reminderDate!.day.toString().padLeft(2, '0')}';

    var remainingPaymentToAllocate = _payPerItem ? 0.0 : _overallPaid;
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone_number': _normalizePhoneNumber(_phoneController.text),
      'address': _addressController.text.trim(),
      'items': _items.map((item) {
        // The backend stores amount_paid on each item. In total-payment mode,
        // allocate the entered payment across items in their displayed order.
        final itemPaid = _payPerItem
            ? item.paid
            : (() {
          final allocation = remainingPaymentToAllocate
              .clamp(0, item.total)
              .toDouble();
          remainingPaymentToAllocate -= allocation;
          return allocation;
        })();
        return <String, dynamic>{
          'item_name': item.name.text.trim(),
          'weight_grams': double.parse(
            item.weight.text.trim().replaceAll(',', ''),
          ),
          'rate_per_gram': double.parse(
            item.rate.text.trim().replaceAll(',', ''),
          ),
          'total_amount': item.total,
          'amount_paid': itemPaid,
          'reminder_date': reminderDate,
          'sms_reminder_enabled': _sendSmsReminder,
        };
      }).toList(),
    };

    setState(() => _isSaving = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/add-customer');
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer saved successfully.'),
            backgroundColor: Color(0xFF247A4B),
          ),
        );
        Navigator.of(context).maybePop(true);
        return;
      }

      final serverMessage = responseData is Map
          ? (responseData['detail'] ??
          responseData['message'] ??
          responseData['error'])
          ?.toString()
          : null;

      String message;
      if (response.statusCode == 401) {
        message = 'Login session expired. Please log in again.';
      } else if (response.statusCode == 422) {
        message = serverMessage ?? 'Some customer or item fields are invalid.';
      } else {
        message = serverMessage ??
            'Could not save customer (HTTP ${response.statusCode}).';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Check internet and try again.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to the server. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = !widget.isSupplier;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _purple),
        ),
        title: const Text('Add New Entry',
            style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              initialValue: _language,
              onSelected: (value) => setState(() => _language = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'English', child: Text('English')),
                PopupMenuItem(value: 'हिन्दी', child: Text('हिन्दी')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  const Icon(Icons.language_rounded, size: 18, color: _purple),
                  const SizedBox(width: 6),
                  Text(_language, style: const TextStyle(fontSize: 12, color: _text)),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _text),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _sectionTitle(isCustomer ? 'Customer Details' : 'Supplier Details'),
              const SizedBox(height: 8),
              _groupCard([
                _inputRow(icon: Icons.person_rounded, label: 'Full Name *',
                    hint: isCustomer ? 'Enter customer name' : 'Enter supplier name',
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                _inputRow(icon: Icons.call_rounded, label: 'Phone Number *',
                    hint: 'Enter phone number', controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!_isValidE164(_normalizePhoneNumber(v))) {
                        return 'Enter a valid number with country code, e.g. +919876543210';
                      }
                      return null;
                    }),
                _inputRow(icon: Icons.location_on_rounded, label: 'Address',
                    hint: 'Enter address (optional)', controller: _addressController, requiredField: false),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Items (${_items.length})'),
              const SizedBox(height: 3),
              const Text('Add multiple items to one customer entry.',
                  style: TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 10),
              ...List.generate(_items.length, (index) => _itemCard(_items[index], index)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Add Another Item', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFF7B4B8B)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Order Summary'),
              const SizedBox(height: 8),
              _groupCard([
                ...List.generate(_items.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text(
                      'Item ${i + 1}${_items[i].name.text.trim().isEmpty ? '' : ' (${_items[i].name.text.trim()})'}',
                      style: const TextStyle(fontSize: 12, color: _text),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    Text('₹ ${_money(_items[i].total)}',
                        style: const TextStyle(fontSize: 12, color: _text, fontWeight: FontWeight.w600)),
                  ]),
                )),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFFBF0DD), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    _iconCircle(Icons.currency_rupee_rounded),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Total Amount (₹)', style: TextStyle(fontSize: 12, color: _text))),
                    Text(_money(_totalAmount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _purple)),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Payment Method'),
              const SizedBox(height: 8),
              _groupCard([
                RadioListTile<bool>(
                  value: true,
                  groupValue: _payPerItem,
                  activeColor: _purple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  title: const Text(
                    'Pay amount item-wise',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text),
                  ),
                  subtitle: const Text(
                    'Enter payment separately for each item.',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _payPerItem = value!),
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: _payPerItem,
                  activeColor: _purple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  title: const Text(
                    'Add one total payment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text),
                  ),
                  subtitle: const Text(
                    'Enter the total amount received for all items together.',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _payPerItem = value!),
                ),
                if (!_payPerItem)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: TextFormField(
                      controller: _overallPaidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _fieldDecoration('Total amount received (₹)'),
                      style: const TextStyle(fontSize: 14, color: _text),
                      validator: (value) {
                        if (_payPerItem || value == null || value.trim().isEmpty) return null;
                        final amount = double.tryParse(value.trim().replaceAll(',', ''));
                        if (amount == null || amount < 0) return 'Enter a valid amount';
                        if (amount > _totalAmount) return 'Cannot exceed total amount';
                        return null;
                      },
                    ),
                  ),
              ]),
              if (!_payPerItem) ...[
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'For saving, this payment is allocated to items in the order shown above because the backend stores payment per item.',
                    style: TextStyle(fontSize: 11, color: _muted, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _sectionTitle('Payment Summary'),
              const SizedBox(height: 8),
              _groupCard([
                _summaryRow('Total Amount', _totalAmount, isEmphasized: true),
                const Divider(height: 1, color: _border),
                _summaryRow('Total Paid', _amountPaid, valueColor: const Color(0xFF22864B)),
                const Divider(height: 1, color: _border),
                _summaryRow('Remaining Balance', _balance, valueColor: const Color(0xFFD84343)),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Reminder (Optional)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(15), border: Border.all(color: _border)),
                child: Column(children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10), onTap: _pickReminderDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        _iconCircle(Icons.calendar_month_rounded),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Reminder Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                          const SizedBox(height: 4),
                          Text(_reminderDate == null ? 'Select reminder date (optional)' :
                          '${_reminderDate!.day.toString().padLeft(2, '0')}/${_reminderDate!.month.toString().padLeft(2, '0')}/${_reminderDate!.year}',
                              style: const TextStyle(fontSize: 12, color: _muted)),
                        ])),
                        const Icon(Icons.calendar_today_outlined, color: _purple, size: 19),
                      ]),
                    ),
                  ),
                  const Divider(height: 20, color: _border),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero, value: _sendSmsReminder,
                    activeTrackColor: _purple,
                    onChanged: (value) => setState(() => _sendSmsReminder = value),
                    title: const Text('Send reminder by SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                    subtitle: Text(_sendSmsReminder ? 'SMS reminder enabled' : 'SMS reminder disabled',
                        style: const TextStyle(fontSize: 11, color: _muted)),
                    secondary: _iconCircle(Icons.sms_outlined),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF4EFFB), borderRadius: BorderRadius.circular(14)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, color: Colors.deepPurple),
                  SizedBox(width: 10),
                  Expanded(child: Text('Total amount and balance are calculated automatically from all added items.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: _purple))),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEntry,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save_rounded, size: 19),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save ${isCustomer ? 'Customer Entry' : 'Supplier Entry'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemCard(_JewelleryItem item, int index) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(15), border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 25, height: 25, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF4D18A), shape: BoxShape.circle),
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _text))),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => _removeItem(index),
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 21),
          tooltip: 'Remove item',
        ),
      ]),
      _inputRow(
        icon: Icons.diamond_outlined, label: 'Item Name *',
        hint: 'e.g. Gold Ring, Necklace', controller: item.name,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 4, 10),
        child: Row(children: [
          Expanded(child: _compactNumberField(label: 'Weight (Grams) *',
              hint: 'e.g. 12.5', controller: item.weight,
              validator: (v) => _positiveNumberValidator(v, 'Weight'))),
          const SizedBox(width: 10),
          Expanded(child: _compactNumberField(label: 'Rate per Gram (₹) *',
              hint: 'e.g. 6,200', controller: item.rate,
              validator: (v) => _positiveNumberValidator(v, 'Rate'))),
        ]),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFFFBF0DD), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _iconCircle(Icons.currency_rupee_rounded),
          const SizedBox(width: 10),
          const Expanded(child: Text('Item Total (₹)', style: TextStyle(fontSize: 12, color: _text))),
          SizedBox(
            width: 125,
            child: TextFormField(
              controller: item.totalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _purple, width: 1.3)),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _purple),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                final amount = double.tryParse(value.trim().replaceAll(',', ''));
                if (amount == null || amount < 0) return 'Invalid';
                return null;
              },
            ),
          ),
        ]),
      ),
      if (_payPerItem) ...[
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _compactNumberField(
              label: 'Amount Paid (₹)',
              hint: 'Enter paid amount',
              controller: item.paidController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final amount = double.tryParse(value.trim().replaceAll(',', ''));
                if (amount == null || amount < 0) return 'Invalid amount';
                if (amount > item.total) return 'Cannot exceed item total';
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE7E4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Item Balance (₹)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text),
                ),
                const SizedBox(height: 9),
                Text(
                  '₹ ${_money(item.balance)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFD84343)),
                ),
              ]),
            ),
          ),
        ]),
      ],
    ]),
  );

  Widget _summaryRow(String label, double amount, {Color? valueColor, bool isEmphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isEmphasized ? 13 : 12,
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
                color: _text,
              ),
            ),
          ),
          Text(
            '₹ ${_money(amount)}',
            style: TextStyle(
              fontSize: isEmphasized ? 18 : 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? _purple,
            ),
          ),
        ]),
      );

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text));

  Widget _groupCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(15), border: Border.all(color: _border)),
    child: Column(children: children),
  );

  Widget _inputRow({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool requiredField = true,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(9, 7, 9, 2),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _iconCircle(icon),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
        TextFormField(
          controller: controller, keyboardType: keyboardType,
          validator: requiredField ? validator : null,
          onChanged: (_) => _refresh(),
          decoration: _fieldDecoration(hint),
          style: const TextStyle(fontSize: 12, color: _text),
        ),
      ])),
    ]),
  );

  Widget _compactNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
    TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: _fieldDecoration(hint),
      style: const TextStyle(fontSize: 12, color: _text),
    ),
  ]);

  String? _positiveNumberValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final number = double.tryParse(value.trim().replaceAll(',', ''));
    if (number == null || number <= 0) return 'Enter valid $label';
    return null;
  }

  Widget _iconCircle(IconData icon) => Container(
    width: 37, height: 37,
    decoration: const BoxDecoration(color: Color(0xFFF7EFE4), shape: BoxShape.circle),
    child: Icon(icon, size: 18, color: const Color(0xFF77716B)),
  );

  Widget _paymentCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: _border), borderRadius: BorderRadius.circular(13)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor)),
      const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
        child,
      ])),
    ]),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 11, color: _muted),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    border: const UnderlineInputBorder(borderSide: BorderSide(color: _border)),
    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _border)),
    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _purple, width: 1.2)),
    errorStyle: const TextStyle(fontSize: 10),
  );
}
