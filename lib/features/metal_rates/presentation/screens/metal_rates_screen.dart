import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../services/api_client.dart';
import '../../../../services/cache_service.dart';

class MetalRatesScreen extends StatefulWidget {
  const MetalRatesScreen({super.key});

  @override
  State<MetalRatesScreen> createState() => _MetalRatesScreenState();
}

class _MetalRatesScreenState extends State<MetalRatesScreen> {
  DateTime? _lastUpdated;
  bool _loading = false;
  bool _hasError = false;

  Map<String, dynamic>? _gold;
  Map<String, dynamic>? _silver;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  String get _formattedDate {
    final date = _lastUpdated;

    if (date == null) return 'Not updated yet';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<Map<String, dynamic>> _fetchMetal(String metal) async {
    final endpoint = metal == 'gold'
        ? ApiConfig.goldRatesUrl
        : ApiConfig.silverRatesUrl;

    debugPrint('[$metal] Fetching URL: $endpoint');

    final response = await ApiClient.instance.get(
      Uri.parse(endpoint),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$metal rates request failed '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response format');
    }

    final rates = decoded['rates'];

    if (rates is! List || rates.isEmpty) {
      throw FormatException('No $metal rates found in API response');
    }

    return decoded;
  }

  Future<void> _loadRates() async {
    if (_loading) return;

    // 1. Load cached metal rates if available
    final cachedGold = await CacheService.instance.getCacheData('cache_metal_gold');
    final cachedSilver = await CacheService.instance.getCacheData('cache_metal_silver');
    final timestamp = await CacheService.instance.getCacheTimestamp('cache_metal_gold');

    if (cachedGold != null || cachedSilver != null) {
      if (mounted) {
        setState(() {
          if (cachedGold is Map<String, dynamic>) _gold = cachedGold;
          if (cachedSilver is Map<String, dynamic>) _silver = cachedSilver;
          if (timestamp != null) _lastUpdated = timestamp;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }
    }

    // 2. Fetch fresh metal rates from backend
    Map<String, dynamic>? goldResult;
    Map<String, dynamic>? silverResult;

    try {
      goldResult = await _fetchMetal('gold');
      await CacheService.instance.saveCache('cache_metal_gold', goldResult);
      debugPrint('GOLD API: success');
    } catch (error) {
      debugPrint('GOLD API ERROR: $error');
    }

    try {
      silverResult = await _fetchMetal('silver');
      await CacheService.instance.saveCache('cache_metal_silver', silverResult);
      debugPrint('SILVER API: success');
    } catch (error) {
      debugPrint('SILVER API ERROR: $error');
    }

    if (!mounted) return;

    setState(() {
      if (goldResult != null) _gold = goldResult;
      if (silverResult != null) _silver = silverResult;

      _hasError = (goldResult == null && _gold == null) ||
          (silverResult == null && _silver == null);

      if (goldResult != null || silverResult != null) {
        _lastUpdated = DateTime.now();
      }

      _loading = false;
    });
  }

  Future<void> _refreshRates() async {
    await _loadRates();
  }

  String _money(dynamic value) {
    if (value is! num) return '—';

    final rounded = value.round().toString();
    final out = StringBuffer();

    for (int i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) {
        out.write(',');
      }

      out.write(rounded[i]);
    }

    return '₹ ${out.toString()}';
  }

  List<Map<String, dynamic>> _rateRecords(Map<String, dynamic>? metal) {
    final rates = metal?['rates'];

    if (rates is! List) {
      return [];
    }

    return rates
        .whereType<Map>()
        .map((rate) => Map<String, dynamic>.from(rate))
        .toList();
  }

  Map<String, dynamic>? _rateForKarat(String karat) {
    for (final rate in _rateRecords(_gold)) {
      if (rate['karat']?.toString().toUpperCase() == karat.toUpperCase()) {
        return rate;
      }
    }

    return null;
  }

  String _mainGoldPrice() {
    final rate = _rateForKarat('24K');
    return _money(rate?['price_per_gram']);
  }

  String _mainSilverPrice() {
    final rates = _rateRecords(_silver);

    if (rates.isEmpty) return '—';

    return _money(rates.first['price_per_gram']);
  }

  List<_PurityRate> _goldPurities() {
    const purities = [
      ('24K', '24K (999)'),
      ('22K', '22K (916)'),
      ('18K', '18K (750)'),
    ];

    return purities.map((purity) {
      final rate = _rateForKarat(purity.$1);

      return _PurityRate(purity.$2, _money(rate?['price_per_gram']), '/g');
    }).toList();
  }

  List<_PurityRate> _silverPurities() {
    final rates = _rateRecords(_silver);

    if (rates.isEmpty) {
      return const [_PurityRate('999', '—', '/g')];
    }

    final first = rates.first;

    final purity =
        first['purity']?.toString() ?? first['fineness']?.toString() ?? '999';

    return [_PurityRate(purity, _money(first['price_per_gram']), '/g')];
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
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
            onPressed: _loading ? null : _refreshRates,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading && _gold == null && _silver == null
            ? const SkeletonMetalRates()
            : SingleChildScrollView(
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
                                color: _hasError
                                    ? const Color(0xFFFCE8E6)
                                    : const Color(0xFFE2F5E8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: _hasError
                                        ? const Color(0xFFB42318)
                                        : AppColors.success,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _hasError
                                        ? 'Unavailable'
                                        : (_loading ? 'Updating' : 'Live'),
                                    style: TextStyle(
                                      color: _hasError
                                          ? const Color(0xFFB42318)
                                          : AppColors.success,
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

                        _MetalRateCard(
                          title: 'Gold',
                          icon: Icons.diamond_rounded,
                          iconColor: const Color(0xFFE3A000),
                          rate: _mainGoldPrice(),
                          unit: '/g',
                          rates: _goldPurities(),
                        ),

                        const SizedBox(height: 14),

                        _MetalRateCard(
                          title: 'Silver',
                          icon: Icons.diamond_rounded,
                          iconColor: const Color(0xFF92969D),
                          rate: _mainSilverPrice(),
                          unit: '/g',
                          rates: _silverPurities(),
                        ),

                        const SizedBox(height: 14),

                        const _MetalRateCard(
                          title: 'Diamond',
                          icon: Icons.diamond_outlined,
                          iconColor: Color(0xFF1595ED),
                          rate: '—',
                          unit: '/ct',
                          rates: [
                            _PurityRate('Natural', '—', '/ct'),
                            _PurityRate('Lab Grown', '—', '/ct'),
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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
                child: Icon(icon, color: iconColor, size: 39),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.roleTitle),
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
                    style: const TextStyle(color: AppColors.body, fontSize: 13),
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
                  style: const TextStyle(color: AppColors.body, fontSize: 12),
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
  const _PurityRate(this.label, this.amount, this.unit);

  final String label;
  final String amount;
  final String unit;
}
