class TronRepo {
  final String id;
  final String userId;
  final String projectId;
  final String name;
  final String githubUrl;
  final TronRepoStack stack;
  final String health; // green, yellow, red
  final double testCoverage;
  final int commitsStreak;
  final bool claudeMdExists;
  final String localPath;
  // Stats from TronRepoResponse
  final int tasksInBacklog;
  final int tasksCompleted;
  final int tasksInDev;
  final DateTime? lastAnalyzedAt;
  final DateTime? lastCommitAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TronRepo({
    required this.id,
    this.userId = '',
    required this.projectId,
    required this.name,
    this.githubUrl = '',
    this.stack = const TronRepoStack(),
    this.health = 'green',
    this.testCoverage = 0,
    this.commitsStreak = 0,
    this.claudeMdExists = false,
    this.localPath = '',
    this.tasksInBacklog = 0,
    this.tasksCompleted = 0,
    this.tasksInDev = 0,
    this.lastAnalyzedAt,
    this.lastCommitAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Language shortcut from stack
  String get language => stack.language;

  /// Status derived from health for UI compatibility
  String get status => health;

  /// Stats object for UI compatibility
  TronRepoStats get stats => TronRepoStats(
        totalFiles: stack.fileCount,
        totalLines: stack.linesOfCode,
        openTasks: tasksInBacklog + tasksInDev,
        completedTasks: tasksCompleted,
        testCoverage: testCoverage,
        commitsToday: commitsStreak,
      );

  factory TronRepo.fromJson(Map<String, dynamic> json) {
    return TronRepo(
      id: _str(json['id']),
      userId: _str(json['user_id']),
      projectId: _str(json['project_id']),
      name: json['name'] as String? ?? '',
      githubUrl: json['github_url'] as String? ?? json['url'] as String? ?? '',
      stack: json['stack'] != null
          ? TronRepoStack.fromJson(json['stack'] as Map<String, dynamic>)
          : const TronRepoStack(),
      health: json['health'] as String? ?? 'green',
      testCoverage: (json['test_coverage'] as num?)?.toDouble() ?? 0,
      commitsStreak: (json['commits_streak'] as num?)?.toInt() ?? 0,
      claudeMdExists: json['claude_md_exists'] as bool? ?? false,
      localPath: json['local_path'] as String? ?? '',
      tasksInBacklog: (json['tasks_in_backlog'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      tasksInDev: (json['tasks_in_dev'] as num?)?.toInt() ?? 0,
      lastAnalyzedAt: _parseNullDate(json['last_analyzed_at']),
      lastCommitAt: _parseNullDate(json['last_commit_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'github_url': githubUrl,
      };
}

class TronRepoStack {
  final String language;
  final String framework;
  final String database;
  final List<String> tools;
  final int fileCount;
  final int linesOfCode;

  const TronRepoStack({
    this.language = '',
    this.framework = '',
    this.database = '',
    this.tools = const [],
    this.fileCount = 0,
    this.linesOfCode = 0,
  });

  factory TronRepoStack.fromJson(Map<String, dynamic> json) {
    return TronRepoStack(
      language: json['language'] as String? ?? '',
      framework: json['framework'] as String? ?? '',
      database: json['database'] as String? ?? '',
      tools: (json['tools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fileCount: (json['file_count'] as num?)?.toInt() ?? 0,
      linesOfCode: (json['lines_of_code'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Backwards-compatible stats object used by the UI
class TronRepoStats {
  final int totalFiles;
  final int totalLines;
  final int openTasks;
  final int completedTasks;
  final double testCoverage;
  final int commitsToday;

  const TronRepoStats({
    required this.totalFiles,
    required this.totalLines,
    required this.openTasks,
    required this.completedTasks,
    required this.testCoverage,
    required this.commitsToday,
  });

  factory TronRepoStats.empty() => const TronRepoStats(
        totalFiles: 0,
        totalLines: 0,
        openTasks: 0,
        completedTasks: 0,
        testCoverage: 0,
        commitsToday: 0,
      );

  factory TronRepoStats.fromJson(Map<String, dynamic> json) {
    return TronRepoStats(
      totalFiles: (json['total_files'] as num?)?.toInt() ?? 0,
      totalLines: (json['total_lines'] as num?)?.toInt() ?? 0,
      openTasks: (json['open_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      testCoverage: (json['test_coverage'] as num?)?.toDouble() ?? 0,
      commitsToday: (json['commits_today'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_files': totalFiles,
        'total_lines': totalLines,
        'open_tasks': openTasks,
        'completed_tasks': completedTasks,
        'test_coverage': testCoverage,
        'commits_today': commitsToday,
      };
}

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime _parseDate(dynamic v) {
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _parseNullDate(dynamic v) {
  if (v is String) return DateTime.tryParse(v);
  return null;
}
