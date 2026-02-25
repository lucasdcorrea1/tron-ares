class TronProject {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> references;
  final List<String> repos;
  final String frequency;
  final List<String> directives;
  final bool isActive;
  final double dailyBudget;
  // Stats from TronProjectResponse
  final int reposCount;
  final int tasksInBacklog;
  final int tasksCompleted;
  final double todayCostUsd;
  final int commitsToday;
  final String activeDirective;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TronProject({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    this.references = const [],
    this.repos = const [],
    this.frequency = 'normal',
    this.directives = const [],
    this.isActive = true,
    this.dailyBudget = 5.0,
    this.reposCount = 0,
    this.tasksInBacklog = 0,
    this.tasksCompleted = 0,
    this.todayCostUsd = 0,
    this.commitsToday = 0,
    this.activeDirective = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TronProject.fromJson(Map<String, dynamic> json) {
    return TronProject(
      id: _asString(json['id']),
      userId: _asString(json['user_id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      references: _asStringList(json['references']),
      repos: _asStringList(json['repos']),
      frequency: json['frequency'] as String? ?? 'normal',
      directives: _asStringList(json['directives']),
      isActive: json['is_active'] as bool? ?? true,
      dailyBudget: (json['daily_budget'] as num?)?.toDouble() ?? 5.0,
      reposCount: (json['repos_count'] as num?)?.toInt() ?? 0,
      tasksInBacklog: (json['tasks_in_backlog'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      todayCostUsd: (json['today_cost_usd'] as num?)?.toDouble() ?? 0,
      commitsToday: (json['commits_today'] as num?)?.toInt() ?? 0,
      activeDirective: json['active_directive'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'references': references,
        'frequency': frequency,
        'is_active': isActive,
        'daily_budget': dailyBudget,
      };

  TronProject copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? references,
    List<String>? repos,
    String? frequency,
    List<String>? directives,
    bool? isActive,
    double? dailyBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TronProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      references: references ?? this.references,
      repos: repos ?? this.repos,
      frequency: frequency ?? this.frequency,
      directives: directives ?? this.directives,
      isActive: isActive ?? this.isActive,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Keep for backward compatibility but unused now
class TronProjectConfig {
  final bool autoAssign;
  final bool autoMerge;
  final bool requireCioApproval;
  final int maxConcurrentTasks;
  final String defaultBranch;

  const TronProjectConfig({
    required this.autoAssign,
    required this.autoMerge,
    required this.requireCioApproval,
    required this.maxConcurrentTasks,
    required this.defaultBranch,
  });

  factory TronProjectConfig.empty() => const TronProjectConfig(
        autoAssign: true,
        autoMerge: false,
        requireCioApproval: true,
        maxConcurrentTasks: 3,
        defaultBranch: 'main',
      );

  factory TronProjectConfig.fromJson(Map<String, dynamic> json) {
    return TronProjectConfig(
      autoAssign: json['auto_assign'] as bool? ?? true,
      autoMerge: json['auto_merge'] as bool? ?? false,
      requireCioApproval: json['require_cio_approval'] as bool? ?? true,
      maxConcurrentTasks: (json['max_concurrent_tasks'] as num?)?.toInt() ?? 3,
      defaultBranch: json['default_branch'] as String? ?? 'main',
    );
  }

  Map<String, dynamic> toJson() => {
        'auto_assign': autoAssign,
        'auto_merge': autoMerge,
        'require_cio_approval': requireCioApproval,
        'max_concurrent_tasks': maxConcurrentTasks,
        'default_branch': defaultBranch,
      };
}

// -- Safe parsing helpers --

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

List<String> _asStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
