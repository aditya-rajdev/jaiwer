import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../customer_ledger/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';


class TemporarySignupScreen extends StatefulWidget {
  const TemporarySignupScreen({super.key});

  @override
  State<TemporarySignupScreen> createState() =>
      _TemporarySignupScreenState();
}

class _TemporarySignupScreenState extends State<TemporarySignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _showOtpScreen = false;
  bool _isRegistering = false;
  bool _isVerifying = false;

  static const String _baseUrl = 'https://jaiwer-backend.onrender.com';
  static const String _registerUrl = '$_baseUrl/auth/register';
  static const String _verifyOtpUrl = '$_baseUrl/auth/verify-otp';

  static const Color _purple = Color(0xFF35113F);
  static const Color _gold = Color(0xFFD2A04A);
  static const Color _cream = Color(0xFFFFFCF7);
  static const Color _muted = Color(0xFF77717D);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _continueToOtp() async {
    if (!_formKey.currentState!.validate() || _isRegistering) return;

    FocusScope.of(context).unfocus();
    setState(() => _isRegistering = true);

    try {
      final response = await http
          .post(
        Uri.parse(_registerUrl),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': '+91${_phoneController.text.trim()}',
        }),
      )
          .timeout(const Duration(seconds: 25));

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = null;
      }

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _showOtpScreen = true;
          _otpController.clear();
        });
        final message = data is Map
            ? (data['message'] ?? 'Registration successful. Enter your OTP.')
            .toString()
            : 'Registration successful. Enter your OTP.';
        _showTemporaryMessage(message);
      } else {
        final message = data is Map
            ? (data['detail'] ?? data['message'] ??
            'Registration failed (${response.statusCode}).')
            .toString()
            : 'Registration failed (${response.statusCode}).';
        _showTemporaryMessage(message);
      }
    } on Exception {
      if (mounted) {
        _showTemporaryMessage(
          'Could not connect to registration server. Check internet and server URL.',
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    FocusScope.of(context).unfocus();
    final otp = _otpController.text.trim();

    if (!RegExp(r'^[0-9]{8}$').hasMatch(otp)) {
      _showTemporaryMessage('Please enter the complete 8-digit OTP.');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await http
          .post(
        Uri.parse(_verifyOtpUrl),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'token': otp,
        }),
      )
          .timeout(const Duration(seconds: 25));

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = null;
      }

      debugPrint('OTP VERIFY STATUS: ${response.statusCode}');
      debugPrint('OTP VERIFY RESPONSE: ${response.body}');

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is! Map) {
          throw Exception('Unexpected OTP verification response.');
        }

        final responseData = Map<String, dynamic>.from(data as Map);
        final accessToken = responseData['access_token']?.toString();
        final refreshToken = responseData['refresh_token']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('Verification succeeded but access token was missing.');
        }

        const storage = FlutterSecureStorage();
        await storage.write(key: 'access_token', value: accessToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await storage.write(key: 'refresh_token', value: refreshToken);
        }
        if (responseData['token_type'] != null) {
          await storage.write(key: 'token_type', value: responseData['token_type'].toString());
        }

        final profile = responseData['profile'] is Map
            ? Map<String, dynamic>.from(responseData['profile'] as Map)
            : <String, dynamic>{};
        final name = profile['name'] ?? responseData['name'] ?? _nameController.text.trim();
        final email = profile['email'] ?? responseData['email'] ?? _emailController.text.trim();
        final phone = profile['phone_number'] ?? responseData['phone_number'];
        final accountType = profile['account_type'] ?? responseData['account_type'];
        final userId = profile['user_id'] ?? responseData['user_id'];
        final ownerReferenceId = profile['owner_reference_id'] ?? responseData['owner_reference_id'];
        final shopName = profile['shop_name'] ?? responseData['shop_name'];

        if (name.toString().trim().isNotEmpty) {
          await storage.write(key: 'user_name', value: name.toString());
        }
        if (email.toString().trim().isNotEmpty) {
          await storage.write(key: 'user_email', value: email.toString());
        }
        if (phone != null && phone.toString().trim().isNotEmpty) {
          await storage.write(key: 'user_phone', value: phone.toString());
        }
        if (accountType != null && accountType.toString().trim().isNotEmpty) {
          await storage.write(key: 'account_type', value: accountType.toString());
        }
        if (userId != null && userId.toString().trim().isNotEmpty) {
          await storage.write(key: 'user_id', value: userId.toString());
        }
        if (ownerReferenceId != null && ownerReferenceId.toString().trim().isNotEmpty) {
          await storage.write(key: 'owner_reference_id', value: ownerReferenceId.toString());
        }
        if (shopName != null && shopName.toString().trim().isNotEmpty) {
          await storage.write(key: 'shop_name', value: shopName.toString());
        }

        final message = (responseData['message'] ?? 'OTP verified successfully.').toString();
        _showTemporaryMessage(message);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
              (route) => false,
        );
      } else {
        final message = data is Map
            ? (data['detail'] ??
            data['message'] ??
            'OTP verification failed (${response.statusCode}).')
            .toString()
            : 'OTP verification failed (${response.statusCode}).';
        _showTemporaryMessage(message);
      }
    } on Exception catch (e) {
      debugPrint('OTP VERIFY ERROR: $e');
      if (mounted) {
        _showTemporaryMessage(
          'Could not connect to OTP verification server. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showTemporaryMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_showOtpScreen) {
                        setState(() {
                          _showOtpScreen = false;
                        });
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _purple,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE8E0E8)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.language, size: 17, color: _purple),
                        SizedBox(width: 6),
                        Text(
                          'English',
                          style: TextStyle(
                            color: _purple,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16, color: _purple),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'JAIWER',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: _purple,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showOtpScreen
                    ? _buildOtpContent()
                    : _buildSignupContent(),
              ),

              const SizedBox(height: 28),

              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 15, color: _muted),
                    SizedBox(width: 8),
                    Text(
                      'Your data is secure and protected',
                      style: TextStyle(
                        fontSize: 12,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupContent() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('signup'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Your Account',
            style: TextStyle(
              color: _purple,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your details to continue',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 28),

          _buildField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          _buildField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter 10-digit phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 17)),
                  SizedBox(width: 6),
                  Text(
                    '+91',
                    style: TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('|', style: TextStyle(color: Color(0xFFDAD2DA))),
                ],
              ),
            ),
            validator: (value) {
              final phone = value?.trim() ?? '';
              if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                return 'Enter a valid 10-digit phone number';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          _buildField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email address',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(email)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          _primaryButton(
            label: _isRegistering ? 'Registering...' : 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isRegistering ? null : _continueToOtp,
          ),

          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: _muted),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.bold,
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

  Widget _buildOtpContent() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 76,
            color: _gold,
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Verify OTP',
            style: TextStyle(
              color: _purple,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Enter the 8-digit OTP to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '+91 ${_phoneController.text.trim()}',
            style: const TextStyle(
              color: _purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _emailController.text.trim(),
            style: const TextStyle(color: _muted),
          ),
        ),
        const SizedBox(height: 28),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !_isVerifying,
          maxLength: 8,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _purple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••••',
            hintStyle: const TextStyle(
              color: Color(0xFFC9BECF),
              letterSpacing: 7,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E0E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E0E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _purple, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: _isRegistering || _isVerifying
                ? null
                : () {
              _otpController.clear();
              _showTemporaryMessage(
                'Resend OTP endpoint is not configured yet.',
              );
            },
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                color: _purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        _primaryButton(
          label: _isVerifying ? 'Verifying...' : 'Verify & Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _isVerifying ? null : _verifyOtp,
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _purple,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA39BA7),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: _purple, size: 21),
            prefix: prefix,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E0E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E0E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _purple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _purple.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}
