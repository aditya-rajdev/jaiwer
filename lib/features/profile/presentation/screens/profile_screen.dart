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
  String address = 'Not available';

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
      final storedAddress = await _storage.read(key: 'shop_address');

      if (!mounted) return;

      setState(() {
        name = storedName?.trim().isNotEmpty == true
            ? storedName!.trim()
            : 'User';

        email = storedEmail?.trim().isNotEmpty == true ? storedEmail!.trim() : '';
        phone = storedPhone?.trim().isNotEmpty == true ? storedPhone!.trim() : '';
        role = _formatRole(storedRole);
        shopName = storedShop?.trim().isNotEmpty == true
            ? storedShop!.trim()
            : 'JAIWER Member';
        address = storedAddress?.trim().isNotEmpty == true
            ? storedAddress!.trim()
            : 'Not available';

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

  String _formatPhone(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'Not available';

    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+91 ${digits.substring(2)}';
    }

    if (digits.length == 10) {
      return '+91 $digits';
    }

    return cleaned;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF247A4B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openEditProfileSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: name);
    final emailCtrl = TextEditingController(text: email);
    final phoneCtrl = TextEditingController(text: phone.replaceAll(RegExp(r'^\+91\s*'), ''));
    final addressCtrl = TextEditingController(text: address == 'Not available' ? '' : address);

    bool isSaving = false;

    Future<bool> onWillPop(BuildContext ctx) async {
      final nameChanged = nameCtrl.text.trim() != name;
      final emailChanged = emailCtrl.text.trim() != email;
      final phoneCleaned = phone.replaceAll(RegExp(r'^\+91\s*'), '');
      final phoneChanged = phoneCtrl.text.trim() != phoneCleaned;
      final addressCleaned = address == 'Not available' ? '' : address;
      final addressChanged = addressCtrl.text.trim() != addressCleaned;

      if (nameChanged || emailChanged || phoneChanged || addressChanged) {
        final confirm = await showDialog<bool>(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            backgroundColor: background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Unsaved Changes', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: const Text('Keep Editing', style: TextStyle(color: Color(0xFF555160))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                child: const Text('Discard', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return confirm ?? false;
      }
      return true;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await onWillPop(sheetContext);
            if (shouldPop && sheetContext.mounted) {
              Navigator.pop(sheetContext, false);
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: background,
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
                            'Edit Profile',
                            style: TextStyle(
                              color: primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final shouldPop = await onWillPop(sheetContext);
                              if (shouldPop && sheetContext.mounted) {
                                Navigator.pop(sheetContext, false);
                              }
                            },
                            icon: const Icon(Icons.close_rounded, color: primary),
                          ),
                        ],
                      ),
                      const Divider(color: borderColor),
                      const SizedBox(height: 12),

                      // Full Name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: const Icon(Icons.person_outline, color: primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email Address
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          helperText: 'Changing email requires OTP verification',
                          prefixIcon: const Icon(Icons.email_outlined, color: primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email Address is required';
                          final isValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim());
                          if (!isValid) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone Number
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '10-digit number',
                          prefixText: '+91 ',
                          prefixIcon: const Icon(Icons.phone_outlined, color: primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final digits = v.replaceAll(RegExp(r'\D'), '');
                            if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Address
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Action Buttons: Save & Cancel
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () async {
                                final shouldPop = await onWillPop(sheetContext);
                                if (shouldPop && sheetContext.mounted) {
                                  Navigator.pop(sheetContext, false);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isSaving ? null : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);

                                final newName = nameCtrl.text.trim();
                                final newEmail = emailCtrl.text.trim();
                                final newPhone = phoneCtrl.text.trim().isNotEmpty
                                    ? '+91${phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '')}'
                                    : '';
                                final newAddress = addressCtrl.text.trim();

                                if (newEmail != email) {
                                  final otpVerified =
                                  await _openEmailOtpVerificationDialog(
                                    newEmail: newEmail,
                                  );

                                  if (!otpVerified) {
                                    setSheetState(() => isSaving = false);
                                    return;
                                  }

                                  await _storage.write(key: 'user_email', value: newEmail);
                                }

                                await _storage.write(key: 'user_name', value: newName);
                                if (newPhone.isNotEmpty) {
                                  await _storage.write(key: 'user_phone', value: newPhone);
                                }
                                if (newAddress.isNotEmpty) {
                                  await _storage.write(key: 'shop_address', value: newAddress);
                                }

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext, true);
                                }
                              },
                              icon: isSaving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: Text(
                                isSaving ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadProfile();
      _showMessage('Profile updated successfully!');
    }
  }

  Future<bool> _openEmailOtpVerificationDialog({
    required String newEmail,
  }) async {
    final otpCtrl = TextEditingController();
    String? errorText;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Email OTP Verification', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter 6-digit OTP sent to $newEmail.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF555160)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Email OTP verification must be connected to the backend. '
                      'A test OTP is not accepted.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A5A00),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF555160))),
            ),
            ElevatedButton(
              onPressed: () {
                setDialogState(() {
                  errorText =
                  'OTP verification API is not connected yet. '
                      'Email has not been changed.';
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: const Text('Verify Email', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    otpCtrl.dispose();
    return verified ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _openEditProfileSheet,
            icon: const Icon(Icons.edit_outlined, color: primary, size: 18),
            label: const Text('Edit', style: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: primary),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Stack(
        children: [
          const Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.diamond_outlined,
              color: Color(0x18FFFFFF),
              size: 85,
            ),
          ),
          Row(
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  border: Border.all(color: gold, width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD98B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 15,
                            color: primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            role,
                            style: const TextStyle(
                              color: Color(0xFF482A12),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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
        ),
        _infoRow(
          Icons.email_outlined,
          'Email Address',
          email.isEmpty ? 'Not available' : email,
        ),
        _infoRow(
          Icons.phone_outlined,
          'Phone Number',
          phone.isEmpty ? 'Not available' : _formatPhone(phone),
        ),
        _infoRow(
          Icons.location_on_outlined,
          'Address',
          address,
          showArrow: true,
          isLast: true,
        ),
      ],
    );
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
          'Active Account',
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
        ),
        _securityRow(
          Icons.phonelink_lock_outlined,
          'Change Phone Number',
          'Update your mobile number (OTP verification)',
        ),
        _securityRow(
          Icons.devices_outlined,
          'Active Sessions',
          'Manage devices where your account is logged in',
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
        bool showArrow = true,
        Widget? trailing,
        bool isLast = false,
      }) {
    return Container(
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
                    fontSize: 14,
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
    );
  }

  Widget _securityRow(
      IconData icon,
      String title,
      String subtitle, {
        bool isLast = false,
      }) {
    return Container(
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
