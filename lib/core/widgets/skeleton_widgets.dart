import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF0E9E0),
    this.highlightColor = Colors.white,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9E0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.height = 80,
    this.padding = const EdgeInsets.all(14),
  });

  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D9)),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, borderRadius: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 120, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: double.infinity, height: 140, borderRadius: 18),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: SkeletonBox(height: 90, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 90, borderRadius: 14)),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(width: 140, height: 18),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => const SkeletonCard(height: 70),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonCustomerDetails extends StatelessWidget {
  const SkeletonCustomerDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SkeletonCard(height: 90),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
            ],
          ),
          const SizedBox(height: 18),
          const SkeletonBox(width: double.infinity, height: 38, borderRadius: 10),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => const SkeletonCard(height: 65),
          ),
        ],
      ),
    );
  }
}

class SkeletonTransactionList extends StatelessWidget {
  const SkeletonTransactionList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => const SkeletonCard(height: 68),
      ),
    );
  }
}

class SkeletonItemsList extends StatelessWidget {
  const SkeletonItemsList({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => const SkeletonCard(height: 80),
      ),
    );
  }
}

class SkeletonMetalRates extends StatelessWidget {
  const SkeletonMetalRates({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SkeletonBox(width: double.infinity, height: 32, borderRadius: 16),
            const SizedBox(height: 18),
            const SkeletonCard(height: 150),
            const SizedBox(height: 14),
            const SkeletonCard(height: 130),
            const SizedBox(height: 14),
            const SkeletonCard(height: 110),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.lastUpdated});
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: const Color(0xFFFFF3CD),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 15, color: Color(0xFF856404)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastUpdated != null
                  ? 'Offline Mode • Cached data ($lastUpdated)'
                  : 'Offline Mode • Displaying cached data',
              style: const TextStyle(fontSize: 12, color: Color(0xFF856404), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
