import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_task_model.dart';
import '../bloc/tron_kanban_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronKanbanPage extends StatefulWidget {
  const TronKanbanPage({super.key});

  @override
  State<TronKanbanPage> createState() => _TronKanbanPageState();
}

class _TronKanbanPageState extends State<TronKanbanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectId =
          context.read<TronProjectBloc>().state.selectedProject?.id;
      if (projectId != null) {
        context.read<TronKanbanBloc>().add(LoadKanbanEvent(projectId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Kanban', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<TronKanbanBloc, TronKanbanState>(
        builder: (context, state) {
          if (state.isLoading && state.allTasks.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.error != null && state.allTasks.isEmpty) {
            return _buildErrorState(state.error!);
          }

          return Column(
            children: [
              if (state.isLoading)
                LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.divider,
                  minHeight: 2,
                ),
              if (state.repos.isNotEmpty) _buildFilterBar(state),
              Expanded(child: _buildKanbanBoard(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.expense),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load tasks',
              style: AppTypography.titleMedium(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodySmall(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                final projectId =
                    context.read<TronProjectBloc>().state.selectedProject?.id;
                if (projectId != null) {
                  context
                      .read<TronKanbanBloc>()
                      .add(LoadKanbanEvent(projectId));
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: AppTypography.button()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Filter Bar --

  Widget _buildFilterBar(TronKanbanState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All Repos',
              isSelected: state.filterRepoId == null,
              onTap: () {
                context
                    .read<TronKanbanBloc>()
                    .add(const FilterByRepoEvent(null));
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            ...state.repos.map((repo) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _buildFilterChip(
                  label: repo.name,
                  isSelected: state.filterRepoId == repo.id,
                  onTap: () {
                    context
                        .read<TronKanbanBloc>()
                        .add(FilterByRepoEvent(repo.id));
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // -- Kanban Board --

  Widget _buildKanbanBoard(TronKanbanState state) {
    final columns = <_KanbanColumnData>[
      _KanbanColumnData(
        title: 'Todo',
        tasks: state.todoTasks,
        color: AppColors.textSecondary,
        icon: Icons.radio_button_unchecked_rounded,
      ),
      _KanbanColumnData(
        title: 'In Progress',
        tasks: state.inProgressTasks,
        color: AppColors.info,
        icon: Icons.play_circle_outline_rounded,
      ),
      _KanbanColumnData(
        title: 'Review',
        tasks: state.reviewTasks,
        color: AppColors.warning,
        icon: Icons.rate_review_outlined,
      ),
      _KanbanColumnData(
        title: 'Done',
        tasks: state.doneTasks,
        color: AppColors.income,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: columns.length,
      itemBuilder: (context, index) {
        final column = columns[index];
        return _buildKanbanColumn(column);
      },
    );
  }

  Widget _buildKanbanColumn(_KanbanColumnData column) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = (screenWidth - AppSpacing.md * 2 - AppSpacing.sm * 3)
            .clamp(260.0, 300.0);

    return Container(
      width: columnWidth,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: column.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(column.icon, size: 16, color: column.color),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  column.title,
                  style: AppTypography.titleSmall(color: column.color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: column.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${column.tasks.length}',
                    style: AppTypography.labelSmall(color: column.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Column cards
          Expanded(
            child: column.tasks.isEmpty
                ? _buildEmptyColumn()
                : ListView.separated(
                    itemCount: column.tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _buildTaskCard(column.tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No tasks',
          style: AppTypography.bodySmall(color: AppColors.textMuted),
        ),
      ),
    );
  }

  // -- Task Card --

  Widget _buildTaskCard(TronTask task) {
    final priorityColor = _priorityColor(task.priority);
    final agentColor = _agentColor(task.assignedAgent);
    final repoName = _findRepoName(task.repoId);

    return GestureDetector(
      onTap: () => context.push('/tron/tasks/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with priority indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.bodyMedium(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Bottom row: agent + repo
            Row(
              children: [
                if (task.assignedAgent != 'none') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: agentColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _agentIcon(task.assignedAgent),
                          size: 10,
                          color: agentColor,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          task.assignedAgent.toUpperCase(),
                          style: AppTypography.labelSmall(color: agentColor)
                              .copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (repoName != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            repoName,
                            style: AppTypography.labelSmall(
                                color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildTypeBadge(task.type),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        type,
        style:
            AppTypography.labelSmall(color: AppColors.textMuted).copyWith(fontSize: 9),
      ),
    );
  }

  // -- Helpers --

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return AppColors.expense;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      case 'low':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  Color _agentColor(String agent) {
    switch (agent) {
      case 'pm':
        return const Color(0xFF818CF8);
      case 'dev':
        return const Color(0xFF34D399);
      case 'qa':
        return const Color(0xFFFBBF24);
      case 'system':
        return AppColors.textMuted;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _agentIcon(String agent) {
    switch (agent) {
      case 'pm':
        return Icons.assignment_rounded;
      case 'dev':
        return Icons.code_rounded;
      case 'qa':
        return Icons.bug_report_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.smart_toy_rounded;
    }
  }

  String? _findRepoName(String repoId) {
    if (repoId.isEmpty) return null;
    try {
      final state = context.read<TronKanbanBloc>().state;
      final repo = state.repos.firstWhere((r) => r.id == repoId);
      return repo.name;
    } catch (_) {
      return null;
    }
  }
}

// -- Internal data class for column definition --

class _KanbanColumnData {
  final String title;
  final List<TronTask> tasks;
  final Color color;
  final IconData icon;

  const _KanbanColumnData({
    required this.title,
    required this.tasks,
    required this.color,
    required this.icon,
  });
}
