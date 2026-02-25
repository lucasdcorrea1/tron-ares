import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_directive_model.dart';
import '../bloc/tron_directives_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronDirectivesPage extends StatefulWidget {
  const TronDirectivesPage({super.key});

  @override
  State<TronDirectivesPage> createState() => _TronDirectivesPageState();
}

class _TronDirectivesPageState extends State<TronDirectivesPage> {
  final _contentController = TextEditingController();
  String _selectedScope = 'global';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectState = context.read<TronProjectBloc>().state;
      final projectId = projectState.selectedProject?.id;
      if (projectId != null) {
        context.read<TronDirectivesBloc>().add(LoadDirectivesEvent(projectId));
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _createDirective() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final projectState = context.read<TronProjectBloc>().state;
    final projectId = projectState.selectedProject?.id;
    if (projectId == null) return;

    context.read<TronDirectivesBloc>().add(CreateDirectiveEvent(
          projectId: projectId,
          content: content,
          scope: _selectedScope,
        ));
    _contentController.clear();
  }

  void _deactivateDirective(String directiveId) {
    final projectState = context.read<TronProjectBloc>().state;
    final projectId = projectState.selectedProject?.id;
    if (projectId == null) return;

    context.read<TronDirectivesBloc>().add(DeactivateDirectiveEvent(
          projectId: projectId,
          directiveId: directiveId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Directives', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<TronDirectivesBloc, TronDirectivesState>(
        builder: (context, state) {
          if (state.isLoading && state.directives.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.error != null && state.directives.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.expense,
                    size: AppSpacing.iconXl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Failed to load directives',
                    style: AppTypography.titleMedium(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.error!,
                    style:
                        AppTypography.bodySmall(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      final projectId = context
                          .read<TronProjectBloc>()
                          .state
                          .selectedProject
                          ?.id;
                      if (projectId != null) {
                        context
                            .read<TronDirectivesBloc>()
                            .add(LoadDirectivesEvent(projectId));
                      }
                    },
                    child: Text(
                      'Retry',
                      style:
                          AppTypography.labelLarge(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          final active = state.activeDirectives;
          final inactive = state.inactiveDirectives;

          return Column(
            children: [
              // New directive input area
              _buildNewDirectiveInput(state),

              // Directives list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // Active directives header
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.sm,
                        top: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: AppColors.income,
                            size: AppSpacing.iconSm,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Active Directives',
                            style: AppTypography.titleSmall(
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            child: Text(
                              '${active.length}',
                              style: AppTypography.labelSmall(
                                  color: AppColors.income),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (active.isEmpty)
                      _buildEmptyState(
                        icon: Icons.lightbulb_outline,
                        message:
                            'No active directives. Create one above to guide your agents.',
                      ),

                    // Active directive cards
                    ...active.map((d) => _buildDirectiveCard(d, isActive: true)),

                    const SizedBox(height: AppSpacing.lg),

                    // Inactive directives section (expandable)
                    if (inactive.isNotEmpty)
                      _buildInactiveSection(inactive),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewDirectiveInput(TronDirectivesState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Directive',
            style: AppTypography.labelMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contentController,
            style: AppTypography.bodyMedium(color: AppColors.textPrimary),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Enter directive for agents...',
              hintStyle:
                  AppTypography.bodyMedium(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Scope selector
              _buildScopeChip('global', Icons.public),
              const SizedBox(width: AppSpacing.sm),
              _buildScopeChip('repo', Icons.folder),
              const SizedBox(width: AppSpacing.sm),
              _buildScopeChip('agent', Icons.smart_toy),
              const Spacer(),
              // Send button
              SizedBox(
                height: AppSpacing.buttonHeightSm,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _createDirective,
                  icon: state.isLoading
                      ? SizedBox(
                          width: AppSpacing.iconSm,
                          height: AppSpacing.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: Text(
                    'Send',
                    style: AppTypography.labelLarge(
                        color: AppColors.textPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip(String scope, IconData icon) {
    final isSelected = _selectedScope == scope;
    return GestureDetector(
      onTap: () => setState(() => _selectedScope = scope),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              scope[0].toUpperCase() + scope.substring(1),
              style: AppTypography.labelSmall(
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectiveCard(TronDirective directive,
      {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: scope badge + date + deactivate button
          Row(
            children: [
              _buildScopeBadge(directive.scope),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatDate(directive.createdAt),
                style: AppTypography.labelSmall(
                    color: AppColors.textMuted),
              ),
              const Spacer(),
              if (isActive)
                InkWell(
                  onTap: () => _deactivateDirective(directive.id),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          size: 14,
                          color: AppColors.expense,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Deactivate',
                          style: AppTypography.labelSmall(
                              color: AppColors.expense),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isActive && directive.deactivatedAt != null)
                Text(
                  'Deactivated ${_formatDate(directive.deactivatedAt!)}',
                  style:
                      AppTypography.labelSmall(color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Content
          Text(
            directive.content,
            style: AppTypography.bodyMedium(
              color: isActive
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
          if (directive.targetAgent != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.smart_toy,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Target: ${directive.targetAgent}',
                  style: AppTypography.labelSmall(
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScopeBadge(String scope) {
    Color badgeColor;
    IconData icon;

    switch (scope) {
      case 'global':
        badgeColor = AppColors.primary;
        icon = Icons.public;
        break;
      case 'repo':
        badgeColor = AppColors.info;
        icon = Icons.folder;
        break;
      case 'agent':
        badgeColor = AppColors.warning;
        icon = Icons.smart_toy;
        break;
      default:
        badgeColor = AppColors.textMuted;
        icon = Icons.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            scope[0].toUpperCase() + scope.substring(1),
            style: AppTypography.labelSmall(color: badgeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveSection(List<TronDirective> inactive) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showInactive = !_showInactive),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppColors.textMuted,
                  size: AppSpacing.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Inactive Directives',
                  style: AppTypography.titleSmall(
                      color: AppColors.textMuted),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.3),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${inactive.length}',
                    style: AppTypography.labelSmall(
                        color: AppColors.textMuted),
                  ),
                ),
                const Spacer(),
                Icon(
                  _showInactive
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: AppSpacing.iconMd,
                ),
              ],
            ),
          ),
        ),
        if (_showInactive)
          ...inactive
              .map((d) => _buildDirectiveCard(d, isActive: false)),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: AppSpacing.iconXl, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
