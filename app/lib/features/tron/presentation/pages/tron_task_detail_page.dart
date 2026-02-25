import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_task_model.dart';
import '../bloc/tron_task_detail_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronTaskDetailPage extends StatefulWidget {
  final String taskId;

  const TronTaskDetailPage({super.key, required this.taskId});

  @override
  State<TronTaskDetailPage> createState() => _TronTaskDetailPageState();
}

class _TronTaskDetailPageState extends State<TronTaskDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaskDetail();
    });
  }

  void _loadTaskDetail() {
    final projectState = context.read<TronProjectBloc>().state;
    final projectId = projectState.selectedProject?.id;
    if (projectId != null) {
      context.read<TronTaskDetailBloc>().add(
            LoadTaskDetailEvent(
              projectId: projectId,
              taskId: widget.taskId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TronTaskDetailBloc, TronTaskDetailState>(
      listener: (context, state) {
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionMessage!),
              backgroundColor: AppColors.cardDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: Text(
              state.task?.title ?? 'Task Detail',
              style: AppTypography.titleLarge(),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(TronTaskDetailState state) {
    if (state.isLoading && state.task == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.task == null) {
      return _buildErrorState(state.error!);
    }

    final task = state.task;
    if (task == null) {
      return Center(
        child: Text(
          'Task not found',
          style: AppTypography.bodyLarge(color: AppColors.textSecondary),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            // Extra bottom padding to avoid CIO actions overlap
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusAndMeta(task),
              const SizedBox(height: AppSpacing.lg),
              _buildDescriptionSection(task),
              const SizedBox(height: AppSpacing.lg),
              _buildTimelineSection(task.timeline),
              const SizedBox(height: AppSpacing.lg),
              _buildCommitsSection(task.commits),
            ],
          ),
        ),
        // CIO actions pinned at the bottom
        if (task.cioDecision == 'pending' || task.cioDecision == 'none')
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCioActions(task, state.isLoading),
          ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSpacing.iconXl,
              color: AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load task',
              style: AppTypography.titleMedium(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodySmall(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadTaskDetail,
              icon: const Icon(Icons.refresh, size: AppSpacing.iconSm),
              label: Text('Retry', style: AppTypography.button()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status badge + meta row ──────────────────────────────────────────

  Widget _buildStatusAndMeta(TronTask task) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(status: task.status),
              const SizedBox(width: AppSpacing.sm),
              _PriorityBadge(priority: task.priority),
              const Spacer(),
              Text(
                task.type.toUpperCase(),
                style: AppTypography.labelSmall(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: AppSpacing.iconSm, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _agentLabel(task.assignedAgent),
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.call_split,
                  size: AppSpacing.iconSm, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  task.branch.isNotEmpty ? task.branch : '--',
                  style:
                      AppTypography.bodySmall(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (task.cioDecision != 'none' && task.cioDecision != 'pending') ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  task.cioDecision == 'approved'
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: AppSpacing.iconSm,
                  color: task.cioDecision == 'approved'
                      ? AppColors.income
                      : AppColors.expense,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'CIO: ${task.cioDecision.toUpperCase()}',
                  style: AppTypography.labelSmall(
                    color: task.cioDecision == 'approved'
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _agentLabel(String agent) {
    switch (agent.toLowerCase()) {
      case 'pm':
        return 'Project Manager';
      case 'dev':
        return 'Developer';
      case 'qa':
        return 'QA Engineer';
      case 'none':
        return 'Unassigned';
      default:
        return agent.toUpperCase();
    }
  }

  // ── Description ──────────────────────────────────────────────────────

  Widget _buildDescriptionSection(TronTask task) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTypography.titleSmall(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.description.isNotEmpty
                ? task.description
                : 'No description provided.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Timeline ─────────────────────────────────────────────────────────

  Widget _buildTimelineSection(TronTaskTimeline timeline) {
    final phases = <_TimelinePhase>[
      _TimelinePhase(
        label: 'PM Planning',
        icon: Icons.assignment,
        startedAt: timeline.pmStartedAt,
        completedAt: timeline.pmCompletedAt,
      ),
      _TimelinePhase(
        label: 'Development',
        icon: Icons.code,
        startedAt: timeline.devStartedAt,
        completedAt: timeline.devCompletedAt,
      ),
      _TimelinePhase(
        label: 'QA Testing',
        icon: Icons.bug_report,
        startedAt: timeline.qaStartedAt,
        completedAt: timeline.qaCompletedAt,
      ),
      _TimelinePhase(
        label: 'CIO Review',
        icon: Icons.gavel,
        startedAt: timeline.cioReviewedAt,
        completedAt: timeline.cioReviewedAt,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: AppTypography.titleSmall(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(phases.length, (index) {
            final phase = phases[index];
            final isLast = index == phases.length - 1;
            return _buildTimelineEntry(phase, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(_TimelinePhase phase, bool isLast) {
    final isCompleted = phase.completedAt != null;
    final isActive =
        phase.startedAt != null && phase.completedAt == null;
    final isPending = phase.startedAt == null;

    Color dotColor;
    if (isCompleted) {
      dotColor = AppColors.income;
    } else if (isActive) {
      dotColor = AppColors.warning;
    } else {
      dotColor = AppColors.textMuted;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                            width: 3,
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.income.withValues(alpha: 0.4)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Phase content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        phase.icon,
                        size: AppSpacing.iconSm,
                        color: isCompleted
                            ? AppColors.income
                            : isActive
                                ? AppColors.warning
                                : AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        phase.label,
                        style: AppTypography.labelLarge(
                          color: isPending
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'IN PROGRESS',
                            style: AppTypography.labelSmall(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (phase.startedAt != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Started: ${_formatDateTime(phase.startedAt!)}',
                      style:
                          AppTypography.labelSmall(color: AppColors.textMuted),
                    ),
                  ],
                  if (phase.completedAt != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Completed: ${_formatDateTime(phase.completedAt!)}',
                      style:
                          AppTypography.labelSmall(color: AppColors.textMuted),
                    ),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Pending',
                      style:
                          AppTypography.labelSmall(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  // ── Commits ──────────────────────────────────────────────────────────

  Widget _buildCommitsSection(List<TronCommit> commits) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Commits',
                style: AppTypography.titleSmall(color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${commits.length}',
                  style: AppTypography.labelSmall(color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (commits.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'No commits yet.',
              style: AppTypography.bodySmall(color: AppColors.textMuted),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            ...commits.map((commit) => _buildCommitRow(commit)),
          ],
        ],
      ),
    );
  }

  Widget _buildCommitRow(TronCommit commit) {
    final shortSha =
        commit.sha.length >= 7 ? commit.sha.substring(0, 7) : commit.sha;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.commit,
            size: AppSpacing.iconSm,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        shortSha,
                        style: AppTypography.labelSmall(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Additions / deletions
                    Text(
                      '+${commit.additions}',
                      style: AppTypography.labelSmall(
                        color: AppColors.income,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '-${commit.deletions}',
                      style: AppTypography.labelSmall(
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  commit.message,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CIO Actions ──────────────────────────────────────────────────────

  Widget _buildCioActions(TronTask task, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CIO Decision',
              style: AppTypography.labelMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppSpacing.buttonHeightMd,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _onApprove(task),
                      icon: const Icon(Icons.check, size: AppSpacing.iconSm),
                      label: Text('Approve', style: AppTypography.button()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: AppSpacing.buttonHeightMd,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _onReject(task),
                      icon: const Icon(Icons.close, size: AppSpacing.iconSm),
                      label: Text('Reject', style: AppTypography.button()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onApprove(TronTask task) {
    final projectState = context.read<TronProjectBloc>().state;
    final projectId = projectState.selectedProject?.id;
    if (projectId == null) return;

    context.read<TronTaskDetailBloc>().add(
          ApproveTaskEvent(
            projectId: projectId,
            taskId: task.id,
          ),
        );
  }

  void _onReject(TronTask task) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(color: AppColors.divider),
          ),
          title: Text(
            'Reject Task',
            style: AppTypography.titleMedium(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for rejecting this task.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Reason for rejection...',
                  hintStyle:
                      AppTypography.bodyMedium(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
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
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.button(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;

                Navigator.of(dialogContext).pop();

                final projectState =
                    context.read<TronProjectBloc>().state;
                final projectId = projectState.selectedProject?.id;
                if (projectId == null) return;

                context.read<TronTaskDetailBloc>().add(
                      RejectTaskEvent(
                        projectId: projectId,
                        taskId: task.id,
                        reason: reason,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                'Reject',
                style: AppTypography.button(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _color() {
    switch (status.toLowerCase()) {
      case 'done':
        return AppColors.income;
      case 'in_progress':
        return AppColors.warning;
      case 'review':
        return AppColors.info;
      case 'todo':
        return AppColors.textMuted;
      case 'backlog':
      default:
        return AppColors.textMuted;
    }
  }

  String _label() {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Done';
      case 'in_progress':
        return 'In Progress';
      case 'review':
        return 'Review';
      case 'todo':
        return 'To Do';
      case 'backlog':
        return 'Backlog';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label(),
        style: AppTypography.labelSmall(color: c),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  Color _color() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.expense;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.primary;
      case 'low':
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 10, color: c),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            priority.toUpperCase(),
            style: AppTypography.labelSmall(color: c),
          ),
        ],
      ),
    );
  }
}

class _TimelinePhase {
  final String label;
  final IconData icon;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const _TimelinePhase({
    required this.label,
    required this.icon,
    this.startedAt,
    this.completedAt,
  });
}
