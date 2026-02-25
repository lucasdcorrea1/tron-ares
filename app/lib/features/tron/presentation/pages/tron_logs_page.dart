import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_agent_log_model.dart';
import '../bloc/tron_logs_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronLogsPage extends StatefulWidget {
  const TronLogsPage({super.key});

  @override
  State<TronLogsPage> createState() => _TronLogsPageState();
}

class _TronLogsPageState extends State<TronLogsPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedAgent;
  String? _selectedRepoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectState = context.read<TronProjectBloc>().state;
      final projectId = projectState.selectedProject?.id;
      if (projectId != null) {
        context.read<TronLogsBloc>().add(LoadLogsEvent(projectId));
        context.read<TronLogsBloc>().add(ConnectWebSocketEvent(projectId));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleWebSocket() {
    final logsState = context.read<TronLogsBloc>().state;
    if (logsState.isWsConnected) {
      context.read<TronLogsBloc>().add(const DisconnectWebSocketEvent());
    } else {
      final projectId =
          context.read<TronProjectBloc>().state.selectedProject?.id;
      if (projectId != null) {
        context.read<TronLogsBloc>().add(ConnectWebSocketEvent(projectId));
      }
    }
  }

  void _onAgentFilterChanged(String? agent) {
    setState(() => _selectedAgent = agent);
    context.read<TronLogsBloc>().add(FilterLogsEvent(
          agent: agent,
          repoId: _selectedRepoId,
        ));
  }

  void _onRepoFilterChanged(String? repoId) {
    setState(() => _selectedRepoId = repoId);
    context.read<TronLogsBloc>().add(FilterLogsEvent(
          agent: _selectedAgent,
          repoId: repoId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Logs', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // WebSocket connection indicator
          BlocBuilder<TronLogsBloc, TronLogsState>(
            buildWhen: (prev, curr) =>
                prev.isWsConnected != curr.isWsConnected,
            builder: (context, state) {
              return Padding(
                padding:
                    const EdgeInsets.only(right: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isWsConnected
                            ? AppColors.income
                            : AppColors.expense,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (state.isWsConnected
                                    ? AppColors.income
                                    : AppColors.expense)
                                .withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      state.isWsConnected ? 'Live' : 'Offline',
                      style: AppTypography.labelSmall(
                        color: state.isWsConnected
                            ? AppColors.income
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Connect/disconnect button
                    IconButton(
                      onPressed: _toggleWebSocket,
                      icon: Icon(
                        state.isWsConnected
                            ? Icons.link_off
                            : Icons.link,
                        size: AppSpacing.iconSm,
                        color: state.isWsConnected
                            ? AppColors.expense
                            : AppColors.income,
                      ),
                      tooltip: state.isWsConnected
                          ? 'Disconnect'
                          : 'Connect',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.buttonHeightSm,
                        minHeight: AppSpacing.buttonHeightSm,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TronLogsBloc, TronLogsState>(
        builder: (context, state) {
          if (state.isLoading && state.logs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.error != null && state.logs.isEmpty) {
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
                    'Failed to load logs',
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
                            .read<TronLogsBloc>()
                            .add(LoadLogsEvent(projectId));
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

          final filteredLogs = state.filteredLogs;

          return Column(
            children: [
              // Filter row
              _buildFilterRow(state),

              // Log entries list
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: AppSpacing.iconXl,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No log entries',
                              style: AppTypography.bodyMedium(
                                  color: AppColors.textMuted),
                            ),
                            if (_selectedAgent != null ||
                                _selectedRepoId != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Try adjusting filters',
                                style: AppTypography.bodySmall(
                                    color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          return _buildLogEntry(filteredLogs[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(TronLogsState state) {
    final repos = context.read<TronProjectBloc>().state.repos;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAgentChip(null, 'All', Icons.apps),
                const SizedBox(width: AppSpacing.sm),
                _buildAgentChip('pm', 'PM', Icons.manage_accounts),
                const SizedBox(width: AppSpacing.sm),
                _buildAgentChip('dev', 'Dev', Icons.code),
                const SizedBox(width: AppSpacing.sm),
                _buildAgentChip('qa', 'QA', Icons.bug_report),
                const SizedBox(width: AppSpacing.sm),
                _buildAgentChip('system', 'System', Icons.settings),
              ],
            ),
          ),
          if (repos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            // Repo filter dropdown
            Container(
              height: AppSpacing.buttonHeightSm,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedRepoId,
                  isExpanded: true,
                  dropdownColor: AppColors.cardDark,
                  hint: Text(
                    'All Repositories',
                    style: AppTypography.bodySmall(
                        color: AppColors.textMuted),
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: AppSpacing.iconSm,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Repositories',
                        style: AppTypography.bodySmall(
                            color: AppColors.textSecondary),
                      ),
                    ),
                    ...repos.map(
                      (repo) => DropdownMenuItem<String?>(
                        value: repo.id,
                        child: Text(
                          repo.name,
                          style: AppTypography.bodySmall(
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                  onChanged: _onRepoFilterChanged,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentChip(
      String? agent, String label, IconData icon) {
    final isSelected = _selectedAgent == agent;
    final chipColor = agent != null ? _agentColor(agent) : AppColors.primary;

    return GestureDetector(
      onTap: () => _onAgentFilterChanged(agent),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? chipColor : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelSmall(
                color:
                    isSelected ? chipColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(TronAgentLog log) {
    final levelColor = _levelColor(log.level);
    final levelIcon = _levelIcon(log.level);
    final agentColor = _agentColor(log.agent);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          left: BorderSide(
            color: levelColor.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 52,
            child: Text(
              _formatTimestamp(log.timestamp),
              style: AppTypography.labelSmall(
                  color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Agent badge
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: agentColor.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              log.agent.toUpperCase(),
              style: AppTypography.labelSmall(color: agentColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Level icon
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              levelIcon,
              size: 14,
              color: levelColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Message
          Expanded(
            child: Text(
              log.message,
              style: AppTypography.bodySmall(
                color: log.level == 'error'
                    ? AppColors.expense
                    : log.level == 'warning'
                        ? AppColors.warning
                        : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'info':
        return AppColors.info;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.expense;
      case 'debug':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_amber;
      case 'error':
        return Icons.error_outline;
      case 'debug':
        return Icons.bug_report_outlined;
      default:
        return Icons.circle_outlined;
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

  String _formatTimestamp(DateTime timestamp) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
