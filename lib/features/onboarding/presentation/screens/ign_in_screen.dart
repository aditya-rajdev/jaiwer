
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.role,
  });

  final String role;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sign in will be connected to authentication next.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: AppColors.gold,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Welcome back!',
                      style: AppTextStyles.welcomeHeading,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Sign in to your JewelSetu account as ${widget.role}.',
                      style: AppTextStyles.body,
                    ),

                    const SizedBox(height: 30),

                    Text(
                      'Email or mobile number',
                      style: AppTextStyles.roleTitle,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Enter email or mobile number',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        final input = value?.trim() ?? '';

                        if (input.isEmpty) {
                          return 'Please enter your email or mobile number.';
                        }

                        final isEmail = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(input);

                        final isPhone = RegExp(
                          r'^\+?[0-9]{10,15}$',
                        ).hasMatch(input);

                        if (!isEmail && !isPhone) {
                          return 'Enter a valid email or mobile number.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Password',
                      style: AppTextStyles.roleTitle,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Sign In'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        'Your shop records, all in one place.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.helper,
                      ),
                    ),
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
