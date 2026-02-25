import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/tron_decision_model.dart';
import '../../data/services/tron_api_service.dart';
import '../bloc/tron_project_bloc.dart';

class TronDecisionsPage extends StatefulWidget {
  const TronDecisionsPage({super.key});

  @override
  State<TronDecisionsPage> createState() => _TronDecisionsPageState();
}

class _TronDecisionsPageState extends State<TronDecisionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TronApiService _apiService = sl<TronApiService>();

  List<TronDecision> _allDecisions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDecisions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _getProjectId() {
    try {
      final projectState = context.read<TronProjectBloc>().state;
      return projectState.selectedProject?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDecisions() async {
    final projectId = _getProjectId();
    if (projectId == null) {
      setState(() {
        _error = 'No project selected';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final decisions = await _apiService.getDecisions(projectId);
      if (mounted) {
        setState(() {
          _allDecisions = decisions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<TronDecision> _filterByStatus(String status) {
    return _allDecisions.where((d) => d.status == status).toList();
  }

  Future<void> _approveDecision(TronDecision decision) async {
    final reason = await _showReasonDialog('Approve Decision', isRequired: false);
    if (reason == null) return;

    final projectId = _getProjectId();
    if (projectId == null) return;

    try {
      await _apiService.approveDecision(
        projectId,
        decision.id,
        reason.isEmpty ? null : reason,
      );
      _loadDecisions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _rejectDecision(TronDecision decision) async {
    final reason = await _showReasonDialog('Reject Decision', isRequired: true);
    if (reason == null || reason.isEmpty) return;

    final projectId = _getProjectId();
    if (projectId == null) return;

    try {
      await _apiService.rejectDecision(projectId, decision.id, reason);
      _loadDecisions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  Future<String?> _showReasonDialog(String title, {bool isRequired = false}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(title, style: AppTypography.titleMedium()),
        content: TextField(
          controller: controller,
          style: AppTypography.bodyMedium(),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isRequired ? 'Reason (required)' : 'Reason (optional)',
            hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
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
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Cancel',
                style: AppTypography.labelLarge(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (isRequired && controller.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(controller.text.trim());
            },
            child: Text('Confirm',
                style: AppTypography.labelLarge(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('CIO Decisions', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadDecisions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTypography.labelLarge(),
          unselectedLabelStyle: AppTypography.labelMedium(),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildCountBadge(_filterByStatus('pending').length),
                ],
              ),
            ),
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDecisionList(_filterByStatus('pending'), 'pending'),
                    _buildDecisionList(
                        _filterByStatus('approved'), 'approved'),
                    _buildDecisionList(
                        _filterByStatus('rejected'), 'rejected'),
                  ],
                ),
    );
  }

  Widget _buildCountBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        count.toString(),
        style: AppTypography.labelSmall(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppSpacing.iconXl, color: AppColors.expense),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load decisions',
              style: AppTypography.titleMedium(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: AppTypography.bodySmall(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadDecisions,
              icon: const Icon(Icons.refresh, size: AppSpacing.iconSm),
              label: Text('Retry', style: AppTypography.labelLarge()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
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

  Widget _buildDecisionList(List<TronDecision> decisions, String tab) {
    if (decisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab == 'pending'
                  ? Icons.check_circle_outline
                  : Icons.inbox_outlined,
              size: AppSpacing.iconXl,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              tab == 'pending'
                  ? 'No pending decisions'
                  : 'No $tab decisions',
              style: AppTypography.bodyLarge(color: AppColors.textSecondary),
            ),
            if (tab == 'pending') ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'All caught up!',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDecisions,
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: decisions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final decision = decisions[index];
          return _DecisionCard(
            decision: decision,
            isPending: tab == 'pending',
            onApprove: () => _approveDecision(decision),
            onReject: () => _rejectDecision(decision),
          );
        },
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final TronDecision decision;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DecisionCard({
    required this.decision,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isPending
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: type badge + timestamp
            Row(
              children: [
                _buildTypeBadge(decision.type),
                const Spacer(),
                Text(
                  _formatTimestamp(decision.createdAt),
                  style: AppTypography.labelSmall(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              decision.title,
              style: AppTypography.titleMedium(color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Description
            Text(
              decision.description,
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Requested by
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: AppSpacing.iconSm, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Requested by ',
                  style: AppTypography.labelSmall(color: AppColors.textMuted),
                ),
                Text(
                  _formatAgentName(decision.requestedBy),
                  style: AppTypography.labelSmall(color: AppColors.primary),
                ),
              ],
            ),

            // Status info for approved/rejected
            if (!isPending && decision.reason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    decision.status == 'approved'
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: AppSpacing.iconSm,
                    color: decision.status == 'approved'
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          decision.status == 'approved'
                              ? 'Approved'
                              : 'Rejected',
                          style: AppTypography.labelMedium(
                            color: decision.status == 'approved'
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        if (decision.reason != null &&
                            decision.reason!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            decision.reason!,
                            style: AppTypography.bodySmall(
                                color: AppColors.textSecondary),
                          ),
                        ],
                        if (decision.decidedAt != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _formatTimestamp(decision.decidedAt!),
                            style: AppTypography.labelSmall(
                                color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons for pending
            if (isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: Icon(Icons.close,
                          size: AppSpacing.iconSm, color: AppColors.expense),
                      label: Text('Reject',
                          style: AppTypography.labelLarge(
                              color: AppColors.expense)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.expense),
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
                      onPressed: onApprove,
                      icon: Icon(Icons.check,
                          size: AppSpacing.iconSm,
                          color: AppColors.textPrimary),
                      label: Text('Approve',
                          style: AppTypography.labelLarge(
                              color: AppColors.textPrimary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final config = _typeConfig(type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            config.label,
            style: AppTypography.labelSmall(color: config.color),
          ),
        ],
      ),
    );
  }

  _TypeConfig _typeConfig(String type) {
    switch (type) {
      case 'merge':
        return _TypeConfig(
          icon: Icons.merge_type,
          label: 'MERGE',
          color: AppColors.income,
        );
      case 'deploy':
        return _TypeConfig(
          icon: Icons.rocket_launch,
          label: 'DEPLOY',
          color: AppColors.primary,
        );
      case 'architecture':
        return _TypeConfig(
          icon: Icons.architecture,
          label: 'ARCHITECTURE',
          color: AppColors.info,
        );
      case 'priority':
        return _TypeConfig(
          icon: Icons.priority_high,
          label: 'PRIORITY',
          color: AppColors.warning,
        );
      case 'abort':
        return _TypeConfig(
          icon: Icons.dangerous,
          label: 'ABORT',
          color: AppColors.expense,
        );
      default:
        return _TypeConfig(
          icon: Icons.help_outline,
          label: type.toUpperCase(),
          color: AppColors.textSecondary,
        );
    }
  }

  String _formatAgentName(String agent) {
    switch (agent.toLowerCase()) {
      case 'pm':
        return 'Project Manager';
      case 'dev':
        return 'Developer';
      case 'qa':
        return 'QA Engineer';
      default:
        return agent;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

class _TypeConfig {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}
