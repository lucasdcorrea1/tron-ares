import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Custom app bar for the Imperium app
class ImperiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showLogo;
  final List<Widget>? actions;

  const ImperiumAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showLogo = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : showLogo
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.imperiumGold,
                          AppColors.imperiumDarkGold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: AppColors.backgroundDark,
                      size: 20,
                    ),
                  ),
                )
              : null,
      title: showLogo
          ? Text(
              title.toUpperCase(),
              style: AppTypography.titleMedium(
                color: AppColors.imperiumGold,
              ).copyWith(letterSpacing: 3),
            )
          : Text(
              title,
              style: AppTypography.titleLarge(),
            ),
      actions: actions,
    );
  }
}
