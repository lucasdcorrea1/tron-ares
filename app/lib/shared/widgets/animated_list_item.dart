import 'package:flutter/material.dart';

/// Widget that animates list items with staggered fade + slide animation
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start animation after staggered delay
    final delay = widget.delayPerItem * widget.index;
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
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
        child: widget.child,
      ),
    );
  }
}

/// A ListView builder with staggered animation
class AnimatedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int)? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Duration delayPerItem;
  final Duration itemDuration;

  const AnimatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.delayPerItem = const Duration(milliseconds: 40),
    this.itemDuration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder!,
        itemBuilder: (context, index) {
          return AnimatedListItem(
            index: index,
            delayPerItem: delayPerItem,
            duration: itemDuration,
            child: itemBuilder(context, index),
          );
        },
      );
    }

    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          delayPerItem: delayPerItem,
          duration: itemDuration,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// Wrapper for Column with staggered animation for its children
class AnimatedColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration delayPerItem;
  final Duration itemDuration;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AnimatedColumn({
    super.key,
    required this.children,
    this.delayPerItem = const Duration(milliseconds: 60),
    this.itemDuration = const Duration(milliseconds: 250),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        return AnimatedListItem(
          index: entry.key,
          delayPerItem: delayPerItem,
          duration: itemDuration,
          child: entry.value,
        );
      }).toList(),
    );
  }
}
