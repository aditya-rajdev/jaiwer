import 'package:flutter/material.dart';

import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.role});

  final String role;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();

  bool _usePhone = true;
  String _countryCode = '+91';
  String _language = 'English';

  static const Color _purple = Color(0xFF2B1038);
  static const Color _gold = Color(0xFFD0A04B);
  static const Color _cream = Color(0xFFFFFCF7);
  static const Color _border = Color(0xFFE8E1D8);
  static const Color _muted = Color(0xFF77727A);

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
              const SizedBox(height: 16),
              for (final language in ['English', 'Hindi'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(language),
                  trailing: _language == language
                      ? const Icon(Icons.check_circle, color: _purple)
                      : null,
                  onTap: () => Navigator.pop(context, language),
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;

    setState(() => _language = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Go back',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 21,
                            color: _purple,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _chooseLanguage,
                          icon: const Icon(Icons.language, size: 19),
                          label: Text(_language),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _purple,
                            side: const BorderSide(color: _border),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 64),

                    // Welcome heading — no logo image here.
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 42,
                          height: 1.12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Jewel',
                            style: TextStyle(color: _gold),
                          ),
                          TextSpan(
                            text: 'Setu',
                            style: TextStyle(color: _purple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your jewellery business, organised.',
                      style: TextStyle(fontSize: 17, color: _muted),
                    ),

                    const SizedBox(height: 54),

                    // Phone / Email switch
                    Container(
                      height: 54,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          _LoginTab(
                            title: 'Phone Number',
                            selected: _usePhone,
                            onTap: () {
                              setState(() {
                                _usePhone = true;
                                _inputController.clear();
                              });
                            },
                          ),
                          _LoginTab(
                            title: 'Email',
                            selected: !_usePhone,
                            onTap: () {
                              setState(() {
                                _usePhone = false;
                                _inputController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phone number field
                    if (_usePhone)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _countryCode,
                                items: const [
                                  DropdownMenuItem(
                                    value: '+91',
                                    child: Text('🇮🇳 +91'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+1',
                                    child: Text('🇺🇸 +1'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+44',
                                    child: Text('🇬🇧 +44'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+971',
                                    child: Text('🇦🇪 +971'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _countryCode = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _inputController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Enter phone number',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final phone = value?.trim() ?? '';

                                if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                                  return 'Enter a valid 10-digit number';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      TextFormField(
                        controller: _inputController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter email address',
                          prefixIcon: Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                      ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continue', style: TextStyle(fontSize: 19)),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    const Row(
                      children: [
                        Expanded(child: Divider(color: _border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: _muted)),
                        ),
                        Expanded(child: Divider(color: _border)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Google sign-in is not connected yet.',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _purple,
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 17, color: _muted),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Your data is secure and protected',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2B1038) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF29232D),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
