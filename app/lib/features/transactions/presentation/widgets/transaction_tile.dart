import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction_entity.dart';

/// Widget to display a single transaction in a list with animations
class TransactionTile extends StatefulWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategoryExtension.fromString(widget.transaction.category);
    final isIncome = widget.transaction.type == TransactionType.income;
    final categoryColor = Color(category.colorValue);

    return Dismissible(
      key: Key(widget.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      confirmDismiss: (direction) async {
        if (widget.onDelete != null) {
          widget.onDelete!();
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _isPressed
                  ? AppColors.surfaceDark
                  : AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _isPressed
                    ? AppColors.divider
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Category icon - neutral background with colored icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Description and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transaction.description,
                        style: AppTypography.titleSmall(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatRelative(widget.transaction.date),
                        style: AppTypography.bodySmall(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatBRL(widget.transaction.amount)}',
                  style: AppTypography.currencySmall(
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
