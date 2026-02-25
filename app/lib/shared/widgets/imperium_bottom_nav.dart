import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';

/// iOS-style floating bottom navigation bar
class ImperiumBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ImperiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<ImperiumBottomNav> createState() => _ImperiumBottomNavState();
}

class _ImperiumBottomNavState extends State<ImperiumBottomNav> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.homeTitle,
      ),
      _NavItemData(
        icon: Icons.swap_horiz_rounded,
        activeIcon: Icons.swap_horiz_rounded,
        label: l10n.transactionsTitle,
      ),
      _NavItemData(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: l10n.debtsTitle,
      ),
      _NavItemData(
        icon: Icons.smart_toy_outlined,
        activeIcon: Icons.smart_toy_rounded,
        label: 'TRON',
      ),
      _NavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l10n.settingsTitle,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: _getIndicatorPosition(widget.currentIndex, items.length),
                    top: 8,
                    child: Container(
                      width: _getItemWidth(items.length) - 16,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Nav items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(items.length, (index) {
                      return Expanded(
                        child: _NavItem(
                          data: items[index],
                          isSelected: widget.currentIndex == index,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onTap(index);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition(int index, int itemCount) {
    final screenWidth = MediaQuery.of(context).size.width - 32; // padding
    final itemWidth = screenWidth / itemCount;
    return (itemWidth * index) + 8;
  }

  double _getItemWidth(int itemCount) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    return screenWidth / itemCount;
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatefulWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          height: 70,
          child: Center(
            // Animated icon with bounce - no labels
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: widget.isSelected ? 0.0 : 1.0,
                end: widget.isSelected ? 1.0 : 0.0,
              ),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.15),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: widget.isSelected
                          ? AppColors.primaryGradient
                          : [AppColors.textMuted, AppColors.textMuted],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(
                      widget.isSelected ? widget.data.activeIcon : widget.data.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
