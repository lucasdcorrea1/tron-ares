/// Matches Go backend's TronMetricsResponse
class TronMetrics {
  final TronMetricsPeriod? today;
  final TronMetricsPeriod? week;
  final TronMetricsPeriod? month;
  final List<TronDailyMetric> daily;
  final List<TronRepoMetric> byRepo;
  final List<TronAgentMetricEntry> byAgent;

  const TronMetrics({
    this.today,
    this.week,
    this.month,
    this.daily = const [],
    this.byRepo = const [],
    this.byAgent = const [],
  });

  /// Backwards compat: agents map from byAgent list
  Map<String, TronAgentMetrics> get agents {
    final map = <String, TronAgentMetrics>{};
    for (final a in byAgent) {
      map[a.agentType] = TronAgentMetrics(
        agent: a.agentType,
        status: 'active',
        tasksCompleted: 0,
        commitsToday: 0,
        lastActiveAt: DateTime.now(),
      );
    }
    return map;
  }

  /// Backwards-compatible summary for the dashboard UI
  TronMetricsSummary get summary => TronMetricsSummary(
        totalTasks: today?.tasksCompleted ?? 0,
        completedTasks: today?.tasksCompleted ?? 0,
        openTasks: 0,
        totalCommits: today?.commitsTotal ?? 0,
        commitsToday: today?.commitsTotal ?? 0,
        testCoverage: 0,
        estimatedCostUsd: today?.totalCostUsd ?? 0,
        pendingDecisions: 0,
        activeAgents: byAgent.length,
      );

  factory TronMetrics.fromJson(Map<String, dynamic> json) {
    return TronMetrics(
      today: json['today'] != null
          ? TronMetricsPeriod.fromJson(json['today'] as Map<String, dynamic>)
          : null,
      week: json['week'] != null
          ? TronMetricsPeriod.fromJson(json['week'] as Map<String, dynamic>)
          : null,
      month: json['month'] != null
          ? TronMetricsPeriod.fromJson(json['month'] as Map<String, dynamic>)
          : null,
      daily: (json['daily'] as List<dynamic>?)
              ?.map(
                  (e) => TronDailyMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      byRepo: (json['by_repo'] as List<dynamic>?)
              ?.map(
                  (e) => TronRepoMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      byAgent: (json['by_agent'] as List<dynamic>?)
              ?.map((e) =>
                  TronAgentMetricEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'today': today?.toJson(),
        'week': week?.toJson(),
        'month': month?.toJson(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'by_repo': byRepo.map((e) => e.toJson()).toList(),
        'by_agent': byAgent.map((e) => e.toJson()).toList(),
      };
}

class TronMetricsPeriod {
  final String period;
  final int commitsTotal;
  final int tasksCompleted;
  final int tasksRejected;
  final double approvalRate;
  final double totalCostUsd;
  final int totalTokens;
  final double avgCostPerTask;
  final int commitsStreak;

  const TronMetricsPeriod({
    this.period = '',
    this.commitsTotal = 0,
    this.tasksCompleted = 0,
    this.tasksRejected = 0,
    this.approvalRate = 0,
    this.totalCostUsd = 0,
    this.totalTokens = 0,
    this.avgCostPerTask = 0,
    this.commitsStreak = 0,
  });

  factory TronMetricsPeriod.fromJson(Map<String, dynamic> json) {
    return TronMetricsPeriod(
      period: json['period'] as String? ?? '',
      commitsTotal: (json['commits_total'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      tasksRejected: (json['tasks_rejected'] as num?)?.toInt() ?? 0,
      approvalRate: (json['approval_rate'] as num?)?.toDouble() ?? 0,
      totalCostUsd: (json['total_cost_usd'] as num?)?.toDouble() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      avgCostPerTask: (json['avg_cost_per_task'] as num?)?.toDouble() ?? 0,
      commitsStreak: (json['commits_streak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'commits_total': commitsTotal,
        'tasks_completed': tasksCompleted,
        'tasks_rejected': tasksRejected,
        'approval_rate': approvalRate,
        'total_cost_usd': totalCostUsd,
        'total_tokens': totalTokens,
        'avg_cost_per_task': avgCostPerTask,
        'commits_streak': commitsStreak,
      };
}

class TronDailyMetric {
  final DateTime date;
  final int commits;
  final int tasksCompleted;
  final double costUsd;

  const TronDailyMetric({
    required this.date,
    this.commits = 0,
    this.tasksCompleted = 0,
    this.costUsd = 0,
  });

  factory TronDailyMetric.fromJson(Map<String, dynamic> json) {
    return TronDailyMetric(
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      commits: (json['commits'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'commits': commits,
        'tasks_completed': tasksCompleted,
        'cost_usd': costUsd,
      };
}

class TronRepoMetric {
  final String repoId;
  final String repoName;
  final int commitsTotal;
  final int tasksCompleted;
  final double costUsd;
  final String health;

  const TronRepoMetric({
    this.repoId = '',
    this.repoName = '',
    this.commitsTotal = 0,
    this.tasksCompleted = 0,
    this.costUsd = 0,
    this.health = 'green',
  });

  factory TronRepoMetric.fromJson(Map<String, dynamic> json) {
    return TronRepoMetric(
      repoId: json['repo_id']?.toString() ?? '',
      repoName: json['repo_name'] as String? ?? '',
      commitsTotal: (json['commits_total'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0,
      health: json['health'] as String? ?? 'green',
    );
  }

  Map<String, dynamic> toJson() => {
        'repo_id': repoId,
        'repo_name': repoName,
        'commits_total': commitsTotal,
        'tasks_completed': tasksCompleted,
        'cost_usd': costUsd,
        'health': health,
      };
}

class TronAgentMetricEntry {
  final String agentType;
  final int totalRuns;
  final double successRate;
  final double totalCostUsd;
  final int totalTokens;
  final int avgDurationMs;

  const TronAgentMetricEntry({
    this.agentType = '',
    this.totalRuns = 0,
    this.successRate = 0,
    this.totalCostUsd = 0,
    this.totalTokens = 0,
    this.avgDurationMs = 0,
  });

  factory TronAgentMetricEntry.fromJson(Map<String, dynamic> json) {
    return TronAgentMetricEntry(
      agentType: json['agent_type'] as String? ?? '',
      totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0,
      totalCostUsd: (json['total_cost_usd'] as num?)?.toDouble() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      avgDurationMs: (json['avg_duration_ms'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'agent_type': agentType,
        'total_runs': totalRuns,
        'success_rate': successRate,
        'total_cost_usd': totalCostUsd,
        'total_tokens': totalTokens,
        'avg_duration_ms': avgDurationMs,
      };
}

/// Backwards-compatible summary used by the dashboard UI
class TronMetricsSummary {
  final int totalTasks;
  final int completedTasks;
  final int openTasks;
  final int totalCommits;
  final int commitsToday;
  final double testCoverage;
  final double estimatedCostUsd;
  final int pendingDecisions;
  final int activeAgents;

  const TronMetricsSummary({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.openTasks = 0,
    this.totalCommits = 0,
    this.commitsToday = 0,
    this.testCoverage = 0,
    this.estimatedCostUsd = 0,
    this.pendingDecisions = 0,
    this.activeAgents = 0,
  });

  factory TronMetricsSummary.empty() => const TronMetricsSummary();

  factory TronMetricsSummary.fromJson(Map<String, dynamic> json) {
    return TronMetricsSummary(
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      openTasks: (json['open_tasks'] as num?)?.toInt() ?? 0,
      totalCommits: (json['total_commits'] as num?)?.toInt() ?? 0,
      commitsToday: (json['commits_today'] as num?)?.toInt() ?? 0,
      testCoverage: (json['test_coverage'] as num?)?.toDouble() ?? 0,
      estimatedCostUsd:
          (json['estimated_cost_usd'] as num?)?.toDouble() ?? 0,
      pendingDecisions: (json['pending_decisions'] as num?)?.toInt() ?? 0,
      activeAgents: (json['active_agents'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'open_tasks': openTasks,
        'total_commits': totalCommits,
        'commits_today': commitsToday,
        'test_coverage': testCoverage,
        'estimated_cost_usd': estimatedCostUsd,
        'pending_decisions': pendingDecisions,
        'active_agents': activeAgents,
      };
}

/// Agent metrics used by the agents page and agents status endpoint
class TronAgentMetrics {
  final String agent;
  final String status;
  final int tasksCompleted;
  final int tasksInProgress;
  final int commitsToday;
  final double avgTaskDurationMinutes;
  final DateTime lastActiveAt;

  const TronAgentMetrics({
    required this.agent,
    this.status = 'offline',
    this.tasksCompleted = 0,
    this.tasksInProgress = 0,
    this.commitsToday = 0,
    this.avgTaskDurationMinutes = 0,
    required this.lastActiveAt,
  });

  factory TronAgentMetrics.empty(String agentName) => TronAgentMetrics(
        agent: agentName,
        lastActiveAt: DateTime.now(),
      );

  factory TronAgentMetrics.fromJson(Map<String, dynamic> json) {
    return TronAgentMetrics(
      agent: json['agent'] as String? ??
          json['agent_type'] as String? ??
          '',
      status: json['status'] as String? ?? 'offline',
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      tasksInProgress: (json['tasks_in_progress'] as num?)?.toInt() ?? 0,
      commitsToday: (json['commits_today'] as num?)?.toInt() ?? 0,
      avgTaskDurationMinutes:
          (json['avg_task_duration_minutes'] as num?)?.toDouble() ??
              ((json['avg_duration_ms'] as num?)?.toDouble() ?? 0) / 60000,
      lastActiveAt: json['last_active_at'] != null
          ? (DateTime.tryParse(json['last_active_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'agent': agent,
        'status': status,
        'tasks_completed': tasksCompleted,
        'tasks_in_progress': tasksInProgress,
        'commits_today': commitsToday,
        'avg_task_duration_minutes': avgTaskDurationMinutes,
        'last_active_at': lastActiveAt.toIso8601String(),
      };
}
