import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/notification_service.dart';
import '../../../customers/presentation/screens/new_customer_screen.dart';
import '../../../customers/presentation/screens/customers_list_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_list_screen.dart';
import '../../../metal_rates/presentation/screens/metal_rates_screen.dart';
import '../../../onboarding/presentation/screens/role_selection_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../shop_settings/presentation/screens/shop_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showCash = true;
  bool _isOffline = false;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _isOffline = !ConnectivityService.instance.isOnline;
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOffline = !isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
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
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NewCustomerScreen(),
              ),
            );
          },
          onSupplierTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NewCustomerScreen(isSupplier: true),
              ),
            );
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
    await NotificationService.instance.clearToken();
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
            onPressed: () async {
              await NotificationService.instance.requestPermission();
              _showMessage('Notification permissions updated.');
            },
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

            if (label == 'My Profile') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileScreen(
                    onLogout: _logout,
                  ),
                ),
              );
              return;
            }

            if (label == 'Shop Settings') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ShopSettingsScreen(),
                ),
              );
              return;
            }

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
                      if (_isOffline)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: OfflineBanner(),
                        ),
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
                        childAspectRatio: isWide ? 1.0 : 0.86,
                        children: [
                          _DashboardTile(
                            title: 'Customers',
                            subtitle: '248',
                            icon: Icons.people_alt_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CustomersListScreen(),
                              ),
                            ),
                          ),
                          _DashboardTile(
                            title: 'Suppliers',
                            subtitle: 'Manage',
                            icon: Icons.inventory_2_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SuppliersListScreen(),
                              ),
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
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PaymentsScreen(),
                              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: AppColors.goldDark),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.heading,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
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
  String _email = 'Email not available';
  String _phone = '';
  String _accountType = 'Shop Owner';
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await _storage.read(key: 'user_name');
      final email = await _storage.read(key: 'user_email');
      final phone = await _storage.read(key: 'user_phone');
      final accountType = await _storage.read(key: 'account_type');
      final shopName = await _storage.read(key: 'shop_name');

      if (!mounted) return;
      setState(() {
        if (name != null && name.trim().isNotEmpty) _name = name.trim();
        if (email != null && email.trim().isNotEmpty) _email = email.trim();
        if (phone != null && phone.trim().isNotEmpty) _phone = phone.trim();
        if (shopName != null && shopName.trim().isNotEmpty) {
          _shopName = shopName.trim();
        }
        if (accountType != null && accountType.trim().isNotEmpty) {
          _accountType = accountType.toLowerCase() == 'worker'
              ? 'Shop Worker'
              : 'Shop Owner';
        }
      });
    } catch (e) {
      debugPrint('Could not load drawer profile: $e');
    }
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final list = parts.take(2).toList();
    if (list.isEmpty) return 'JS';
    return list.map((part) => part[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 29,
                              letterSpacing: -1.1,
                              fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 3),
                        const Text(
                          'Jewellery Shop Management',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 30,
                      color: AppColors.heading,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF4E6),
                      border: Border.all(color: AppColors.gold, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 29,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.heading,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBD0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 16,
                                color: AppColors.goldDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _accountType,
                                style: const TextStyle(
                                  color: AppColors.goldDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    children: [
                      _DrawerMenuItem(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        selected: true,
                        onTap: () => widget.onItemTap('Home'),
                      ),
                      _DrawerMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'My Profile',
                        onTap: () => widget.onItemTap('My Profile'),
                      ),
                      _DrawerMenuItem(
                        icon: Icons.storefront_outlined,
                        title: 'Shop Settings',
                        onTap: () => widget.onItemTap('Shop Settings'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.border, height: 1),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      _DrawerMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () => widget.onItemTap('Help & Support'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      _DrawerMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                        onTap: widget.onLogout,
                      ),
                    ],
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'v1.2.4 (Beta)',
                      style: TextStyle(color: AppColors.body, fontSize: 12),
                    ),
                  ),
                  if (_shopName.isNotEmpty)
                    Flexible(
                      child: Text(
                        _shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.body,
                          fontSize: 11,
                        ),
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
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive
        ? const Color(0xFFC62828)
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? const Color(0xFFF2E8F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : foreground,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? foreground : AppColors.heading,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive ? foreground : AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
