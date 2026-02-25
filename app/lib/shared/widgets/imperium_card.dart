import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Clean, minimal card with subtle press animation
class ImperiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool hasBorder;
  final Color? borderColor;

  const ImperiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.hasBorder = true,
    this.borderColor,
  });

  @override
  State<ImperiumCard> createState() => _ImperiumCardState();
}

class _ImperiumCardState extends State<ImperiumCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: widget.hasBorder
            ? Border.all(
                color: widget.borderColor ?? AppColors.divider,
                width: 1,
              )
            : null,
      ),
      transform: _isPressed
          ? (Matrix4.identity()..scale(0.98))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Gradient border card
class ImperiumGradientCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ImperiumGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  State<ImperiumGradientCard> createState() => _ImperiumGradientCardState();
}

class _ImperiumGradientCardState extends State<ImperiumGradientCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: _isPressed
          ? (Matrix4.identity()..scale(0.98))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Animated card with entrance animation
class AnimatedImperiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool hasBorder;
  final Duration delay;

  const AnimatedImperiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.hasBorder = true,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedImperiumCard> createState() => _AnimatedImperiumCardState();
}

class _AnimatedImperiumCardState extends State<AnimatedImperiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ImperiumCard(
          padding: widget.padding,
          onTap: widget.onTap,
          backgroundColor: widget.backgroundColor,
          hasBorder: widget.hasBorder,
          child: widget.child,
        ),
      ),
    );
  }
}
