import 'package:flutter/material.dart';

/// Add New Entry screen for creating a customer or supplier.
/// Place this file at:
/// lib/features/customers/presentation/screens/new_customer_screen.dart
class NewCustomerScreen extends StatefulWidget {
  /// Set [isSupplier] to true when opening this screen from the New Supplier action.
  const NewCustomerScreen({super.key, this.isSupplier = false});

  final bool isSupplier;

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  static const Color _purple = Color(0xFF35113F);
  static const Color _gold = Color(0xFFD2A04A);
  static const Color _cream = Color(0xFFFFFAF2);
  static const Color _border = Color(0xFFEDE4D9);
  static const Color _text = Color(0xFF292333);
  static const Color _muted = Color(0xFF8A858B);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _itemController = TextEditingController();
  final _weightController = TextEditingController();
  final _rateController = TextEditingController();
  final _totalController = TextEditingController(text: '0');
  final _paidController = TextEditingController();

  bool _isAutoTotal = true;
  bool _updatingTotal = false;
  DateTime? _reminderDate;
  bool _sendSmsReminder = false;

  late final bool _isCustomer = !widget.isSupplier;
  String _language = 'English';

  double get _calculatedTotal {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    return weight * rate;
  }

  double get _totalAmount =>
      double.tryParse(_totalController.text.trim()) ?? 0;

  double get _amountPaid =>
      double.tryParse(_paidController.text.trim()) ?? 0;

  double get _balance => (_totalAmount - _amountPaid).clamp(0, double.infinity).toDouble();

  String _money(double amount) =>
      amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightOrRateChanged);
    _rateController.addListener(_onWeightOrRateChanged);
    _totalController.addListener(() {
      if (!_updatingTotal) _isAutoTotal = false;
      _refreshAmounts();
    });
    _paidController.addListener(_refreshAmounts);
  }

  void _onWeightOrRateChanged() {
    if (_isAutoTotal) _setTotal(_calculatedTotal);
    _refreshAmounts();
  }

  void _setTotal(double amount) {
    _updatingTotal = true;
    _totalController.value = TextEditingValue(
      text: _money(amount),
      selection: TextSelection.collapsed(offset: _money(amount).length),
    );
    _updatingTotal = false;
  }

  void _recalculateTotal() {
    _isAutoTotal = true;
    _setTotal(_calculatedTotal);
    _refreshAmounts();
  }

  void _refreshAmounts() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _itemController.dispose();
    _weightController.dispose();
    _rateController.dispose();
    _totalController.dispose();
    _paidController.dispose();
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
            primary: _purple,
            onPrimary: Colors.white,
            surface: _cream,
            onSurface: _text,
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _reminderDate = selected);
    }
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;
    if (_amountPaid > _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount paid cannot exceed total amount.')),
      );
      return;
    }
    if (_sendSmsReminder && _reminderDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reminder date or turn off SMS reminder.')),
      );
      return;
    }

    // TODO: Connect this action to the customer/supplier create API.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_isCustomer ? 'Customer' : 'Supplier'} details validated. Connect the save API to persist this entry.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Add New Entry',
          style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700),
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
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, size: 18, color: _purple),
                    const SizedBox(width: 6),
                    Text(_language, style: const TextStyle(fontSize: 12, color: _text)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _text),
                  ],
                ),
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
              _sectionTitle(_isCustomer ? 'Customer Details' : 'Supplier Details'),
              const SizedBox(height: 8),
              _groupCard([
                _inputRow(
                  icon: Icons.person_rounded,
                  label: 'Full Name *',
                  hint: _isCustomer ? 'Enter customer name' : 'Enter supplier name',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                _inputRow(
                  icon: Icons.call_rounded,
                  label: 'Phone Number *',
                  hint: 'Enter phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                ),
                _inputRow(
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  hint: 'Enter address (optional)',
                  controller: _addressController,
                  requiredField: false,
                ),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Item Details'),
              const SizedBox(height: 8),
              _groupCard([
                _inputRow(
                  icon: Icons.diamond_outlined,
                  label: 'Item Name *',
                  hint: 'e.g. Gold Ring, Necklace',
                  controller: _itemController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _compactNumberField(
                          label: 'Weight (Grams) *',
                          hint: 'Enter weight (g)',
                          controller: _weightController,
                          validator: (v) => _positiveNumberValidator(v, 'Weight'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _compactNumberField(
                          label: 'Rate per Gram (₹)',
                          hint: 'Enter rate',
                          controller: _rateController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return _positiveNumberValidator(v, 'Rate');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EEE4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _iconCircle(Icons.currency_rupee_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Amount (₹)', style: TextStyle(fontSize: 11, color: _muted)),
                            TextFormField(
                              controller: _totalController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'Enter total or use auto calculation',
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _text),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Total amount is required';
                                final amount = double.tryParse(value.trim());
                                if (amount == null || amount < 0) return 'Enter a valid total amount';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Calculate from weight × rate',
                        onPressed: _recalculateTotal,
                        icon: Icon(
                          Icons.calculate_outlined,
                          color: _isAutoTotal ? _purple : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Payment Details'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _paymentCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF22864B),
                      iconBg: const Color(0xFFE3F3E6),
                      label: 'Amount Paid (₹)',
                      child: TextFormField(
                        controller: _paidController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: const [],
                        decoration: _fieldDecoration('Enter amount'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final value = double.tryParse(v.trim());
                          if (value == null || value < 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _paymentCard(
                      icon: Icons.money_off_csred_rounded,
                      iconColor: const Color(0xFFD84343),
                      iconBg: const Color(0xFFFCE7E4),
                      label: 'Balance (₹)',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(_money(_balance), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle('Reminder'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _pickReminderDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            _iconCircle(Icons.calendar_month_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Reminder Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _reminderDate == null
                                        ? 'Select reminder date (optional)'
                                        : '${_reminderDate!.day.toString().padLeft(2, '0')}/${_reminderDate!.month.toString().padLeft(2, '0')}/${_reminderDate!.year}',
                                    style: const TextStyle(fontSize: 12, color: _muted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: _purple, size: 19),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20, color: _border),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _sendSmsReminder,
                      activeTrackColor: _purple,
                      onChanged: (value) {
                        setState(() => _sendSmsReminder = value);
                      },
                      title: const Text('Send reminder by SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                      subtitle: Text(
                        _sendSmsReminder
                            ? 'SMS reminder enabled'
                            : 'SMS reminder disabled',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                      secondary: _iconCircle(Icons.sms_outlined),
                    ),
                    if (_sendSmsReminder && _reminderDate == null)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Please select a reminder date.', style: TextStyle(fontSize: 11, color: Colors.red)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save_rounded, size: 19),
                  label: Text('Save ${_isCustomer ? 'Customer' : 'Supplier'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
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

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text));

  Widget _groupCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(15), border: Border.all(color: _border)),
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
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconCircle(icon),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: requiredField ? validator : null,
                  decoration: _fieldDecoration(hint),
                  style: const TextStyle(fontSize: 12, color: _text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)),
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        decoration: _fieldDecoration(hint),
        style: const TextStyle(fontSize: 12, color: _text),
      ),
    ],
  );

  String? _positiveNumberValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) return 'Enter valid $label';
    return null;
  }

  Widget _iconCircle(IconData icon) => Container(
    width: 37,
    height: 37,
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
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), border: Border.all(color: _border), borderRadius: BorderRadius.circular(13)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, size: 16, color: iconColor)),
        const SizedBox(width: 7),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _text)), child])),
      ],
    ),
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
