import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_metrics_model.dart';
import '../bloc/tron_metrics_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronMetricsPage extends StatefulWidget {
  const TronMetricsPage({super.key});

  @override
  State<TronMetricsPage> createState() => _TronMetricsPageState();
}

class _TronMetricsPageState extends State<TronMetricsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectState = context.read<TronProjectBloc>().state;
      final projectId = projectState.selectedProject?.id;
      if (projectId != null) {
        context
            .read<TronMetricsBloc>()
            .add(LoadMetricsEvent(projectId, days: 30));
      }
    });
  }

  void _loadWithDays(int days) {
    final projectId =
        context.read<TronProjectBloc>().state.selectedProject?.id;
    if (projectId != null) {
      context
          .read<TronMetricsBloc>()
          .add(LoadMetricsEvent(projectId, days: days));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Metrics', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<TronMetricsBloc, TronMetricsState>(
        builder: (context, state) {
          if (state.isLoading && state.metrics == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.error != null && state.metrics == null) {
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
                    'Failed to load metrics',
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
                    onPressed: () => _loadWithDays(state.selectedDays),
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

          final metrics = state.metrics;
          if (metrics == null) {
            return Center(
              child: Text(
                'No metrics available',
                style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadWithDays(state.selectedDays),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Period selector chips
                _buildPeriodSelector(state.selectedDays),
                const SizedBox(height: AppSpacing.md),

                // Summary cards row
                _buildSummaryCards(metrics.summary),
                const SizedBox(height: AppSpacing.lg),

                // Daily commits bar chart
                _buildDailyCommitsChart(metrics.daily),
                const SizedBox(height: AppSpacing.lg),

                // Tasks completion rate
                _buildCompletionRate(metrics.summary),
                const SizedBox(height: AppSpacing.lg),

                // Agent performance table
                _buildAgentPerformanceTable(metrics.agents),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(int selectedDays) {
    return Row(
      children: [
        Text(
          'Period',
          style: AppTypography.labelMedium(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        _buildPeriodChip(7, selectedDays),
        const SizedBox(width: AppSpacing.sm),
        _buildPeriodChip(14, selectedDays),
        const SizedBox(width: AppSpacing.sm),
        _buildPeriodChip(30, selectedDays),
      ],
    );
  }

  Widget _buildPeriodChip(int days, int selectedDays) {
    final isSelected = days == selectedDays;
    return GestureDetector(
      onTap: () => _loadWithDays(days),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          '${days}d',
          style: AppTypography.labelLarge(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(TronMetricsSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.8,
      children: [
        _buildSummaryCard(
          title: 'Total Tasks',
          value: '${summary.totalTasks}',
          icon: Icons.task_alt,
          iconColor: AppColors.primary,
        ),
        _buildSummaryCard(
          title: 'Completed',
          value: '${summary.completedTasks}',
          icon: Icons.check_circle,
          iconColor: AppColors.income,
        ),
        _buildSummaryCard(
          title: 'Commits',
          value: '${summary.totalCommits}',
          icon: Icons.commit,
          iconColor: AppColors.info,
        ),
        _buildSummaryCard(
          title: 'Est. Cost',
          value: '\$${summary.estimatedCostUsd.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.iconSm, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSmall(
                      color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineSmall(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCommitsChart(List<TronDailyMetric> daily) {
    if (daily.isEmpty) {
      return _buildSectionCard(
        title: 'Daily Commits',
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'No daily data available',
              style:
                  AppTypography.bodySmall(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final maxCommits =
        daily.map((d) => d.commits).reduce((a, b) => math.max(a, b));
    final chartMax = maxCommits > 0 ? maxCommits : 1;

    // Show up to last 14 entries to avoid overcrowding
    final displayData =
        daily.length > 14 ? daily.sublist(daily.length - 14) : daily;

    return _buildSectionCard(
      title: 'Daily Commits',
      child: SizedBox(
        height: 140,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: displayData.map((d) {
                  final ratio = d.commits / chartMax;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2),
                      child: Tooltip(
                        message:
                            '${d.date.day}/${d.date.month}: ${d.commits} commits',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (d.commits > 0)
                              Text(
                                '${d.commits}',
                                style: AppTypography.labelSmall(
                                    color: AppColors.textMuted),
                              ),
                            const SizedBox(height: 2),
                            Container(
                              height:
                                  math.max(4, ratio * 80),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3 + ratio * 0.7),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Date labels for first and last
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${displayData.first.date.day}/${displayData.first.date.month}',
                  style: AppTypography.labelSmall(
                      color: AppColors.textMuted),
                ),
                Text(
                  '${displayData.last.date.day}/${displayData.last.date.month}',
                  style: AppTypography.labelSmall(
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRate(TronMetricsSummary summary) {
    final total = summary.totalTasks;
    final completed = summary.completedTasks;
    final rate = total > 0 ? completed / total : 0.0;

    return _buildSectionCard(
      title: 'Task Completion Rate',
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 0.7
                          ? AppColors.income
                          : rate >= 0.4
                              ? AppColors.warning
                              : AppColors.expense,
                    ),
                  ),
                ),
                Text(
                  '${(rate * 100).toInt()}%',
                  style: AppTypography.titleMedium(
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                    'Completed', '$completed', AppColors.income),
                const SizedBox(height: AppSpacing.sm),
                _buildStatRow(
                    'Open', '${summary.openTasks}', AppColors.warning),
                const SizedBox(height: AppSpacing.sm),
                _buildStatRow(
                    'Total', '$total', AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                _buildStatRow(
                  'Test Coverage',
                  '${summary.testCoverage.toStringAsFixed(1)}%',
                  AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySmall(
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        Text(
          value,
          style: AppTypography.labelLarge(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildAgentPerformanceTable(
      Map<String, TronAgentMetrics> agents) {
    if (agents.isEmpty) {
      return _buildSectionCard(
        title: 'Agent Performance',
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Text(
              'No agent data available',
              style:
                  AppTypography.bodySmall(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final agentList = agents.entries.toList();

    return _buildSectionCard(
      title: 'Agent Performance',
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Agent',
                    style: AppTypography.labelSmall(
                        color: AppColors.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: AppTypography.labelSmall(
                        color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Done',
                    style: AppTypography.labelSmall(
                        color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'WIP',
                    style: AppTypography.labelSmall(
                        color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Commits',
                    style: AppTypography.labelSmall(
                        color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ...agentList.map((entry) =>
              _buildAgentRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildAgentRow(String name, TronAgentMetrics agent) {
    final statusColor = _agentStatusColor(agent.status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  _agentIcon(name),
                  size: AppSpacing.iconSm,
                  color: _agentColor(name),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: AppTypography.labelLarge(
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  agent.status,
                  style: AppTypography.labelSmall(color: statusColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${agent.tasksCompleted}',
              style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${agent.tasksInProgress}',
              style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${agent.commitsToday}',
              style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              title,
              style: AppTypography.titleSmall(
                  color: AppColors.textSecondary),
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Color _agentStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.income;
      case 'idle':
        return AppColors.warning;
      case 'error':
        return AppColors.expense;
      case 'offline':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _agentIcon(String agent) {
    switch (agent.toLowerCase()) {
      case 'pm':
        return Icons.manage_accounts;
      case 'dev':
        return Icons.code;
      case 'qa':
        return Icons.bug_report;
      case 'system':
        return Icons.settings;
      default:
        return Icons.smart_toy;
    }
  }

  Color _agentColor(String agent) {
    switch (agent.toLowerCase()) {
      case 'pm':
        return AppColors.primary;
      case 'dev':
        return AppColors.info;
      case 'qa':
        return AppColors.warning;
      case 'system':
        return AppColors.textMuted;
      default:
        return AppColors.textSecondary;
    }
  }
}
