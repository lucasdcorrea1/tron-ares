import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/tron_project_model.dart';
import '../models/tron_repo_model.dart';
import '../models/tron_task_model.dart';
import '../models/tron_agent_log_model.dart';
import '../models/tron_decision_model.dart';
import '../models/tron_directive_model.dart';
import '../models/tron_metrics_model.dart';

/// Helper to safely extract a list from response data.
/// Backend may return: a raw List, a Map with a key, or null.
List<dynamic> _extractList(dynamic data, [String? key]) {
  if (data == null) return [];
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    if (key != null && data.containsKey(key)) {
      final val = data[key];
      if (val is List) return val;
    }
    // Try common wrapper keys
    for (final k in ['data', 'items', 'results']) {
      if (data.containsKey(k) && data[k] is List) return data[k] as List;
    }
  }
  return [];
}

/// Helper to safely extract a map from response data.
Map<String, dynamic> _extractMap(dynamic data, [String? key]) {
  if (data == null) return {};
  if (data is Map<String, dynamic>) {
    if (key != null && data.containsKey(key)) {
      final val = data[key];
      if (val is Map<String, dynamic>) return val;
    }
    return data;
  }
  return {};
}

class TronApiService {
  final ApiClient _apiClient;

  TronApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Dio get _dio => _apiClient.dio;

  // ==================== Projects ====================

  Future<List<TronProject>> getProjects() async {
    final response = await _dio.get('/tron/projects');
    final list = _extractList(response.data);
    return list
        .map((e) => TronProject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TronProject> getProject(String id) async {
    final response = await _dio.get('/tron/projects/$id');
    return TronProject.fromJson(_extractMap(response.data));
  }

  Future<TronProject> createProject({
    required String name,
    required String description,
  }) async {
    final response = await _dio.post('/tron/projects', data: {
      'name': name,
      'description': description,
    });
    return TronProject.fromJson(_extractMap(response.data));
  }

  Future<TronProject> updateProject(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tron/projects/$id', data: data);
    return TronProject.fromJson(_extractMap(response.data));
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete('/tron/projects/$id');
  }

  // ==================== Repos ====================

  Future<List<TronRepo>> getRepos(String projectId) async {
    final response =
        await _dio.get('/tron/projects/$projectId/repos');
    final list = _extractList(response.data);
    return list
        .map((e) => TronRepo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TronRepo> importRepo(String projectId, String repoUrl) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/repos',
      data: {'url': repoUrl},
    );
    return TronRepo.fromJson(_extractMap(response.data));
  }

  Future<TronRepo> createRepo(
      String projectId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/repos/create',
      data: data,
    );
    return TronRepo.fromJson(_extractMap(response.data));
  }

  Future<void> deleteRepo(String projectId, String repoId) async {
    await _dio.delete('/tron/projects/$projectId/repos/$repoId');
  }

  Future<TronRepo> analyzeRepo(String projectId, String repoId) async {
    final response =
        await _dio.post('/tron/projects/$projectId/repos/$repoId/analyze');
    return TronRepo.fromJson(_extractMap(response.data));
  }

  // ==================== Tasks ====================

  Future<List<TronTask>> getTasks(String projectId,
      {String? repoId, String? status}) async {
    final queryParams = <String, dynamic>{};
    if (repoId != null) queryParams['repo_id'] = repoId;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '/tron/projects/$projectId/tasks',
      queryParameters: queryParams,
    );
    final list = _extractList(response.data, 'tasks');
    return list
        .map((e) => TronTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TronTask> getTask(String projectId, String taskId) async {
    final response =
        await _dio.get('/tron/projects/$projectId/tasks/$taskId');
    return TronTask.fromJson(_extractMap(response.data));
  }

  Future<TronTask> createTask(
      String projectId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/tasks',
      data: data,
    );
    return TronTask.fromJson(_extractMap(response.data));
  }

  Future<TronTask> updateTask(
      String projectId, String taskId, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '/tron/projects/$projectId/tasks/$taskId',
      data: data,
    );
    return TronTask.fromJson(_extractMap(response.data));
  }

  Future<TronTask> moveTask(
      String projectId, String taskId, String newStatus) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/tasks/$taskId/move',
      data: {'status': newStatus},
    );
    return TronTask.fromJson(_extractMap(response.data));
  }

  // ==================== Decisions (CIO) ====================

  Future<List<TronDecision>> getDecisions(String projectId,
      {String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '/tron/projects/$projectId/decisions',
      queryParameters: queryParams,
    );
    final list = _extractList(response.data, 'decisions');
    return list
        .map((e) => TronDecision.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TronDecision> approveDecision(
      String projectId, String decisionId, String? reason) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/decisions/$decisionId/approve',
      data: {'reason': reason},
    );
    return TronDecision.fromJson(_extractMap(response.data));
  }

  Future<TronDecision> rejectDecision(
      String projectId, String decisionId, String reason) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/decisions/$decisionId/reject',
      data: {'reason': reason},
    );
    return TronDecision.fromJson(_extractMap(response.data));
  }

  // ==================== Directives ====================

  Future<List<TronDirective>> getDirectives(String projectId,
      {bool? activeOnly}) async {
    final queryParams = <String, dynamic>{};
    if (activeOnly != null) queryParams['active_only'] = activeOnly;

    final response = await _dio.get(
      '/tron/projects/$projectId/directives',
      queryParameters: queryParams,
    );
    final list = _extractList(response.data, 'directives');
    return list
        .map((e) => TronDirective.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TronDirective> createDirective(
      String projectId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/tron/projects/$projectId/directives',
      data: data,
    );
    return TronDirective.fromJson(_extractMap(response.data));
  }

  Future<void> deactivateDirective(
      String projectId, String directiveId) async {
    await _dio
        .post('/tron/projects/$projectId/directives/$directiveId/deactivate');
  }

  // ==================== Metrics ====================

  Future<TronMetrics> getMetrics(String projectId, {int? days}) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;

    final response = await _dio.get(
      '/tron/projects/$projectId/metrics',
      queryParameters: queryParams,
    );
    return TronMetrics.fromJson(_extractMap(response.data));
  }

  // ==================== Logs ====================

  Future<List<TronAgentLog>> getLogs(String projectId,
      {String? agent, String? repoId, int? limit}) async {
    final queryParams = <String, dynamic>{};
    if (agent != null) queryParams['agent'] = agent;
    if (repoId != null) queryParams['repo_id'] = repoId;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _dio.get(
      '/tron/projects/$projectId/logs',
      queryParameters: queryParams,
    );
    final list = _extractList(response.data, 'logs');
    return list
        .map((e) => TronAgentLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==================== Agent Cycle ====================

  /// Trigger a manual agent cycle for the project
  Future<void> runAgentCycle(String projectId) async {
    await _dio.post('/tron/projects/$projectId/agents/run');
  }

  // ==================== Agents ====================

  Future<Map<String, TronAgentMetrics>> getAgentsStatus(
      String projectId) async {
    final response =
        await _dio.get('/tron/projects/$projectId/agents');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Try to extract agents map - could be direct or nested
      final map = data.containsKey('agents')
          ? data['agents'] as Map<String, dynamic>? ?? {}
          : data;
      return map.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, TronAgentMetrics.fromJson(value));
        }
        return MapEntry(key, TronAgentMetrics.empty(key));
      });
    }
    return {};
  }
}
