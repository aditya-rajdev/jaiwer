
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _storage = FlutterSecureStorage();

  static const Color primary = Color(0xFF2B1038);
  static const Color gold = Color(0xFFD9B66F);
  static const Color background = Color(0xFFFFF9F0);
  static const Color borderColor = Color(0xFFEDE4D9);

  String name = 'User';
  String email = '';
  String phone = '';
  String role = 'Shop Owner';
  String shopName = 'JAIWER Member';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final storedName = await _storage.read(key: 'user_name');
      final storedEmail = await _storage.read(key: 'user_email');
      final storedPhone = await _storage.read(key: 'user_phone');
      final storedRole = await _storage.read(key: 'account_type');
      final storedShop = await _storage.read(key: 'shop_name');

      if (!mounted) return;

      setState(() {
        name = storedName?.trim().isNotEmpty == true
            ? storedName!.trim()
            : 'User';

        email = storedEmail ?? '';
        phone = storedPhone ?? '';
        role = _formatRole(storedRole);
        shopName = storedShop?.trim().isNotEmpty == true
            ? storedShop!.trim()
            : 'JAIWER Member';

        isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatRole(String? value) {
    if (value == null || value.isEmpty) return 'Shop Owner';

    switch (value.toLowerCase()) {
      case 'owner':
      case 'shop_owner':
        return 'Shop Owner';
      case 'worker':
        return 'Worker';
      default:
        return value
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) =>
        word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';

    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return parts.first[0].toUpperCase();
  }

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is not connected yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: primary),
        )
            : Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      Icons.person_outline,
                      'Personal Information',
                    ),
                    _buildPersonalInformation(),

                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      Icons.layers_outlined,
                      'Account Information',
                    ),
                    _buildAccountInformation(),

                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      Icons.lock_outline,
                      'Security & Account',
                    ),
                    _buildSecuritySection(),

                    const SizedBox(height: 28),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              color: primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: primary,
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: TextButton.icon(
              onPressed: () => _showUnavailable('Edit Profile'),
              icon: const Icon(Icons.edit_outlined, color: primary),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF46134C),
            Color(0xFF26002F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              border: Border.all(color: gold, width: 5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: primary,
                fontSize: 42,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD98B),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 17,
                        color: primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Color(0xFF482A12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.diamond_outlined,
            color: Color(0x66FFFFFF),
            size: 55,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 27),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _sectionCard(
      children: [
        _infoRow(
          Icons.person_outline,
          'Full Name',
          name,
          onTap: () => _showUnavailable('Edit Name'),
        ),
        _infoRow(
          Icons.email_outlined,
          'Email Address',
          email.isEmpty ? 'Not available' : email,
          onTap: () => _showUnavailable('Email Details'),
        ),
        _infoRow(
          Icons.phone_outlined,
          'Phone Number',
          phone.isEmpty ? 'Not available' : _formatPhone(phone),
          onTap: () => _showUnavailable('Phone Details'),
        ),
        _infoRow(
          Icons.location_on_outlined,
          'Address',
          'Not available',
          showArrow: true,
          onTap: () => _showUnavailable('Address'),
          isLast: true,
        ),
      ],
    );
  }

  String _formatPhone(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'Not available';

    // Prevent duplicate +91 prefix.
    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+91 ${digits.substring(2)}';
    }

    if (digits.length == 10) {
      return '+91 $digits';
    }

    return cleaned;
  }

  Widget _buildAccountInformation() {
    return _sectionCard(
      children: [
        _infoRow(
          Icons.verified_user_outlined,
          'Account Status',
          'Signed in',
          showArrow: false,
          trailing: _statusBadge(),
        ),
        _infoRow(
          Icons.badge_outlined,
          'Account Role',
          role,
          showArrow: false,
          trailing: _roleBadge(),
        ),
        _infoRow(
          Icons.calendar_month_outlined,
          'Member Since',
          'Not available',
          showArrow: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2DF),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF399B48), size: 17),
          SizedBox(width: 6),
          Text(
            'Signed in',
            style: TextStyle(
              color: Color(0xFF247A4B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5C9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFF482A12),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _sectionCard(
      children: [
        _securityRow(
          Icons.mark_email_read_outlined,
          'Change Email',
          'Update your email address (OTP verification)',
          onTap: () => _showUnavailable('Change Email'),
        ),
        _securityRow(
          Icons.phonelink_lock_outlined,
          'Change Phone Number',
          'Update your mobile number (OTP verification)',
          onTap: () => _showUnavailable('Change Phone Number'),
        ),
        _securityRow(
          Icons.devices_outlined,
          'Active Sessions',
          'Manage devices where your account is logged in',
          onTap: () => _showUnavailable('Active Sessions'),
          isLast: true,
        ),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
      IconData icon,
      String label,
      String value, {
        VoidCallback? onTap,
        bool showArrow = true,
        Widget? trailing,
        bool isLast = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF555160),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: trailing ??
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0xFF301039),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right,
                color: primary,
                size: 25,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _securityRow(
      IconData icon,
      String title,
      String subtitle, {
        VoidCallback? onTap,
        bool isLast = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF301039),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF555160),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: primary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 48,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EAF3),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: primary,
        size: 24,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(),
        icon: const Icon(Icons.logout, color: Colors.red, size: 25),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF0F0),
          side: const BorderSide(color: Color(0xFFF2D0D0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onLogout();
    }
  }
}
