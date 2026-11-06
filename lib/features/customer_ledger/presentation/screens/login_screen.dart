import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api_client.dart';
import '../../../../services/toast_service.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  static const _baseUrl = 'https://jaiwer-backend.onrender.com';
  static const _purple = Color(0xFF35113F);
  static const _gold = Color(0xFFD2A04A);
  static const _cream = Color(0xFFFFFCF7);
  static const _muted = Color(0xFF77717D);
  bool _otpRequested = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 25));

    debugPrint('$path STATUS: ${response.statusCode}');
    debugPrint('$path RESPONSE: ${response.body}');
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception((data['detail'] ?? data['message'] ??
          'Request failed (${response.statusCode}).').toString());
    }
    return data;
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final data = await _post('/auth/login', {
        'email': _emailController.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
        _otpController.clear();
      });
      _message(data['message']?.toString() ??
          'If an account exists, a login code has been sent.');
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final token = _otpController.text.trim();
    if (!RegExp(r'^[0-9]{8}$').hasMatch(token)) {
      _message('Enter the complete 8-digit login code.');
      return;
    }
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final data = await _post('/auth/verify-otp', {
        'email': _emailController.text.trim(),
        'token': token,
      });
      final accessToken = data['access_token']?.toString();
      final refreshToken = data['refresh_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('API response did not include an access token.');
      }
      // Save the actual profile returned by the backend for the drawer.
      final profile = data['profile'] is Map
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : <String, dynamic>{};
      final name = profile['name'] ?? data['name'];
      final email = profile['email'] ?? data['email'] ?? _emailController.text.trim();
      final phone = profile['phone_number'] ?? data['phone_number'];
      final accountType = profile['account_type'] ?? data['account_type'];
      final userId = profile['user_id'] ?? data['user_id'];
      final ownerReferenceId = profile['owner_reference_id'] ?? data['owner_reference_id'];
      final shopName = profile['shop_name'] ?? data['shop_name'];

      final profileMap = <String, String>{};
      if (name != null) profileMap['user_name'] = name.toString();
      if (email != null) profileMap['user_email'] = email.toString();
      if (phone != null) profileMap['user_phone'] = phone.toString();
      if (accountType != null) profileMap['account_type'] = accountType.toString();
      if (userId != null) profileMap['user_id'] = userId.toString();
      if (ownerReferenceId != null) profileMap['owner_reference_id'] = ownerReferenceId.toString();
      if (shopName != null) profileMap['shop_name'] = shopName.toString();

      final saved = await ApiClient.instance.saveAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: data['token_type']?.toString(),
        userProfile: profileMap,
      );

      if (!saved) {
        if (!mounted) return;
        _message('Session could not be established. Please try logging in again.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardScreen()),
            (route) => false,
      );
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String value) {
    if (value.toLowerCase().contains('invalid') || value.toLowerCase().contains('error') || value.toLowerCase().contains('expired')) {
      ToastService.instance.showError(value);
    } else {
      ToastService.instance.showInfo(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _purple),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _otpRequested ? _otpForm() : _emailForm(),
              ),
              const SizedBox(height: 28),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 15, color: _muted),
                    SizedBox(width: 8),
                    Text('Your data is secure and protected',
                        style: TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailForm() => Form(
    key: _formKey,
    child: Column(
      key: const ValueKey('email-form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome Back', style: TextStyle(color: _purple, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Sign in with the email linked to your JewelSetu account.',
            style: TextStyle(color: _muted, fontSize: 15)),
        const SizedBox(height: 28),
        const Text('Email Address', style: TextStyle(color: _purple, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration('Enter your registered email', Icons.mail_outline),
          validator: (value) {
            final email = value?.trim() ?? '';
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                ? null : 'Enter a valid email address';
          },
        ),
        const SizedBox(height: 28),
        _button(_loading ? 'Sending code...' : 'Send Login Code', _loading ? null : _requestCode),
      ],
    ),
  );

  Widget _otpForm() => Column(
    key: const ValueKey('otp-form'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Center(child: Icon(Icons.mark_email_read_outlined, size: 72, color: _gold)),
      const SizedBox(height: 20),
      const Center(child: Text('Verify Login Code',
          style: TextStyle(color: _purple, fontSize: 27, fontWeight: FontWeight.bold))),
      const SizedBox(height: 10),
      const Text('Enter the 8-digit code sent to your registered email.',
          textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 15)),
      const SizedBox(height: 12),
      Center(child: Text(_emailController.text.trim(),
          style: const TextStyle(color: _purple, fontWeight: FontWeight.w600))),
      const SizedBox(height: 28),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 8,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _purple, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
        decoration: InputDecoration(
          counterText: '',
          hintText: '••••••••',
          hintStyle: const TextStyle(color: Color(0xFFC9BECF), letterSpacing: 8),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E0E8))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E0E8))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
        ),
      ),
      const SizedBox(height: 12),
      _button(_loading ? 'Verifying...' : 'Verify & Sign In', _loading ? null : _verifyCode),
      Center(
        child: TextButton(
          onPressed: _loading ? null : () => setState(() {
            _otpRequested = false;
            _otpController.clear();
          }),
          child: const Text('Use a different email', style: TextStyle(color: _purple)),
        ),
      ),
    ],
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA39BA7), fontSize: 14),
    prefixIcon: Icon(icon, color: _purple, size: 21),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E0E8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E0E8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _purple, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent)),
  );

  Widget _button(String label, VoidCallback? onPressed) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _purple.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}