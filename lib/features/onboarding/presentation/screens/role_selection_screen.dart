
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/screens/temporary_signup_screen.dart';
import 'language_selection_screen.dart';

enum UserRole { shopOwner, worker }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;
  String _selectedLanguage = 'English';

  Future<void> _openLanguageSelection() async {
    final language = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const LanguageSelectionScreen(),
      ),
    );

    if (!mounted || language == null) return;

    setState(() {
      _selectedLanguage = language;
    });
  }

  void _continue() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role to continue.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TemporarySignupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openLanguageSelection,
                      icon: const Icon(Icons.language),
                      label: Text(_selectedLanguage),
                    ),
                  ),

                  Center(
                    child: Image.asset(
                      'assets/images/jewelsetu_logo.png',
                      width: 500,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.diamond_outlined,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Choose your role',
                    style: AppTextStyles.sectionHeading,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Select how you want to use JewelSetu.',
                    style: AppTextStyles.body,
                  ),

                  const SizedBox(height: 20),

                  _RoleCard(
                    title: 'Shop Owner',
                    description:
                    'Manage your shop, customers, accounts and workers.',
                    icon: Icons.storefront_outlined,
                    selected: _selectedRole == UserRole.shopOwner,
                    onTap: () {
                      setState(() {
                        _selectedRole = UserRole.shopOwner;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _RoleCard(
                    title: 'Worker',
                    description:
                    'Access shop tasks and records permitted by the owner.',
                    icon: Icons.badge_outlined,
                    selected: _selectedRole == UserRole.worker,
                    onTap: () {
                      setState(() {
                        _selectedRole = UserRole.worker;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: const Text('Continue'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'Secure records. Smarter shop management.',
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
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.selectedBackground
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.selectedBorder
                  : AppColors.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.gold
                      : AppColors.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.roleTitle,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? AppColors.primary
                    : AppColors.hint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
