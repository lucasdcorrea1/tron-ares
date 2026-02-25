class TronAgentLog {
  final String id;
  final String userId;
  final String projectId;
  final String? repoId;
  final String? taskId;
  final String agentType; // orchestrator, pm, dev, qa, etc
  final String action;
  final String inputSummary;
  final String outputSummary;
  final String? reasoning;
  final TronLogMetrics? metrics;
  final bool success;
  final String? error;
  final DateTime createdAt;

  const TronAgentLog({
    required this.id,
    this.userId = '',
    required this.projectId,
    this.repoId,
    this.taskId,
    required this.agentType,
    this.action = '',
    this.inputSummary = '',
    this.outputSummary = '',
    this.reasoning,
    this.metrics,
    this.success = true,
    this.error,
    required this.createdAt,
  });

  /// Backwards compat: agent = agentType
  String get agent => agentType;

  /// Backwards compat: level derived from success/error
  String get level {
    if (error != null && error!.isNotEmpty) return 'error';
    if (!success) return 'warning';
    return 'info';
  }

  /// Backwards compat: message = outputSummary or inputSummary
  String get message =>
      outputSummary.isNotEmpty ? outputSummary : inputSummary;

  /// Backwards compat: timestamp = createdAt
  DateTime get timestamp => createdAt;

  factory TronAgentLog.fromJson(Map<String, dynamic> json) {
    return TronAgentLog(
      id: _str(json['id']),
      userId: _str(json['user_id']),
      projectId: _str(json['project_id']),
      repoId: json['repo_id']?.toString(),
      taskId: json['task_id']?.toString(),
      agentType: json['agent_type'] as String? ??
          json['agent'] as String? ??
          'system',
      action: json['action'] as String? ?? '',
      inputSummary: json['input_summary'] as String? ?? '',
      outputSummary: json['output_summary'] as String? ??
          json['message'] as String? ??
          '',
      reasoning: json['reasoning'] as String?,
      metrics: json['metrics'] != null
          ? TronLogMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
      success: json['success'] as bool? ?? true,
      error: json['error'] as String?,
      createdAt: _date(json['created_at'] ?? json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'agent_type': agentType,
        'action': action,
        'output_summary': outputSummary,
        'success': success,
        'created_at': createdAt.toIso8601String(),
      };
}

class TronLogMetrics {
  final int durationMs;
  final int tokensInput;
  final int tokensOutput;
  final double costUsd;
  final String model;

  const TronLogMetrics({
    this.durationMs = 0,
    this.tokensInput = 0,
    this.tokensOutput = 0,
    this.costUsd = 0,
    this.model = '',
  });

  factory TronLogMetrics.fromJson(Map<String, dynamic> json) {
    return TronLogMetrics(
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      tokensInput: (json['tokens_input'] as num?)?.toInt() ?? 0,
      tokensOutput: (json['tokens_output'] as num?)?.toInt() ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0,
      model: json['model'] as String? ?? '',
    );
  }
}

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime _date(dynamic v) {
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}
