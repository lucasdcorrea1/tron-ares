import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/tron_agent_log_model.dart';
import '../../data/models/tron_decision_model.dart';
import '../../data/models/tron_metrics_model.dart';
import '../../data/models/tron_project_model.dart';
import '../../data/models/tron_repo_model.dart';
import '../bloc/tron_dashboard_bloc.dart';
import '../bloc/tron_project_bloc.dart';

class TronDashboardPage extends StatefulWidget {
  const TronDashboardPage({super.key});

  @override
  State<TronDashboardPage> createState() => _TronDashboardPageState();
}

class _TronDashboardPageState extends State<TronDashboardPage> {
  bool _dashboardLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadDashboard();
    });
  }

  void _tryLoadDashboard() {
    final projectState = context.read<TronProjectBloc>().state;
    final projectId = projectState.selectedProject?.id;
    if (projectId != null && !_dashboardLoaded) {
      _dashboardLoaded = true;
      context.read<TronDashboardBloc>().add(LoadDashboardEvent(projectId));
    }
  }

  void _onRefresh() {
    final projectId =
        context.read<TronProjectBloc>().state.selectedProject?.id;
    if (projectId != null) {
      context.read<TronDashboardBloc>().add(RefreshDashboardEvent(projectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('TRON Dashboard', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _onRefresh,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: BlocListener<TronProjectBloc, TronProjectState>(
        listener: (context, projectState) {
          // When projects finish loading and a project is selected, load dashboard
          if (projectState.selectedProject != null && !_dashboardLoaded) {
            _dashboardLoaded = true;
            context.read<TronDashboardBloc>().add(
                  LoadDashboardEvent(projectState.selectedProject!.id),
                );
          }
        },
        child: BlocBuilder<TronProjectBloc, TronProjectState>(
          builder: (context, projectState) {
            // Projects still loading
            if (projectState.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Loading projects...',
                      style: AppTypography.bodyMedium(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            // No projects — show welcome/setup screen
            if (projectState.projects.isEmpty && projectState.error == null) {
              return _buildEmptyProjectState(context);
            }

            // Projects failed to load (API error)
            if (projectState.error != null && projectState.projects.isEmpty) {
              return _buildProjectErrorState(projectState.error!);
            }

            // Has project — show dashboard
            return BlocBuilder<TronDashboardBloc, TronDashboardState>(
              builder: (context, state) {
                if (state.isLoading && state.metrics == null) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state.error != null && state.metrics == null) {
                  return _buildErrorState(state.error!);
                }

                return RefreshIndicator(
                  onRefresh: () async => _onRefresh(),
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardDark,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (state.isLoading)
                        LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.divider,
                          minHeight: 2,
                        ),
                      // Project selector
                      _buildProjectSelector(projectState),
                      const SizedBox(height: AppSpacing.md),
                      // Action buttons
                      _buildActionButtons(context, state, projectState),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.metrics != null)
                        _buildSummaryCards(state.metrics!.summary),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.repos.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Repositories', Icons.folder_rounded),
                        const SizedBox(height: AppSpacing.sm),
                        _buildRepoList(state.repos),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (state.pendingDecisions.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Pending Decisions', Icons.gavel_rounded),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDecisionsList(state.pendingDecisions),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _buildSectionHeader(
                          'Recent Activity', Icons.history_rounded),
                      const SizedBox(height: AppSpacing.sm),
                      if (state.recentLogs.isNotEmpty)
                        _buildActivityFeed(state.recentLogs)
                      else
                        _buildEmptySection('No recent activity'),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectSelector(TronProjectState projectState) {
    final selected = projectState.selectedProject;
    if (selected == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.folder_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected.name, style: AppTypography.titleSmall()),
                if (selected.description.isNotEmpty)
                  Text(
                    selected.description,
                    style:
                        AppTypography.labelSmall(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (projectState.projects.length > 1)
            PopupMenuButton<TronProject>(
              icon: Icon(Icons.unfold_more_rounded,
                  color: AppColors.textSecondary, size: 20),
              color: AppColors.cardDark,
              onSelected: (project) {
                _dashboardLoaded = false;
                context
                    .read<TronProjectBloc>()
                    .add(SelectProjectEvent(project));
              },
              itemBuilder: (_) => projectState.projects
                  .map((p) => PopupMenuItem(
                        value: p,
                        child: Text(p.name,
                            style: AppTypography.bodyMedium()),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, TronDashboardState state, TronProjectState projectState) {
    final projectId = projectState.selectedProject?.id;

    return Column(
      children: [
        // Run Agents + Open Full View
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.play_circle_rounded,
                label: state.isCycleRunning ? 'Running...' : 'Run Agents',
                color: AppColors.income,
                isLoading: state.isCycleRunning,
                onTap: projectId == null || state.isCycleRunning
                    ? null
                    : () {
                        context
                            .read<TronDashboardBloc>()
                            .add(RunAgentCycleEvent(projectId));
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                icon: Icons.add_rounded,
                label: 'Add Repo',
                color: AppColors.primary,
                onTap: projectId == null
                    ? null
                    : () => _showAddRepoDialog(context, projectId),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Quick nav to TRON sub-pages
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickNavChip(
                icon: Icons.view_kanban_rounded,
                label: 'Kanban',
                onTap: () => context.go('/tron/kanban'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickNavChip(
                icon: Icons.smart_toy_rounded,
                label: 'Agents',
                onTap: () => context.go('/tron/agents'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickNavChip(
                icon: Icons.gavel_rounded,
                label: 'Decisions',
                onTap: () => context.go('/tron/decisions'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickNavChip(
                icon: Icons.bar_chart_rounded,
                label: 'Metrics',
                onTap: () => context.go('/tron/metrics'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickNavChip(
                icon: Icons.terminal_rounded,
                label: 'Logs',
                onTap: () => context.go('/tron/logs'),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickNavChip(
                icon: Icons.rule_rounded,
                label: 'Directives',
                onTap: () => context.go('/tron/directives'),
              ),
            ],
          ),
        ),
        if (state.successMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                  color: AppColors.income.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.income),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    state.successMessage!,
                    style: AppTypography.bodySmall(color: AppColors.income),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAddRepoDialog(BuildContext context, String projectId) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Add Repository', style: AppTypography.titleMedium()),
        content: TextField(
          controller: urlController,
          style: AppTypography.bodyMedium(),
          decoration: InputDecoration(
            labelText: 'GitHub URL',
            hintText: 'https://github.com/user/repo',
            labelStyle:
                AppTypography.labelMedium(color: AppColors.textMuted),
            hintStyle:
                AppTypography.bodySmall(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: AppTypography.labelMedium(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                context.read<TronProjectBloc>().add(ImportRepoEvent(
                      projectId: projectId,
                      repoUrl: urlController.text,
                    ));
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Import',
                style: AppTypography.labelMedium(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProjectState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded,
                  size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Welcome to TRON',
              style: AppTypography.headlineSmall(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your AI-powered development management system.\nCreate your first project to get started.',
              style:
                  AppTypography.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _showCreateProjectDialog(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Create Project',
                  style: AppTypography.button(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => _onRefresh(),
              child: Text('Refresh',
                  style: AppTypography.labelMedium(
                      color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.expense),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not connect',
              style: AppTypography.titleMedium(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Make sure your backend is running on localhost:8080',
              style: AppTypography.bodySmall(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                error,
                style: AppTypography.labelSmall(color: AppColors.expense),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<TronProjectBloc>()
                    .add(const LoadProjectsEvent());
              },
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.white),
              label: Text('Retry',
                  style: AppTypography.button(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('New Project', style: AppTypography.titleMedium()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTypography.bodyMedium(),
              decoration: InputDecoration(
                labelText: 'Project Name',
                labelStyle:
                    AppTypography.labelMedium(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descController,
              style: AppTypography.bodyMedium(),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle:
                    AppTypography.labelMedium(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: AppTypography.labelMedium(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<TronProjectBloc>().add(CreateProjectEvent(
                      name: nameController.text,
                      description: descController.text,
                    ));
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Create',
                style: AppTypography.labelMedium(color: Colors.white)),
          ),
        ],
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
              'Failed to load dashboard',
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
              onPressed: _onRefresh,
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

  // -- Summary Cards --

  Widget _buildSummaryCards(TronMetricsSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7,
      children: [
        _buildMetricCard(
          icon: Icons.commit_rounded,
          label: 'Commits Today',
          value: '${summary.commitsToday}',
          color: AppColors.primary,
        ),
        _buildMetricCard(
          icon: Icons.task_alt_rounded,
          label: 'Open Tasks',
          value: '${summary.openTasks}',
          color: AppColors.income,
        ),
        _buildMetricCard(
          icon: Icons.gavel_rounded,
          label: 'Pending Decisions',
          value: '${summary.pendingDecisions}',
          color: AppColors.warning,
        ),
        _buildMetricCard(
          icon: Icons.smart_toy_rounded,
          label: 'Active Agents',
          value: '${summary.activeAgents}',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.headlineSmall()),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: AppTypography.labelSmall(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -- Section Header --

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.titleMedium()),
      ],
    );
  }

  // -- Repo List (horizontal scroll) --

  Widget _buildRepoList(List<TronRepo> repos) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: repos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => _buildRepoCard(repos[index]),
      ),
    );
  }

  Widget _buildRepoCard(TronRepo repo) {
    final languageColor = _languageColor(repo.language);
    final statusColor = _repoStatusColor(repo.status);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  repo.name,
                  style: AppTypography.titleSmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: languageColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                repo.language.isNotEmpty ? repo.language : 'Unknown',
                style: AppTypography.labelSmall(color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRepoStat(
                  Icons.insert_drive_file_outlined, '${repo.stats.totalFiles}'),
              _buildRepoStat(
                  Icons.task_alt_rounded, '${repo.stats.openTasks}'),
              _buildRepoStat(
                  Icons.commit_rounded, '${repo.stats.commitsToday}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepoStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xxs),
        Text(value, style: AppTypography.labelSmall(color: AppColors.textMuted)),
      ],
    );
  }

  Color _languageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'javascript':
      case 'js':
        return const Color(0xFFF1E05A);
      case 'typescript':
      case 'ts':
        return const Color(0xFF3178C6);
      case 'python':
        return const Color(0xFF3572A5);
      case 'rust':
        return const Color(0xFFDEA584);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'swift':
        return const Color(0xFFFA7343);
      case 'kotlin':
        return const Color(0xFFA97BFF);
      case 'java':
        return const Color(0xFFB07219);
      default:
        return AppColors.textMuted;
    }
  }

  Color _repoStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.income;
      case 'analyzing':
        return AppColors.warning;
      case 'paused':
        return AppColors.textMuted;
      case 'error':
        return AppColors.expense;
      default:
        return AppColors.textMuted;
    }
  }

  // -- Pending Decisions --

  Widget _buildDecisionsList(List<TronDecision> decisions) {
    return Column(
      children: decisions.map((d) => _buildDecisionCard(d)).toList(),
    );
  }

  Widget _buildDecisionCard(TronDecision decision) {
    final typeIcon = _decisionTypeIcon(decision.type);
    final typeColor = _decisionTypeColor(decision.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(typeIcon, size: 16, color: typeColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      decision.title,
                      style: AppTypography.titleSmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Requested by ${decision.requestedBy.toUpperCase()} agent',
                      style: AppTypography.labelSmall(
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _buildDecisionTypeBadge(decision.type),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            decision.description,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Reject decision - can be wired to a bloc event
                  },
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.expense),
                  label: Text(
                    'Reject',
                    style:
                        AppTypography.labelMedium(color: AppColors.expense),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.expense.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Approve decision - can be wired to a bloc event
                  },
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: Text('Approve', style: AppTypography.labelMedium(
                      color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
      decoration: BoxDecoration(
        color: _decisionTypeColor(type).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTypography.labelSmall(color: _decisionTypeColor(type)),
      ),
    );
  }

  IconData _decisionTypeIcon(String type) {
    switch (type) {
      case 'merge':
        return Icons.merge_rounded;
      case 'deploy':
        return Icons.rocket_launch_rounded;
      case 'architecture':
        return Icons.architecture_rounded;
      case 'priority':
        return Icons.low_priority_rounded;
      case 'abort':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _decisionTypeColor(String type) {
    switch (type) {
      case 'merge':
        return AppColors.info;
      case 'deploy':
        return AppColors.income;
      case 'architecture':
        return AppColors.primary;
      case 'priority':
        return AppColors.warning;
      case 'abort':
        return AppColors.expense;
      default:
        return AppColors.textMuted;
    }
  }

  // -- Activity Feed --

  Widget _buildActivityFeed(List<TronAgentLog> logs) {
    return Column(
      children: logs.map((log) => _buildActivityItem(log)).toList(),
    );
  }

  Widget _buildActivityItem(TronAgentLog log) {
    final agentColor = _agentColor(log.agent);
    final agentIcon = _agentIcon(log.agent);
    final levelColor = _levelColor(log.level);
    final timeAgo = _formatTimeAgo(log.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: agentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(agentIcon, size: 14, color: agentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.agent.toUpperCase(),
                      style: AppTypography.labelSmall(color: agentColor),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (log.level != 'info')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          log.level.toUpperCase(),
                          style: AppTypography.labelSmall(color: levelColor)
                              .copyWith(fontSize: 9),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      timeAgo,
                      style: AppTypography.labelSmall(
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  log.message,
                  style: AppTypography.bodySmall(
                      color: AppColors.textSecondary),
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

  Color _agentColor(String agent) {
    switch (agent) {
      case 'pm':
        return const Color(0xFF818CF8); // indigo
      case 'dev':
        return const Color(0xFF34D399); // emerald
      case 'qa':
        return const Color(0xFFFBBF24); // amber
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

  Color _levelColor(String level) {
    switch (level) {
      case 'error':
        return AppColors.expense;
      case 'warning':
        return AppColors.warning;
      case 'debug':
        return AppColors.textMuted;
      case 'info':
      default:
        return AppColors.info;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }

  // -- Empty State --

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTypography.bodyMedium(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// -- Reusable Widgets --

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm + 2, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelMedium(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickNavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickNavChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall(
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
