import 'package:flutter/material.dart';

class CustomerDetailsData {
  const CustomerDetailsData({
    required this.name,
    required this.phone,
    required this.initials,
    required this.total,
    required this.baki,
    required this.items,
  });

  final String name;
  final String phone;
  final String initials;
  final int total;
  final int baki;
  final int items;
}

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customer});
  final CustomerDetailsData customer;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  static const _purple = Color(0xFF35113F);
  static const _cream = Color(0xFFFFFAF2);
  static const _border = Color(0xFFEDE4D9);
  static const _muted = Color(0xFF718096);
  static const _green = Color(0xFF16B85A);
  static const _red = Color(0xFFE53935);
  int _tab = 0;

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

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final paid = c.total - c.baki;
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
        title: const Text('Customer Details', style: TextStyle(color: _purple, fontSize: 21, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [TextButton(onPressed: () => _message('Edit customer is demo-only for now'), child: const Text('Edit', style: TextStyle(color: _purple, fontSize: 16, fontWeight: FontWeight.w600))), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            _card(
              child: Row(children: [
                CircleAvatar(radius: 37, backgroundColor: const Color(0xFFF8E4C8), child: Text(c.initials, style: const TextStyle(color: _purple, fontSize: 24, fontWeight: FontWeight.w700))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _purple, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('+91 ${c.phone}', style: const TextStyle(color: _muted, fontSize: 13)),
                  const SizedBox(height: 5),
                  const Row(children: [Icon(Icons.location_on, color: _purple, size: 16), SizedBox(width: 4), Expanded(child: Text('Address not added', style: TextStyle(color: _muted, fontSize: 12)))]),
                ])),
                const SizedBox(width: 4),
                _roundAction(Icons.call_rounded, const Color(0xFFF2ECFA), _purple, () => _message('Calling feature will be connected later')),
                const SizedBox(width: 6),
                _roundAction(Icons.chat_rounded, const Color(0xFFE0F7E8), _green, () => _message('WhatsApp feature will be connected later')),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _summaryCard(Icons.shopping_bag_rounded, 'Total Purchase', '₹ ${_money(c.total)}', const Color(0xFFD49A3A), const Color(0xFFFFF0D6))),
              const SizedBox(width: 8),
              Expanded(child: _summaryCard(Icons.check_circle_rounded, 'Total Paid', '₹ ${_money(paid)}', _green, const Color(0xFFE2F8E8))),
              const SizedBox(width: 8),
              Expanded(child: _summaryCard(Icons.account_balance_wallet_rounded, 'Balance', '₹ ${_money(c.baki)}', _red, const Color(0xFFFFE6E6))),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _tabButton('Transactions', 0),
              _tabButton('Items (${c.items})', 1),
              _tabButton('Details', 2),
            ]),
            Container(height: 1, color: _border),
            const SizedBox(height: 10),
            if (_tab == 0) ...[
              _transactionItem('20', 'Oct', '2026', 'Gold Ring', '22K • 12.5 g', 'Rate: ₹ 6,200/g', 77500, 50000, 27500),
              _transactionItem('12', 'Oct', '2026', 'Necklace', '22K • 28.0 g', 'Rate: ₹ 6,150/g', 172200, 120000, 52200),
              _transactionItem('05', 'Oct', '2026', 'Gold Earrings', '22K • 16.0 g', 'Rate: ₹ 5,900/g', 75300, 55300, 20000),
            ] else if (_tab == 1) ...[
              _transactionItem('20', 'Oct', '2026', 'Gold Ring', '22K • 12.5 g', 'Rate: ₹ 6,200/g', 77500, 50000, 27500),
              _transactionItem('12', 'Oct', '2026', 'Necklace', '22K • 28.0 g', 'Rate: ₹ 6,150/g', 172200, 120000, 52200),
              _transactionItem('05', 'Oct', '2026', 'Gold Earrings', '22K • 16.0 g', 'Rate: ₹ 5,900/g', 75300, 55300, 20000),
              if (c.items > 3) _transactionItem('01', 'Oct', '2026', 'Additional Jewellery', '22K • 8.0 g', 'Rate: ₹ 5,800/g', 46400, 0, 46400),
            ] else ...[
              _card(child: Column(children: [
                _detailRow('Customer Name', c.name),
                const Divider(color: _border),
                _detailRow('Phone Number', '+91 ${c.phone}'),
                const Divider(color: _border),
                _detailRow('Address', 'Not added'),
                const Divider(color: _border),
                _detailRow('Total Items', '${c.items}'),
                const Divider(color: _border),
                _detailRow('Customer Type', 'Retail customer'),
              ])),
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
                onPressed: () => _message('Add Payment form will be connected next'),
                icon: const Icon(Icons.currency_rupee_rounded),
                label: const Text('Add Payment', maxLines: 1),
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
                onPressed: () => _message('Add New Item form will be connected next'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Item', maxLines: 1),
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

  Widget _tabButton(String title, int index) => Expanded(child: InkWell(onTap: () => setState(() => _tab = index), child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == index ? _purple : Colors.transparent, width: 2))), child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: _tab == index ? _purple : _muted, fontSize: 13, fontWeight: FontWeight.w600)))));

  Widget _card({required Widget child}) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)), child: child);

  Widget _summaryCard(IconData icon, String title, String value, Color color, Color bg) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 16, backgroundColor: bg, child: Icon(icon, size: 17, color: color)), const SizedBox(height: 8), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)), const SizedBox(height: 5), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(color: color == _red ? _red : (color == _green ? _green : _purple), fontSize: 14, fontWeight: FontWeight.w700)))]));

  Widget _roundAction(IconData icon, Color bg, Color fg, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(30), child: CircleAvatar(radius: 22, backgroundColor: bg, child: Icon(icon, color: fg, size: 21)));

  Widget _transactionItem(String day, String month, String year, String title, String meta, String rate, int total, int paid, int balance) => Container(margin: const EdgeInsets.only(bottom: 1), padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border))), child: Row(children: [
    Container(width: 54, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF2ECFA), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(day, style: const TextStyle(color: _purple, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(month, style: const TextStyle(color: _muted, fontSize: 11)), Text(year, style: const TextStyle(color: _muted, fontSize: 11))])),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(meta, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 4), Text(rate, style: const TextStyle(color: _muted, fontSize: 12))])),
    const SizedBox(width: 4),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('₹ ${_money(total)}', style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('Paid: ₹ ${_money(paid)}', style: const TextStyle(color: _green, fontSize: 12)), const SizedBox(height: 4), Text('Baki: ₹ ${_money(balance)}', style: const TextStyle(color: _red, fontSize: 12))]),
    const Icon(Icons.chevron_right_rounded, color: _purple, size: 24),
  ]));

  Widget _paymentItem(String day, String month, String year, String method, String note, int amount) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border))), child: Row(children: [
    const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE2F8E8), child: Icon(Icons.account_balance_wallet_rounded, color: _green, size: 20)),
    const SizedBox(width: 8),
    Container(width: 54, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF2ECFA), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(day, style: const TextStyle(color: _purple, fontSize: 16, fontWeight: FontWeight.w700)), Text(month, style: const TextStyle(color: _muted, fontSize: 11)), Text(year, style: const TextStyle(color: _muted, fontSize: 11))])),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Payment Received', style: const TextStyle(color: _purple, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(method, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 4), Text(note, style: const TextStyle(color: _muted, fontSize: 12))])),
    const SizedBox(width: 4),
    Text('₹ ${_money(amount)}', style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
    const Icon(Icons.chevron_right_rounded, color: _purple, size: 22),
  ]));

  Widget _detailRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 13))), Text(value, style: const TextStyle(color: _purple, fontWeight: FontWeight.w600, fontSize: 13))]));

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
