import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Welcome heading
  static const TextStyle welcomeHeading = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    color: AppColors.heading,
  );

  // Brand wordmark
  static const TextStyle wordmark = TextStyle(
    fontSize: 34,
    height: 42 / 34,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    letterSpacing: -0.8,
  );

  // Section heading
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
  );

  // Role card title
  static const TextStyle roleTitle = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.body,
  );

  // Input field text
  static const TextStyle input = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.heading,
  );

  // Primary button
  static const TextStyle button = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  // Helper and privacy text
  static const TextStyle helper = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.body,
  );
}
