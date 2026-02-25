import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class TronSidebar extends StatelessWidget {
  final String currentPath;

  const TronSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          right: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'TRON',
                    style: AppTypography.titleLarge(color: AppColors.primary),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => context.go('/home'),
                  tooltip: 'Voltar ao app',
                ),
              ],
            ),
          ),

          Divider(color: AppColors.divider, height: 1),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  path: '/tron/dashboard',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.view_kanban_rounded,
                  label: 'Kanban',
                  path: '/tron/kanban',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.smart_toy_rounded,
                  label: 'Agents',
                  path: '/tron/agents',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.gavel_rounded,
                  label: 'CIO Decisions',
                  path: '/tron/decisions',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.rule_rounded,
                  label: 'Directives',
                  path: '/tron/directives',
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Divider(color: AppColors.divider, height: 1),
                ),

                _buildNavItem(
                  context,
                  icon: Icons.analytics_rounded,
                  label: 'Metrics',
                  path: '/tron/metrics',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.terminal_rounded,
                  label: 'Logs',
                  path: '/tron/logs',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  path: '/tron/settings',
                ),
              ],
            ),
          ),

          // Status footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.income,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Agents Online',
                  style: AppTypography.labelSmall(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
  }) {
    final isSelected = currentPath.startsWith(path);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => context.go(path),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
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
