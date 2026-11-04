import 'package:flutter/material.dart';

/// Static Payments screen for JAIWER.
///
/// This screen is intentionally frontend-only:
/// - No API calls
/// - No backend integration
/// - Sample transactions are stored in this file
/// - Add Payment is a local UI demonstration only
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  static const Color _primary = Color(0xFF2B1038);
  static const Color _gold = Color(0xFFD9B66F);
  static const Color _background = Color(0xFFFFF9F0);
  static const Color _text = Color(0xFF29232D);
  static const Color _muted = Color(0xFF5E5B70);
  static const Color _green = Color(0xFF087A32);

  final TextEditingController _searchController = TextEditingController();

  bool _searchOpen = false;
  String _selectedMethod = 'All';
  String _sortLabel = 'Newest First';
  DateTimeRange? _selectedDateRange;

  final List<_PaymentTransaction> _transactions = [
    _PaymentTransaction(
      name: 'Ramesh Verma',
      initials: 'RV',
      description: 'Gold Ring - Payment',
      dateLabel: 'Today, 10:30 AM',
      amount: 45000,
      method: 'UPI',
      date: DateTime(2026, 10, 31, 10, 30),
    ),
    _PaymentTransaction(
      name: 'Sharma Jewellery (Supplier)',
      initials: 'SJ',
      description: 'Gold - Payment',
      dateLabel: 'Today, 09:15 AM',
      amount: 150000,
      method: 'Cash',
      date: DateTime(2026, 10, 31, 9, 15),
    ),
    _PaymentTransaction(
      name: 'Priya Singh',
      initials: 'PS',
      description: 'Necklace - Payment',
      dateLabel: 'Yesterday, 04:20 PM',
      amount: 85000,
      method: 'Bank',
      date: DateTime(2026, 10, 30, 16, 20),
    ),
    _PaymentTransaction(
      name: 'Amit Kumar',
      initials: 'AK',
      description: 'Earrings - Payment',
      dateLabel: 'Yesterday, 11:05 AM',
      amount: 25000,
      method: 'UPI',
      date: DateTime(2026, 10, 30, 11, 5),
    ),
    _PaymentTransaction(
      name: 'Meena Devi',
      initials: 'MD',
      description: 'Bangle - Payment',
      dateLabel: '28 Oct 2026, 05:40 PM',
      amount: 40000,
      method: 'Cash',
      date: DateTime(2026, 10, 28, 17, 40),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(int value) {
    final String digits = value.toString();
    if (digits.length <= 3) return '₹ $digits';

    final String lastThree = digits.substring(digits.length - 3);
    String remaining = digits.substring(0, digits.length - 3);
    final List<String> groups = [];

    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);

    return '₹ ${groups.join(',')},$lastThree';
  }

  List<_PaymentTransaction> get _visibleTransactions {
    List<_PaymentTransaction> result = _transactions.where((transaction) {
      final bool methodMatches =
          _selectedMethod == 'All' || transaction.method == _selectedMethod;

      final String query = _searchController.text.trim().toLowerCase();
      final bool searchMatches = query.isEmpty ||
          transaction.name.toLowerCase().contains(query) ||
          transaction.description.toLowerCase().contains(query) ||
          transaction.method.toLowerCase().contains(query);

      final bool dateMatches = _selectedDateRange == null ||
          (!transaction.date.isBefore(_selectedDateRange!.start) &&
              !transaction.date.isAfter(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              ));

      return methodMatches && searchMatches && dateMatches;
    }).toList();

    result.sort((a, b) => _sortLabel == 'Newest First'
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));

    return result;
  }

  Future<void> _chooseDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(2026, 10, 1),
            end: DateTime(2026, 10, 31),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: _background,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  String get _dateRangeLabel {
    if (_selectedDateRange == null) {
      return 'This Month (01 Oct – 31 Oct 2026)';
    }
    final DateTime start = _selectedDateRange!.start;
    final DateTime end = _selectedDateRange!.end;
    return '${_formatDate(start)} – ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _showExportMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export UI is ready. File export will be added later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddPaymentDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final itemController = TextEditingController();
    String method = 'Cash';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _background,
              title: const Text(
                'Add Payment',
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField(
                        controller: nameController,
                        label: 'Customer / Supplier Name',
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter a name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _dialogField(
                        controller: itemController,
                        label: 'Payment Description',
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _dialogField(
                        controller: amountController,
                        label: 'Amount (₹)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final amount = int.tryParse(value ?? '');
                          return amount == null || amount <= 0
                              ? 'Enter a valid amount'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: method,
                        decoration: _inputDecoration('Payment Method'),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => method = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final name = nameController.text.trim();
                    final now = DateTime.now();
                    setState(() {
                      _transactions.insert(
                        0,
                        _PaymentTransaction(
                          name: name,
                          initials: _initials(name),
                          description: itemController.text.trim(),
                          dateLabel: 'Just now',
                          amount: int.parse(amountController.text.trim()),
                          method: method,
                          date: now,
                        ),
                      );
                      _selectedMethod = 'All';
                      _selectedDateRange = null;
                    });

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment added locally.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
    itemController.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8DCD0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8DCD0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  void _showTransactionDetails(_PaymentTransaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
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
                const SizedBox(height: 22),
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '+ ${_money(transaction.amount)}',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('Name', transaction.name),
                _detailRow('Description', transaction.description),
                _detailRow('Payment Method', transaction.method),
                _detailRow('Date', transaction.dateLabel),
                _detailRow('Status', 'Received', valueColor: _green),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? _text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _visibleTransactions;

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentDialog,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 34),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  _buildDateAndExportRow(),
                  const SizedBox(height: 20),
                  _buildSummaryCards(),
                  const SizedBox(height: 22),
                  _buildMethodFilters(),
                  const SizedBox(height: 28),
                  _buildTransactionsHeader(),
                  const SizedBox(height: 14),
                  if (transactions.isEmpty)
                    _buildEmptyState()
                  else
                    ...transactions.map(
                          (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTransactionCard(transaction),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: _primary),
          ),
          Expanded(
            child: Column(
              children: const [
                Text(
                  'Payments',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All Received Payments',
                  style: TextStyle(color: _muted, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Search payments',
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _searchController.clear();
              });
            },
            icon: const Icon(Icons.search, color: _primary, size: 27),
          ),
          IconButton(
            tooltip: 'Filter payments',
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_alt_outlined, color: _primary, size: 27),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Payments',
                style: TextStyle(
                  color: _primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: ['All', 'Cash', 'UPI', 'Bank', 'Other'].map((method) {
                  final selected = _selectedMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: selected,
                    selectedColor: _primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _text,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedMethod = method);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndExportRow() {
    return Column(
      children: [
        if (_searchOpen) ...[
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search name, item or payment method',
              prefixIcon: const Icon(Icons.search, color: _primary),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE7D9CD)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseDateRange,
                icon: const Icon(Icons.calendar_month_outlined, size: 21),
                label: Text(
                  _dateRangeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side: const BorderSide(color: Color(0xFFE5D6CA)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _showExportMessage,
              icon: const Icon(Icons.download_outlined, size: 20),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;
        final cards = [
          _SummaryCardData(
            title: 'Total Received',
            amount: '₹ 12,45,000',
            icon: Icons.account_balance_wallet_outlined,
            background: const Color(0xFFEAF4E6),
            border: const Color(0xFFCFE5C8),
            iconColor: const Color(0xFF087A32),
          ),
          _SummaryCardData(
            title: 'Cash Received',
            amount: '₹ 4,25,000',
            icon: Icons.payments_outlined,
            background: const Color(0xFFFFF0DD),
            border: const Color(0xFFF3DDBD),
            iconColor: const Color(0xFF9A6100),
          ),
          _SummaryCardData(
            title: 'UPI / Bank Received',
            amount: '₹ 8,20,000',
            icon: Icons.account_balance_outlined,
            background: const Color(0xFFF3EAF7),
            border: const Color(0xFFE4D4EF),
            iconColor: _primary,
          ),
        ];

        if (compact) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _buildSummaryCard(card, compact: true),
              ),
            )
                .toList(),
          );
        }

        return Row(
          children: cards
              .map(
                (card) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildSummaryCard(card),
              ),
            ),
          )
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data, {bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 12),
      decoration: BoxDecoration(
        color: data.background,
        border: Border.all(color: data.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 43 : 42,
            height: compact ? 43 : 42,
            decoration: BoxDecoration(
              color: data.iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.iconColor, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _text),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.amount,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodFilters() {
    final filters = [
      ('All', '124', Icons.apps),
      ('Cash', '46', Icons.payments_outlined),
      ('UPI', '52', Icons.send_outlined),
      ('Bank', '18', Icons.account_balance_outlined),
      ('Other', '8', Icons.more_horiz),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedMethod == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              avatar: selected
                  ? null
                  : Icon(filter.$3, size: 18, color: _text),
              label: Text('${filter.$1} (${filter.$2})'),
              selected: selected,
              showCheckmark: false,
              selectedColor: _primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: selected ? _primary : const Color(0xFFE5D6CA),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : _text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              onSelected: (_) => setState(() => _selectedMethod = filter.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Payment Transactions',
            style: TextStyle(
              color: _primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => setState(() => _sortLabel = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'Newest First', child: Text('Newest First')),
            PopupMenuItem(value: 'Oldest First', child: Text('Oldest First')),
          ],
          child: Row(
            children: [
              Text(
                _sortLabel,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.swap_vert, color: _primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(_PaymentTransaction transaction) {
    final Color methodColor = transaction.method == 'Cash'
        ? const Color(0xFF9A6100)
        : _primary;
    final Color methodBackground = transaction.method == 'Cash'
        ? const Color(0xFFFFEBD0)
        : const Color(0xFFF3EAF7);
    final IconData methodIcon = transaction.method == 'Cash'
        ? Icons.payments_outlined
        : transaction.method == 'Bank'
        ? Icons.account_balance_outlined
        : transaction.method == 'UPI'
        ? Icons.send_outlined
        : Icons.more_horiz;

    return Material(
      color: Colors.white.withOpacity(0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showTransactionDetails(transaction),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFECE0D6)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return _buildCompactTransaction(
                  transaction,
                  methodColor,
                  methodBackground,
                  methodIcon,
                );
              }
              return Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFF9E8CC),
                    child: Text(
                      transaction.initials,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    flex: 5,
                    child: _transactionDescription(transaction),
                  ),
                  const SizedBox(width: 6),
                  _methodBadge(
                    transaction.method,
                    methodColor,
                    methodBackground,
                    methodIcon,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _amountAndStatus(transaction),
                  ),
                  const Icon(Icons.chevron_right, color: _primary, size: 25),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTransaction(
      _PaymentTransaction transaction,
      Color methodColor,
      Color methodBackground,
      IconData methodIcon,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF9E8CC),
              child: Text(transaction.initials),
            ),
            const SizedBox(width: 10),
            Expanded(child: _transactionDescription(transaction)),
            const Icon(Icons.chevron_right, color: _primary),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _methodBadge(
              transaction.method,
              methodColor,
              methodBackground,
              methodIcon,
            ),
            const Spacer(),
            _amountAndStatus(transaction),
          ],
        ),
      ],
    );
  }

  Widget _transactionDescription(_PaymentTransaction transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: _muted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                transaction.dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _methodBadge(
      String method,
      Color color,
      Color background,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            method,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountAndStatus(_PaymentTransaction transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '+ ${_money(transaction.amount)}',
            style: const TextStyle(
              color: _green,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: _green, size: 15),
            SizedBox(width: 4),
            Text(
              'Received',
              style: TextStyle(color: _green, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        border: Border.all(color: const Color(0xFFECE0D6)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: _muted),
          SizedBox(height: 10),
          Text(
            'No payments found',
            style: TextStyle(
              color: _primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PaymentTransaction {
  const _PaymentTransaction({
    required this.name,
    required this.initials,
    required this.description,
    required this.dateLabel,
    required this.amount,
    required this.method,
    required this.date,
  });

  final String name;
  final String initials;
  final String description;
  final String dateLabel;
  final int amount;
  final String method;
  final DateTime date;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.amount,
    required this.icon,
    required this.background,
    required this.border,
    required this.iconColor,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color background;
  final Color border;
  final Color iconColor;
}
