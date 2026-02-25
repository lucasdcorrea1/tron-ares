import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Base shimmer effect widget with animated gradient
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF2A2A4A),
                Color(0xFF3A3A5A),
                Color(0xFF2A2A4A),
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
              transform: _SlideGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlideGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Skeleton box for shimmer loading
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for the balance card
class BalanceCardSkeleton extends StatelessWidget {
  const BalanceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(
                  width: 42,
                  height: 42,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                const SkeletonBox(
                  width: 100,
                  height: 16,
                ),
                const Spacer(),
                SkeletonBox(
                  width: 80,
                  height: 28,
                  borderRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SkeletonBox(
              width: 180,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the monthly summary card
class MonthlySummarySkeleton extends StatelessWidget {
  const MonthlySummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SkeletonBox(width: 18, height: 18),
                SizedBox(width: 8),
                SkeletonBox(width: 120, height: 16),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _SummaryItemSkeleton()),
                const SizedBox(width: 16),
                Expanded(child: _SummaryItemSkeleton()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonBox(width: 34, height: 34, borderRadius: 10),
              SizedBox(width: 10),
              SkeletonBox(width: 60, height: 14),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(width: 90, height: 24),
        ],
      ),
    );
  }
}

/// Skeleton for transaction tile
class TransactionTileSkeleton extends StatelessWidget {
  const TransactionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            SkeletonBox(
              width: 48,
              height: 48,
              borderRadius: AppSpacing.radiusMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 16),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 80, height: 12),
                ],
              ),
            ),
            const SkeletonBox(width: 80, height: 18),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for quick actions
class QuickActionsSkeleton extends StatelessWidget {
  const QuickActionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Row(
        children: [
          Expanded(
            child: SkeletonBox(
              height: 52,
              borderRadius: AppSpacing.radiusMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SkeletonBox(
              height: 52,
              borderRadius: AppSpacing.radiusMd,
            ),
          ),
        ],
      ),
    );
  }
}

/// Complete home page skeleton
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BalanceCardSkeleton(),
          const SizedBox(height: AppSpacing.md),
          const MonthlySummarySkeleton(),
          const SizedBox(height: AppSpacing.lg),
          const QuickActionsSkeleton(),
          const SizedBox(height: AppSpacing.lg),
          // Section title skeleton
          ShimmerEffect(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 140, height: 18),
                SkeletonBox(width: 60, height: 14),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Transaction list skeleton
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TransactionTileSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Transactions page loading skeleton
class TransactionsLoadingSkeleton extends StatelessWidget {
  const TransactionsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips skeleton
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ShimmerEffect(
            child: Column(
              children: [
                Row(
                  children: const [
                    SkeletonBox(width: 60, height: 32, borderRadius: 16),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonBox(width: 100, height: 32, borderRadius: 16),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonBox(width: 90, height: 32, borderRadius: 16),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: const [
                    SkeletonBox(width: 50, height: 32, borderRadius: 16),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonBox(width: 70, height: 32, borderRadius: 16),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonBox(width: 70, height: 32, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Transaction list skeleton
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 10,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => const TransactionTileSkeleton(),
          ),
        ),
      ],
    );
  }
}
