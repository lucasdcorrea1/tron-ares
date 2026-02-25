class TronDirective {
  final String id;
  final String userId;
  final String projectId;
  final String? repoId;
  final String content;
  final String priority; // normal, high, critical
  final String scope; // project, repo
  final bool active;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TronDirective({
    required this.id,
    this.userId = '',
    required this.projectId,
    this.repoId,
    required this.content,
    this.priority = 'normal',
    this.scope = 'project',
    this.active = true,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Backwards compat
  bool get isActive => active;
  String get createdBy => 'cio';
  DateTime? get deactivatedAt => active ? null : updatedAt;
  String? get targetAgent => null;
  String? get targetRepoId => repoId;

  factory TronDirective.fromJson(Map<String, dynamic> json) {
    return TronDirective(
      id: _str(json['id']),
      userId: _str(json['user_id']),
      projectId: _str(json['project_id']),
      repoId: json['repo_id']?.toString(),
      content: json['content'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      scope: json['scope'] as String? ?? 'project',
      active: json['active'] as bool? ?? json['is_active'] as bool? ?? true,
      expiresAt: _nullDate(json['expires_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'priority': priority,
        'scope': scope,
        'repo_id': repoId,
      };
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
