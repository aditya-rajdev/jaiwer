
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MetalRatesScreen extends StatefulWidget {
  const MetalRatesScreen({super.key});

  @override
  State<MetalRatesScreen> createState() => _MetalRatesScreenState();
}

class _MetalRatesScreenState extends State<MetalRatesScreen> {
  late DateTime _lastUpdated;

  @override
  void initState() {
    super.initState();
    _lastUpdated = DateTime.now();
  }

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final date = _lastUpdated;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} '
        '${date.year}, ${hour.toString().padLeft(2, '0')}:'
        '$minute $period';
  }

  void _refreshRates() {
    setState(() {
      _lastUpdated = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Display refreshed. Live market rate integration is pending.',
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 21,
          ),
        ),
        title: const Text(
          'Gold Rate',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh rates',
            onPressed: _refreshRates,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.body,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Last updated: $_formattedDate',
                              style: AppTextStyles.helper,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F5E8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Live',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const _MetalRateCard(
                        title: 'Gold',
                        icon: Icons.diamond_rounded,
                        iconColor: Color(0xFFE3A000),
                        rate: '₹ 12,635',
                        unit: '/g',
                        rates: [
                          _PurityRate('24K (999)', '₹ 12,635', '/g'),
                          _PurityRate('22K (916)', '₹ 11,580', '/g'),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const _MetalRateCard(
                        title: 'Silver',
                        icon: Icons.diamond_rounded,
                        iconColor: Color(0xFF92969D),
                        rate: '₹ 1,062',
                        unit: '/g',
                        rates: [
                          _PurityRate('999', '₹ 1,062', '/g'),
                          _PurityRate('925', '₹ 980', '/g'),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const _MetalRateCard(
                        title: 'Diamond',
                        icon: Icons.diamond_outlined,
                        iconColor: Color(0xFF1595ED),
                        rate: '₹ 12,635',
                        unit: '/ct',
                        rates: [
                          _PurityRate(
                            'Natural',
                            '₹ 12,635',
                            '/ct',
                          ),
                          _PurityRate(
                            'Lab Grown',
                            '₹ 8,450',
                            '/ct',
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EAFB),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF9476D9),
                              size: 21,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Rates are indicative market rates and may '
                                    'vary based on purity, making charges and '
                                    'local market conditions.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: AppColors.body,
                                ),
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
          },
        ),
      ),
    );
  }
}

class _MetalRateCard extends StatelessWidget {
  const _MetalRateCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.rate,
    required this.unit,
    required this.rates,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String rate;
  final String unit;
  final List<_PurityRate> rates;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.heading.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 39,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.roleTitle,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rate,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          unit,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 27,
                color: AppColors.primary,
              ),
            ],
          ),

          const SizedBox(height: 13),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 9),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Purity Wise Rates',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 5),

          for (int i = 0; i < rates.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    rates[i].label,
                    style: const TextStyle(
                      color: AppColors.body,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  rates[i].amount,
                  style: const TextStyle(
                    color: AppColors.heading,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  rates[i].unit,
                  style: const TextStyle(
                    color: AppColors.body,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PurityRate {
  const _PurityRate(
      this.label,
      this.amount,
      this.unit,
      );

  final String label;
  final String amount;
  final String unit;
}
