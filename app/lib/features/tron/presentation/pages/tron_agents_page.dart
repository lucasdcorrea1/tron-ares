import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_metrics_model.dart';
import '../bloc/tron_agents_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronAgentsPage extends StatefulWidget {
  const TronAgentsPage({super.key});

  @override
  State<TronAgentsPage> createState() => _TronAgentsPageState();
}

class _TronAgentsPageState extends State<TronAgentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgents();
    });
  }

  void _loadAgents() {
    final projectState = context.read<TronProjectBloc>().state;
    final projectId = projectState.selectedProject?.id;
    if (projectId != null) {
      context.read<TronAgentsBloc>().add(LoadAgentsEvent(projectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Agents', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadAgents,
          ),
        ],
      ),
      body: BlocBuilder<TronAgentsBloc, TronAgentsState>(
        builder: (context, state) {
          if (state.isLoading && state.agents.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.error != null && state.agents.isEmpty) {
            return _buildErrorState(state.error!);
          }

          if (state.agents.isEmpty) {
            return _buildEmptyState();
          }

          return _buildAgentsList(state);
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
            Icon(
              Icons.error_outline,
              size: AppSpacing.iconXl,
              color: AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load agents',
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
              onPressed: _loadAgents,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: AppSpacing.iconXl,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No agents found',
            style: AppTypography.titleMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Agents will appear here once a project is active.',
            style: AppTypography.bodySmall(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList(TronAgentsState state) {
    final agentEntries = state.agents.entries.toList();

    return RefreshIndicator(
      onRefresh: () async => _loadAgents(),
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: agentEntries.length,
        itemBuilder: (context, index) {
          final entry = agentEntries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _AgentCard(
              agentKey: entry.key,
              metrics: entry.value,
            ),
          );
        },
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final String agentKey;
  final TronAgentMetrics metrics;

  const _AgentCard({
    required this.agentKey,
    required this.metrics,
  });

  IconData _agentIcon(String agent) {
    switch (agent.toLowerCase()) {
      case 'pm':
        return Icons.assignment;
      case 'dev':
        return Icons.code;
      case 'qa':
        return Icons.bug_report;
      default:
        return Icons.smart_toy;
    }
  }

  String _agentDisplayName(String agent) {
    switch (agent.toLowerCase()) {
      case 'pm':
        return 'Project Manager';
      case 'dev':
        return 'Developer';
      case 'qa':
        return 'QA Engineer';
      default:
        return agent.toUpperCase();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF22C55E); // green
      case 'idle':
        return const Color(0xFFEAB308); // yellow
      case 'error':
        return const Color(0xFFEF4444); // red
      case 'offline':
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'idle':
        return 'Idle';
      case 'error':
        return 'Error';
      case 'offline':
      default:
        return 'Offline';
    }
  }

  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)}m';
    }
    final hours = (minutes / 60).floor();
    final remaining = (minutes % 60).toStringAsFixed(0);
    return '${hours}h ${remaining}m';
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final diff = now.difference(lastActive);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastActive.day}/${lastActive.month}/${lastActive.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(metrics.status);
    final agentName = metrics.agent.isNotEmpty ? metrics.agent : agentKey;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Agent name, icon, status
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    _agentIcon(agentName),
                    color: AppColors.primary,
                    size: AppSpacing.iconMd,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _agentDisplayName(agentName),
                        style: AppTypography.titleMedium(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        agentName.toUpperCase(),
                        style: AppTypography.labelSmall(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _statusLabel(metrics.status),
                        style: AppTypography.labelSmall(color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            color: AppColors.divider,
            height: 1,
          ),

          // Metrics grid
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Completed',
                    value: '${metrics.tasksCompleted}',
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.income,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'In Progress',
                    value: '${metrics.tasksInProgress}',
                    icon: Icons.pending_outlined,
                    iconColor: AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Commits',
                    value: '${metrics.commitsToday}',
                    icon: Icons.commit,
                    iconColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            color: AppColors.divider,
            height: 1,
          ),

          // Footer: avg duration + last active
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: AppSpacing.iconSm,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Avg: ${_formatDuration(metrics.avgTaskDurationMinutes)}',
                  style: AppTypography.labelSmall(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: AppSpacing.iconSm,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _formatLastActive(metrics.lastActiveAt),
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
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSm,
          color: iconColor,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.labelSmall(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
