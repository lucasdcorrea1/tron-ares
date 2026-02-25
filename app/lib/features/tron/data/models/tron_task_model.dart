class TronTask {
  final String id;
  final String projectId;
  final String repoId;
  final String title;
  final String description;
  final String status; // backlog, todo, in_progress, review, done
  final String priority; // low, medium, high, critical
  final String type; // feature, bugfix, refactor, test, docs
  final String assignedAgent; // pm, dev, qa, none
  final String branch;
  final List<TronCommit> commits;
  final TronTaskTimeline timeline;
  final String cioDecision; // pending, approved, rejected, none
  final String diffUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TronTask({
    required this.id,
    required this.projectId,
    required this.repoId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.type,
    required this.assignedAgent,
    required this.branch,
    required this.commits,
    required this.timeline,
    required this.cioDecision,
    required this.diffUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TronTask.fromJson(Map<String, dynamic> json) {
    return TronTask(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      repoId: json['repo_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'backlog',
      priority: json['priority'] as String? ?? 'medium',
      type: json['type'] as String? ?? 'feature',
      assignedAgent: json['assigned_agent'] as String? ?? 'none',
      branch: json['branch'] as String? ?? '',
      commits: (json['commits'] as List<dynamic>?)
              ?.map(
                  (e) => TronCommit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: json['timeline'] != null
          ? TronTaskTimeline.fromJson(json['timeline'] as Map<String, dynamic>)
          : TronTaskTimeline.empty(),
      cioDecision: json['cio_decision'] as String? ?? 'none',
      diffUrl: json['diff_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'repo_id': repoId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'type': type,
        'assigned_agent': assignedAgent,
        'branch': branch,
        'commits': commits.map((e) => e.toJson()).toList(),
        'timeline': timeline.toJson(),
        'cio_decision': cioDecision,
        'diff_url': diffUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  TronTask copyWith({
    String? status,
    String? assignedAgent,
    String? cioDecision,
    List<TronCommit>? commits,
    TronTaskTimeline? timeline,
  }) {
    return TronTask(
      id: id,
      projectId: projectId,
      repoId: repoId,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      type: type,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      branch: branch,
      commits: commits ?? this.commits,
      timeline: timeline ?? this.timeline,
      cioDecision: cioDecision ?? this.cioDecision,
      diffUrl: diffUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class TronCommit {
  final String sha;
  final String message;
  final String author;
  final int additions;
  final int deletions;
  final DateTime timestamp;

  const TronCommit({
    required this.sha,
    required this.message,
    required this.author,
    required this.additions,
    required this.deletions,
    required this.timestamp,
  });

  factory TronCommit.fromJson(Map<String, dynamic> json) {
    return TronCommit(
      sha: json['sha'] as String? ?? '',
      message: json['message'] as String? ?? '',
      author: json['author'] as String? ?? '',
      additions: json['additions'] as int? ?? 0,
      deletions: json['deletions'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sha': sha,
        'message': message,
        'author': author,
        'additions': additions,
        'deletions': deletions,
        'timestamp': timestamp.toIso8601String(),
      };
}

class TronTaskTimeline {
  final DateTime? pmStartedAt;
  final DateTime? pmCompletedAt;
  final DateTime? devStartedAt;
  final DateTime? devCompletedAt;
  final DateTime? qaStartedAt;
  final DateTime? qaCompletedAt;
  final DateTime? cioReviewedAt;

  const TronTaskTimeline({
    this.pmStartedAt,
    this.pmCompletedAt,
    this.devStartedAt,
    this.devCompletedAt,
    this.qaStartedAt,
    this.qaCompletedAt,
    this.cioReviewedAt,
  });

  factory TronTaskTimeline.empty() => const TronTaskTimeline();

  factory TronTaskTimeline.fromJson(Map<String, dynamic> json) {
    return TronTaskTimeline(
      pmStartedAt: json['pm_started_at'] != null
          ? DateTime.parse(json['pm_started_at'] as String)
          : null,
      pmCompletedAt: json['pm_completed_at'] != null
          ? DateTime.parse(json['pm_completed_at'] as String)
          : null,
      devStartedAt: json['dev_started_at'] != null
          ? DateTime.parse(json['dev_started_at'] as String)
          : null,
      devCompletedAt: json['dev_completed_at'] != null
          ? DateTime.parse(json['dev_completed_at'] as String)
          : null,
      qaStartedAt: json['qa_started_at'] != null
          ? DateTime.parse(json['qa_started_at'] as String)
          : null,
      qaCompletedAt: json['qa_completed_at'] != null
          ? DateTime.parse(json['qa_completed_at'] as String)
          : null,
      cioReviewedAt: json['cio_reviewed_at'] != null
          ? DateTime.parse(json['cio_reviewed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'pm_started_at': pmStartedAt?.toIso8601String(),
        'pm_completed_at': pmCompletedAt?.toIso8601String(),
        'dev_started_at': devStartedAt?.toIso8601String(),
        'dev_completed_at': devCompletedAt?.toIso8601String(),
        'qa_started_at': qaStartedAt?.toIso8601String(),
        'qa_completed_at': qaCompletedAt?.toIso8601String(),
        'cio_reviewed_at': cioReviewedAt?.toIso8601String(),
      };

  String get currentPhase {
    if (qaCompletedAt != null) return 'done';
    if (qaStartedAt != null) return 'qa';
    if (devCompletedAt != null) return 'review';
    if (devStartedAt != null) return 'dev';
    if (pmCompletedAt != null) return 'ready';
    if (pmStartedAt != null) return 'pm';
    return 'backlog';
  }
}
