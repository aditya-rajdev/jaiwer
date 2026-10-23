import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'English';

  final List<_LanguageOption> _languages = const [
    _LanguageOption(
      name: 'English',
      nativeName: 'English',
      subtitle: 'Continue in English',
    ),
    _LanguageOption(
      name: 'Hindi',
      nativeName: 'हिन्दी',
      subtitle: 'हिन्दी में जारी रखें',
    ),
  ];

  void _continue() {
    Navigator.of(context).pop(_selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choose Language')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Icon(
                      Icons.language_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select your language',
                    style: AppTextStyles.welcomeHeading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the language you are comfortable using.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 28),
                  ..._languages.map(
                    (language) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _LanguageCard(
                        language: language,
                        selected: _selectedLanguage == language.name,
                        onTap: () {
                          setState(() {
                            _selectedLanguage = language.name;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: const Text('Continue'),
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

class _LanguageOption {
  const _LanguageOption({
    required this.name,
    required this.nativeName,
    required this.subtitle,
  });

  final String name;
  final String nativeName;
  final String subtitle;
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedBackground : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.selectedBorder : AppColors.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.nativeName, style: AppTextStyles.roleTitle),
                    const SizedBox(height: 5),
                    Text(language.subtitle, style: AppTextStyles.body),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.hint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
