import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../metal_rates/presentation/screens/metal_rates_screen.dart';
import '../../../onboarding/presentation/screens/role_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showCash = true;
  int _selectedTab = 0;
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddNewSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddNewSheet(
          onCustomerTap: () {
            _showMessage('New Customer screen will be connected next.');
          },
          onSupplierTap: () {
            _showMessage('New Supplier screen will be connected next.');
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'token_type');
    await storage.delete(key: 'user_name');
    await storage.delete(key: 'user_email');
    await storage.delete(key: 'user_phone');
    await storage.delete(key: 'account_type');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'owner_reference_id');
    await storage.delete(key: 'shop_name');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.8,
                ),
                children: [
                  TextSpan(
                    text: 'Jewel',
                    style: TextStyle(color: AppColors.goldDark),
                  ),
                  TextSpan(
                    text: 'Setu',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const Text(
              'Jewellery Shop Management',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.body,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () =>
                _showMessage('Notifications will be connected next.'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.78,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        child: _ProfileSettingsDrawer(
          onClose: () => Navigator.of(context).pop(),
          onLogout: _logout,
          onItemTap: (label) {
            Navigator.of(context).pop();
            _showMessage('$label screen will be connected next.');
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                12,
                isWide ? 28 : 16,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CashCard(
                        showCash: _showCash,
                        onToggle: () {
                          setState(() {
                            _showCash = !_showCash;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _BalanceCard(
                              title: 'Total Jama',
                              amount: '₹ 12,20,300',
                              icon: Icons.north_east_rounded,
                              color: const Color(0xFFE7F2E2),
                              iconColor: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BalanceCard(
                              title: 'Total Baki',
                              amount: '₹ 2,74,500',
                              icon: Icons.south_east_rounded,
                              color: const Color(0xFFFCE8E4),
                              iconColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: isWide ? 6 : 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: isWide ? 1.0 : 0.92,
                        children: [
                          _DashboardTile(
                            title: 'Customers',
                            subtitle: '248',
                            icon: Icons.people_alt_rounded,
                            onTap: () => _showMessage(
                              'Customer management will be connected next.',
                            ),
                          ),
                          _DashboardTile(
                            title: 'Suppliers',
                            subtitle: '34',
                            icon: Icons.inventory_2_rounded,
                            onTap: () => _showMessage(
                              'Supplier management will be connected next.',
                            ),
                          ),
                          _DashboardTile(
                            title: 'Inventory',
                            subtitle: '1,248 items',
                            icon: Icons.all_inbox_rounded,
                            onTap: () => _showMessage(
                              'Inventory will be connected next.',
                            ),
                          ),
                          _DashboardTile(
                            title: 'Payments',
                            subtitle: 'Today: ₹ 45,000',
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: () => _showMessage(
                              'Payments will be connected next.',
                            ),
                          ),
                          _DashboardTile(
                            title: 'Gold Rate',
                            subtitle: '₹ 7,320/g',
                            icon: Icons.bar_chart_rounded,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MetalRatesScreen(),
                                ),
                              );
                            },
                          ),
                          _DashboardTile(
                            title: 'Reports',
                            subtitle: 'View reports',
                            icon: Icons.pie_chart_rounded,
                            onTap: () =>
                                _showMessage('Reports will be connected next.'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: AppTextStyles.sectionHeading.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showMessage(
                              'All transactions will be available here.',
                            ),
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: const [
                            _TransactionTile(
                              initials: 'RV',
                              name: 'Ramesh Verma',
                              description: 'Gold Ring - 12.5 g',
                              amount: '+ ₹ 45,000',
                              time: 'Today, 10:30 AM',
                              isCredit: true,
                            ),
                            Divider(height: 1, color: AppColors.border),
                            _TransactionTile(
                              initials: 'SJ',
                              name: 'Sharma Jewellery (Supplier)',
                              description: 'Gold - 100 g',
                              amount: '- ₹ 6,80,000',
                              time: 'Today, 09:15 AM',
                              isCredit: false,
                            ),
                            Divider(height: 1, color: AppColors.border),
                            _TransactionTile(
                              initials: 'PS',
                              name: 'Priya Singh',
                              description: 'Necklace - 22 g',
                              amount: '+ ₹ 85,000',
                              time: 'Yesterday',
                              isCredit: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddNewSheet,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.body,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });

          if (index != 0) {
            _showMessage(
              '${['Home', 'Customers', 'Inventory', 'Payments', 'More'][index]} screen will be connected next.',
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({required this.showCash, required this.onToggle});

  final bool showCash;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF35103E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, size: 42, color: AppColors.gold),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Cash (Aaj tak)',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 7),
                Text(
                  showCash ? '₹ 12,45,800' : '₹ •••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            color: Colors.white,
            icon: Icon(
              showCash
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.body),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
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
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: AppColors.goldDark),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.heading,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.body, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.initials,
    required this.name,
    required this.description,
    required this.amount,
    required this.time,
    required this.isCredit,
  });

  final String initials;
  final String name;
  final String description;
  final String amount;
  final String time;
  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.gold.withValues(alpha: 0.30),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.body),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: AppColors.body),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddNewSheet extends StatelessWidget {
  const _AddNewSheet({
    required this.onCustomerTap,
    required this.onSupplierTap,
  });

  final VoidCallback onCustomerTap;
  final VoidCallback onSupplierTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8B0A8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Add New',
              style: AppTextStyles.welcomeHeading.copyWith(fontSize: 27),
            ),

            const SizedBox(height: 4),

            Text(
              'What do you want to add?',
              style: AppTextStyles.body.copyWith(fontSize: 17),
            ),

            const SizedBox(height: 18),

            _AddNewOption(
              title: 'New Customer',
              description:
              'Add customer details, purchase, payment and balance.',
              icon: Icons.person_rounded,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                onCustomerTap();
              },
            ),

            const SizedBox(height: 12),

            _AddNewOption(
              title: 'New Supplier',
              description:
              'Add supplier details, purchase, payment and balance.',
              icon: Icons.inventory_2_rounded,
              iconColor: AppColors.goldDark,
              onTap: () {
                Navigator.pop(context);
                onSupplierTap();
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.heading,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNewOption extends StatelessWidget {
  const _AddNewOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.roleTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                size: 29,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ProfileSettingsDrawer extends StatefulWidget {
  const _ProfileSettingsDrawer({
    required this.onClose,
    required this.onLogout,
    required this.onItemTap,
  });

  final VoidCallback onClose;
  final Future<void> Function() onLogout;
  final ValueChanged<String> onItemTap;

  @override
  State<_ProfileSettingsDrawer> createState() => _ProfileSettingsDrawerState();
}

class _ProfileSettingsDrawerState extends State<_ProfileSettingsDrawer> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  String _name = 'JewelSetu User';
  String _shopName = 'Email not available';
  String _email = '';
  String _phone = '';
  String _accountType = 'Shop Owner';
  String _shopId = 'Shop ID not set';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await _storage.read(key: 'user_name');
      final shopName = await _storage.read(key: 'shop_name');
      final email = await _storage.read(key: 'user_email');
      final phone = await _storage.read(key: 'user_phone');
      final accountType = await _storage.read(key: 'account_type');
      final shopId = await _storage.read(key: 'owner_reference_id');
      final userId = await _storage.read(key: 'user_id');
      if (!mounted) return;
      setState(() {
        if (name != null && name.trim().isNotEmpty) _name = name.trim();
        if (shopName != null && shopName.trim().isNotEmpty) {
          _shopName = shopName.trim();
        } else if (email != null && email.trim().isNotEmpty) {
          _shopName = email.trim();
        }
        if (email != null && email.trim().isNotEmpty) _email = email.trim();
        if (phone != null && phone.trim().isNotEmpty) _phone = phone.trim();
        if (accountType != null && accountType.trim().isNotEmpty) {
          _accountType = accountType.toLowerCase() == 'worker'
              ? 'Shop Worker'
              : 'Shop Owner';
        }
        if (shopId != null && shopId.trim().isNotEmpty) {
          _shopId = shopId.trim();
        } else if (userId != null && userId.trim().isNotEmpty) {
          _shopId = userId.trim();
        }
      });
    } catch (e) {
      debugPrint('Could not load drawer profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name.trim().isEmpty
        ? 'JS'
        : _name.trim().split(RegExp(r'\s+')).take(2).map((part) => part[0]).join().toUpperCase();

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
              child: IconButton(
                tooltip: 'Close menu',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, size: 30, color: AppColors.primary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF25072E)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _shopName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF1DDAF), fontSize: 15),
                        ),
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFE6C77F), fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _accountType,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ID: $_shopId',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFE6C77F), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              children: [
                _DrawerMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  onTap: () => widget.onItemTap('My Profile'),
                ),
                _DrawerMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Shop Settings',
                  onTap: () => widget.onItemTap('Shop Settings'),
                ),
                _DrawerMenuItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  onTap: () => widget.onItemTap('Language'),
                ),
                _DrawerMenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  onTap: () => widget.onItemTap('Security'),
                ),
                _DrawerMenuItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  onTap: () => widget.onItemTap('Help & Support'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: ListTile(
              onTap: widget.onLogout,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const Icon(Icons.logout_rounded, color: Color(0xFF8C1538), size: 27),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFF8C1538),
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 18, top: 4),
            child: Text('v1.2.4 (Beta)', style: TextStyle(color: AppColors.body, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.heading,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9D879E), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
