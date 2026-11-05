import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../../config/app_config.dart';
import '../../../../services/api_client.dart';
import '../../../shop_settings/presentation/screens/shop_settings_screen.dart';

/// Add New Entry / Add New Item screen with support for multiple jewellery items,
/// existing customer item additions with receiver notes, and PDF bill downloads.
class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({
    super.key,
    this.isSupplier = false,
    this.existingCustomerName,
    this.existingCustomerPhone,
    this.existingCustomerAddress,
  });

  final bool isSupplier;
  final String? existingCustomerName;
  final String? existingCustomerPhone;
  final String? existingCustomerAddress;

  bool get isExistingCustomer =>
      existingCustomerName != null && existingCustomerName!.trim().isNotEmpty;

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
  bool _isDownloadingPdf = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _receiverController = TextEditingController();
  final _overallPaidController = TextEditingController(text: '0');
  final List<_JewelleryItem> _items = [];
  bool _payPerItem = true;
  DateTime? _reminderDate;
  bool _sendSmsReminder = false;
  String _language = 'English';

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
    if (widget.isExistingCustomer) {
      _nameController.text = widget.existingCustomerName!;
      _phoneController.text = widget.existingCustomerPhone ?? '';
      _addressController.text = widget.existingCustomerAddress ?? '';
    }
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

  void _addItem() {
    setState(() => _items.add(_newItem()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
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
    _receiverController.dispose();
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

  Future<void> _downloadAndSaveReceiptPdf(String? txId) async {
    if (txId == null || txId.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer saved! No PDF bill generated as no transaction ID was created for this payment.'),
          backgroundColor: Color(0xFF247A4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop(true);
      return;
    }

    try {
      final receiptUri = Uri.parse('${ApiConfig.baseUrl}/transactions/$txId/receipt');
      final response = await ApiClient.instance.get(
        receiptUri,
        headers: const {'Accept': 'application/pdf'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final pdfBytes = response.bodyBytes;
        if (pdfBytes.isNotEmpty) {
          final filePath = await _savePdfToDevice(pdfBytes, txId);
          final savedFile = File(filePath);

          if (savedFile.existsSync() && savedFile.lengthSync() > 0) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Customer saved & PDF bill downloaded to $filePath!'),
                backgroundColor: const Color(0xFF247A4B),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  onPressed: () {
                    _openPdfFile(filePath);
                  },
                ),
              ),
            );
            Navigator.of(context).maybePop(true);
            return;
          }
        }
      }

      dynamic errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (_) {}

      String errorMsg = 'Failed to download PDF bill (HTTP ${response.statusCode}).';
      List<String> missingFields = [];

      if (response.statusCode == 409) {
        if (errorData is Map && errorData['detail'] is Map) {
          final detailMap = Map<String, dynamic>.from(errorData['detail'] as Map);
          if (detailMap['missing_fields'] is List) {
            missingFields = (detailMap['missing_fields'] as List).map((e) => e.toString()).toList();
          }
        }

        if (missingFields.isEmpty) {
          try {
            final compRes = await ApiClient.instance.get(
              Uri.parse('${ApiConfig.baseUrl}/shop-profile/completion'),
            );
            if (compRes.statusCode >= 200 && compRes.statusCode < 300) {
              final compData = jsonDecode(compRes.body);
              if (compData is Map && compData['missing_fields'] is List) {
                missingFields = (compData['missing_fields'] as List).map((e) => e.toString()).toList();
              }
            }
          } catch (_) {}
        }

        final fieldText = missingFields.isNotEmpty
            ? missingFields.join(', ')
            : 'shop name, address, or phone number';

        errorMsg = 'Customer entry saved! Bill not generated: Shop profile is incomplete (Missing: $fieldText).';

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFB42318),
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'SHOP SETTINGS',
              textColor: Colors.amber,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShopSettingsScreen(),
                  ),
                );
                if (mounted) {
                  _downloadAndSaveReceiptPdf(txId);
                }
              },
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'RETRY PDF',
            textColor: Colors.amber,
            onPressed: () => _downloadAndSaveReceiptPdf(txId),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer entry saved! PDF download error: $e'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'RETRY PDF',
            textColor: Colors.amber,
            onPressed: () => _downloadAndSaveReceiptPdf(txId),
          ),
        ),
      );
    }
  }

  Future<String> _savePdfToDevice(List<int> bytes, String txId) async {
    Directory? targetDir;
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          final externalDir = Directory('/sdcard/Download');
          if (await externalDir.exists()) {
            targetDir = externalDir;
          } else {
            targetDir = Directory.systemTemp;
          }
        }
      } else {
        targetDir = Directory.systemTemp;
      }
    } catch (_) {
      targetDir = Directory.systemTemp;
    }

    final filename = 'JewelSetu_Bill_${txId.length > 8 ? txId.substring(0, 8) : txId}.pdf';
    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    if (!file.existsSync() || file.lengthSync() == 0) {
      throw Exception('PDF file creation failed or file is empty.');
    }

    return file.path;
  }

  Future<void> _openPdfFile(String filePath) async {
    try {
      final uri = Uri.file(filePath);
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _saveEntry({bool downloadPdf = false}) async {
    if (_isSaving || _isDownloadingPdf) return;
    if (!_formKey.currentState!.validate()) return;

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

    final reminderDate = _reminderDate == null
        ? null
        : '${_reminderDate!.year.toString().padLeft(4, '0')}-'
        '${_reminderDate!.month.toString().padLeft(2, '0')}-'
        '${_reminderDate!.day.toString().padLeft(2, '0')}';

    final paymentMode = _payPerItem ? 'item_wise' : 'total';
    const paymentMethod = 'cash';

    // Existing Customer Handler
    if (widget.isExistingCustomer) {
      final existingPayload = <String, dynamic>{
        'phone_number': _normalizePhoneNumber(_phoneController.text),
        if (_receiverController.text.trim().isNotEmpty)
          'receiver': _receiverController.text.trim(),
        'payment_mode': paymentMode,
        'payment_method': paymentMethod,
        if (!_payPerItem) 'total_payment': _overallPaid,
        'items': _items.map((item) {
          final rateText = item.rate.text.trim().replaceAll(',', '');
          final weightText = item.weight.text.trim().replaceAll(',', '');
          return <String, dynamic>{
            'item_name': item.name.text.trim(),
            'weight_grams': double.parse(weightText),
            'rate_per_gram': rateText.isNotEmpty ? double.tryParse(rateText) : null,
            'total_amount': item.total,
            if (_payPerItem) 'amount_paid': item.paid,
            'reminder_date': reminderDate,
            'sms_reminder_enabled': _sendSmsReminder,
          };
        }).toList(),
      };

      setState(() => _isSaving = true);
      try {
        final uri = Uri.parse(ApiConfig.existingCustomerUrl);
        final response = await ApiClient.instance.post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(existingPayload),
        );

        dynamic responseData;
        try {
          responseData = jsonDecode(response.body);
        } on FormatException {
          responseData = null;
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final txId = responseData is Map ? responseData['transaction_id']?.toString() : null;

          if (downloadPdf) {
            setState(() {
              _isSaving = false;
              _isDownloadingPdf = true;
            });
            await _downloadAndSaveReceiptPdf(txId);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item added for customer successfully.'),
                backgroundColor: Color(0xFF247A4B),
              ),
            );
            Navigator.of(context).maybePop(true);
          }
          return;
        }

        final serverMessage = responseData is Map
            ? (responseData['detail'] ?? responseData['message'] ?? responseData['error'])?.toString()
            : null;

        String message;
        if (response.statusCode == 401) {
          message = 'Login session expired. Please log in again.';
        } else if (response.statusCode == 422) {
          message = 'Some item fields are invalid.';
        } else {
          message = serverMessage ?? 'Could not add item for customer (HTTP ${response.statusCode}).';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _isDownloadingPdf = false;
          });
        }
      }
      return;
    }

    if (widget.isSupplier) {
      final supplierPayload = <String, dynamic>{
        'supplier_name': _nameController.text.trim(),
        'phone_number': _normalizePhoneNumber(_phoneController.text),
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'payment_mode': paymentMode,
        'payment_method': paymentMethod,
        if (!_payPerItem) 'total_payment': _overallPaid,
        'notes': null,
        'items': _items.map((item) {
          final rateText = item.rate.text.trim().replaceAll(',', '');
          final weightText = item.weight.text.trim().replaceAll(',', '');
          return <String, dynamic>{
            'item_name': item.name.text.trim(),
            'weight_grams':
                weightText.isNotEmpty ? double.tryParse(weightText) : null,
            'rate_per_gram':
                rateText.isNotEmpty ? double.tryParse(rateText) : null,
            'total_amount': item.total,
            if (_payPerItem) 'amount_paid': item.paid,
          };
        }).toList(),
      };

      setState(() => _isSaving = true);
      try {
        var response = await ApiClient.instance.post(
          Uri.parse('${ApiConfig.baseUrl}/api/suppliers'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(supplierPayload),
        );

        if (response.statusCode == 404 || response.statusCode == 405) {
          response = await ApiClient.instance.post(
            Uri.parse(ApiConfig.suppliersUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(supplierPayload),
          );
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplier saved successfully.'),
              backgroundColor: Color(0xFF247A4B),
            ),
          );
          Navigator.of(context).maybePop(true);
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save supplier (HTTP ${response.statusCode}).')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving supplier: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
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

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone_number': _normalizePhoneNumber(_phoneController.text),
      'address': _addressController.text.trim(),
      'payment_mode': paymentMode,
      'payment_method': paymentMethod,
      if (!_payPerItem) 'total_payment': _overallPaid,
      'items': _items.map((item) {
        return <String, dynamic>{
          'item_name': item.name.text.trim(),
          'weight_grams': double.parse(
            item.weight.text.trim().replaceAll(',', ''),
          ),
          'rate_per_gram': item.rate.text.trim().isNotEmpty
              ? double.tryParse(item.rate.text.trim().replaceAll(',', ''))
              : null,
          'total_amount': item.total,
          if (_payPerItem) 'amount_paid': item.paid,
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
        final txId = responseData is Map ? responseData['transaction_id']?.toString() : null;

        if (downloadPdf) {
          setState(() {
            _isSaving = false;
            _isDownloadingPdf = true;
          });
          await _downloadAndSaveReceiptPdf(txId);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer saved successfully.'),
              backgroundColor: Color(0xFF247A4B),
            ),
          );
          Navigator.of(context).maybePop(true);
        }
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
      } else if (response.statusCode == 409) {
        message = 'Shop profile is incomplete. Please complete shop details in Shop Settings.';
      } else {
        message = serverMessage ??
            'Could not save customer (HTTP ${response.statusCode}).';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving customer: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isDownloadingPdf = false;
        });
      }
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
        title: Text(
          widget.isExistingCustomer
              ? 'Add New Item'
              : (isCustomer ? 'Add New Customer' : 'Add New Supplier'),
          style: const TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700),
        ),
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
              _sectionTitle(
                widget.isExistingCustomer
                    ? 'Customer Details (Read Only)'
                    : (isCustomer ? 'Customer Details' : 'Supplier Details'),
              ),
              const SizedBox(height: 8),
              _groupCard([
                _inputRow(
                  icon: Icons.person_rounded,
                  label: isCustomer ? 'Full Name *' : 'Supplier Name *',
                  hint: isCustomer ? 'Enter customer name' : 'Enter supplier name',
                  controller: _nameController,
                  readOnly: widget.isExistingCustomer,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                _inputRow(
                  icon: Icons.call_rounded,
                  label: 'Phone Number *',
                  hint: 'Enter phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  readOnly: widget.isExistingCustomer,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!_isValidE164(_normalizePhoneNumber(v))) {
                      return 'Enter a valid number with country code, e.g. +919876543210';
                    }
                    return null;
                  },
                ),
                _inputRow(
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  hint: 'Enter address (optional)',
                  controller: _addressController,
                  requiredField: false,
                  readOnly: widget.isExistingCustomer,
                ),
                if (widget.isExistingCustomer)
                  _inputRow(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Note / Received By (Optional)',
                    hint: 'e.g. Rahul Sharma (Customer\'s brother)',
                    controller: _receiverController,
                    requiredField: false,
                  ),
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
                label: const Text('Add Another Item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFFC8B2DD)),
                  backgroundColor: const Color(0xFFF4ECFB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Payment Details'),
              const SizedBox(height: 8),
              _groupCard([
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Payment Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _text)),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: _payPerItem,
                      title: const Text('Pay per item', style: TextStyle(fontSize: 13, color: _text)),
                      subtitle: const Text('Enter payment for each item separately.', style: TextStyle(fontSize: 11, color: _muted)),
                      contentPadding: EdgeInsets.zero,
                      activeColor: _purple,
                      onChanged: (val) {
                        if (val != null) setState(() => _payPerItem = val);
                      },
                    ),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: _payPerItem,
                      title: const Text('Add one total payment', style: TextStyle(fontSize: 13, color: _text)),
                      subtitle: const Text('Enter the total amount received for all items together.', style: TextStyle(fontSize: 11, color: _muted)),
                      contentPadding: EdgeInsets.zero,
                      activeColor: _purple,
                      onChanged: (val) {
                        if (val != null) setState(() => _payPerItem = val);
                      },
                    ),
                  ]),
                ),
                if (!_payPerItem) ...[
                  const Divider(color: _border, height: 1),
                  _inputRow(
                    icon: Icons.payments_rounded,
                    label: 'Total Amount Received (₹)',
                    hint: 'Enter overall payment received',
                    controller: _overallPaidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    requiredField: false,
                  ),
                ],
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Payment Summary'),
              const SizedBox(height: 8),
              _summaryCard(),
              const SizedBox(height: 18),
              _sectionTitle('Reminder (Optional)'),
              const SizedBox(height: 8),
              _groupCard([
                InkWell(
                  onTap: _pickReminderDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(children: [
                      _iconCircle(Icons.calendar_month_rounded),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Reminder Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
                          const SizedBox(height: 2),
                          Text(
                            _reminderDate == null
                                ? 'Select reminder date (optional)'
                                : '${_reminderDate!.day.toString().padLeft(2, '0')}/${_reminderDate!.month.toString().padLeft(2, '0')}/${_reminderDate!.year}',
                            style: TextStyle(fontSize: 12, color: _reminderDate == null ? _muted : _text),
                          ),
                        ]),
                      ),
                      const Icon(Icons.date_range_rounded, color: _purple, size: 20),
                    ]),
                  ),
                ),
                const Divider(color: _border, height: 1),
                SwitchListTile.adaptive(
                  value: _sendSmsReminder,
                  activeColor: _purple,
                  title: const Text('Send reminder by SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                  subtitle: Text(_sendSmsReminder ? 'SMS reminder enabled' : 'SMS reminder disabled',
                      style: const TextStyle(fontSize: 11, color: _muted)),
                  onChanged: (val) => setState(() => _sendSmsReminder = val),
                ),
              ]),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF2ECFA), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: _purple, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Total amount and balance are calculated automatically from all added items.',
                        style: TextStyle(fontSize: 11, color: _text)),
                  ),
                ]),
              ),
              const SizedBox(height: 22),

              // Bottom Action Buttons: Save Entry vs Save & Download Bill
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: (_isSaving || _isDownloadingPdf) ? null : () => _saveEntry(downloadPdf: false),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _purple, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Entry',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _purple,
                          side: const BorderSide(color: _purple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _isDownloadingPdf) ? null : () => _saveEntry(downloadPdf: true),
                        icon: _isDownloadingPdf
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Colors.white),
                        label: Text(
                          _isDownloadingPdf ? 'Downloading...' : 'Save & Download Bill',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text));

  Widget _groupCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
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
    bool readOnly = false,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(9, 7, 9, 2),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _iconCircle(icon),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: !readOnly,
          validator: requiredField ? validator : null,
          onChanged: (_) => _refresh(),
          decoration: _fieldDecoration(hint),
          style: TextStyle(fontSize: 12, color: readOnly ? _muted : _text),
        ),
      ])),
    ]),
  );

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
        const SizedBox(width: 8),
        Text(!widget.isSupplier ? 'Customer Item' : 'Supplier Item',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
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
      Row(children: [
        Expanded(
          child: _compactNumberField(
            label: 'Weight (g) *', hint: '0.0', controller: item.weight,
            validator: (v) {
              final val = double.tryParse(v?.trim().replaceAll(',', '') ?? '');
              return (val == null || val <= 0) ? 'Enter weight' : null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactNumberField(
            label: 'Rate / Gram (₹)', hint: 'e.g. 6200', controller: item.rate,
            validator: (v) => null,
          ),
        ),
      ]),
      const SizedBox(height: 8),
      _compactNumberField(
        label: 'Total Amount (₹) *', hint: '0', controller: item.totalController,
        validator: (v) {
          final val = double.tryParse(v?.trim().replaceAll(',', '') ?? '');
          return (val == null || val <= 0) ? 'Enter total' : null;
        },
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

  Widget _summaryCard() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
    child: Column(children: [
      _summaryRow('Total Amount', _totalAmount, isEmphasized: true),
      const Divider(color: _border, height: 1),
      _summaryRow('Total Paid', _amountPaid, valueColor: const Color(0xFF247A4B)),
      const Divider(color: _border, height: 1),
      _summaryRow('Remaining Balance', _balance, valueColor: const Color(0xFFD84343), isEmphasized: true),
    ]),
  );

  Widget _summaryRow(String label, double amount, {Color? valueColor, bool isEmphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500, color: _text)),
          const Spacer(),
          Text('₹ ${_money(amount)}', style: TextStyle(fontSize: isEmphasized ? 16 : 14, fontWeight: FontWeight.w800, color: valueColor ?? _text)),
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

  Widget _iconCircle(IconData icon) => Container(
    width: 28, height: 28, alignment: Alignment.center,
    decoration: const BoxDecoration(color: Color(0xFFF2ECFA), shape: BoxShape.circle),
    child: Icon(icon, size: 16, color: _purple),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _muted, fontSize: 11),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );
}
