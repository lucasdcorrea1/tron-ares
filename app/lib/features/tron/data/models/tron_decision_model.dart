class TronDecision {
  final String id;
  final String userId;
  final String projectId;
  final String? repoId;
  final String? taskId;
  final int level; // 1=info, 2=normal, 3=critical
  final String agentType; // orchestrator, board, pm, dev, qa, integration
  final String title;
  final String description;
  final String? context;
  final List<TronDecisionOption> options;
  final String? chosenOption;
  final String status; // pending, approved, rejected, timeout, auto
  final DateTime? timeoutAt;
  final String? defaultOption;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime createdAt;

  const TronDecision({
    required this.id,
    this.userId = '',
    required this.projectId,
    this.repoId,
    this.taskId,
    this.level = 2,
    this.agentType = '',
    required this.title,
    required this.description,
    this.context,
    this.options = const [],
    this.chosenOption,
    required this.status,
    this.timeoutAt,
    this.defaultOption,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
  });

  /// Backwards compat: type = agentType for UI
  String get type => agentType.isNotEmpty ? agentType : 'merge';

  /// Backwards compat: requestedBy
  String get requestedBy => agentType;

  /// Backwards compat: reason = chosenOption description
  String? get reason => chosenOption;

  /// Backwards compat: decidedAt = resolvedAt
  DateTime? get decidedAt => resolvedAt;

  factory TronDecision.fromJson(Map<String, dynamic> json) {
    return TronDecision(
      id: _str(json['id']),
      userId: _str(json['user_id']),
      projectId: _str(json['project_id']),
      repoId: json['repo_id']?.toString(),
      taskId: json['task_id']?.toString(),
      level: (json['level'] as num?)?.toInt() ?? 2,
      agentType: json['agent_type'] as String? ??
          json['requested_by'] as String? ??
          '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      context: json['context'] is String
          ? json['context'] as String
          : json['context']?.toString(),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) =>
                  TronDecisionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chosenOption: json['chosen_option'] as String?,
      status: json['status'] as String? ?? 'pending',
      timeoutAt: _nullDate(json['timeout_at']),
      defaultOption: json['default_option'] as String?,
      resolvedAt: _nullDate(json['resolved_at']),
      resolvedBy: json['resolved_by'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'description': description,
        'status': status,
      };
}

class TronDecisionOption {
  final String id;
  final String label;
  final String description;
  final bool isDefault;
  final String impact;

  const TronDecisionOption({
    this.id = '',
    this.label = '',
    this.description = '',
    this.isDefault = false,
    this.impact = '',
  });

  factory TronDecisionOption.fromJson(Map<String, dynamic> json) {
    return TronDecisionOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      impact: json['impact'] as String? ?? '',
    );
  }
}

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime _date(dynamic v) {
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _nullDate(dynamic v) {
  if (v is String) return DateTime.tryParse(v);
  return null;
}
