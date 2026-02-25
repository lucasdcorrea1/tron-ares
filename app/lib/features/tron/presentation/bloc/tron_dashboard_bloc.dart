import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_decision_model.dart';
import '../../data/models/tron_metrics_model.dart';
import '../../data/models/tron_repo_model.dart';
import '../../data/models/tron_agent_log_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronDashboardEvent extends Equatable {
  const TronDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardEvent extends TronDashboardEvent {
  final String projectId;
  const LoadDashboardEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class RefreshDashboardEvent extends TronDashboardEvent {
  final String projectId;
  const RefreshDashboardEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class RunAgentCycleEvent extends TronDashboardEvent {
  final String projectId;
  const RunAgentCycleEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

// State
class TronDashboardState extends Equatable {
  final TronMetrics? metrics;
  final List<TronRepo> repos;
  final List<TronDecision> pendingDecisions;
  final List<TronAgentLog> recentLogs;
  final bool isLoading;
  final bool isCycleRunning;
  final String? error;
  final String? successMessage;

  const TronDashboardState({
    this.metrics,
    this.repos = const [],
    this.pendingDecisions = const [],
    this.recentLogs = const [],
    this.isLoading = false,
    this.isCycleRunning = false,
    this.error,
    this.successMessage,
  });

  TronDashboardState copyWith({
    TronMetrics? metrics,
    List<TronRepo>? repos,
    List<TronDecision>? pendingDecisions,
    List<TronAgentLog>? recentLogs,
    bool? isLoading,
    bool? isCycleRunning,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TronDashboardState(
      metrics: metrics ?? this.metrics,
      repos: repos ?? this.repos,
      pendingDecisions: pendingDecisions ?? this.pendingDecisions,
      recentLogs: recentLogs ?? this.recentLogs,
      isLoading: isLoading ?? this.isLoading,
      isCycleRunning: isCycleRunning ?? this.isCycleRunning,
      error: clearError ? null : error ?? this.error,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        metrics,
        repos,
        pendingDecisions,
        recentLogs,
        isLoading,
        isCycleRunning,
        error,
        successMessage,
      ];
}

// Bloc
class TronDashboardBloc
    extends Bloc<TronDashboardEvent, TronDashboardState> {
  final TronApiService _apiService;

  TronDashboardBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronDashboardState()) {
    on<LoadDashboardEvent>(_onLoad);
    on<RefreshDashboardEvent>(_onRefresh);
    on<RunAgentCycleEvent>(_onRunCycle);
  }

  Future<void> _onLoad(
      LoadDashboardEvent event, Emitter<TronDashboardState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetchData(event.projectId, emit);
  }

  Future<void> _onRefresh(
      RefreshDashboardEvent event, Emitter<TronDashboardState> emit) async {
    await _fetchData(event.projectId, emit);
  }

  Future<void> _onRunCycle(
      RunAgentCycleEvent event, Emitter<TronDashboardState> emit) async {
    emit(state.copyWith(isCycleRunning: true, clearError: true));
    try {
      await _apiService.runAgentCycle(event.projectId);
      emit(state.copyWith(
        isCycleRunning: false,
        successMessage: 'Agent cycle queued! Agents are working...',
      ));
      // Refresh data after triggering
      await _fetchData(event.projectId, emit);
    } catch (e) {
      emit(state.copyWith(
        isCycleRunning: false,
        error: 'Failed to start cycle: ${e.toString()}',
      ));
    }
  }

  Future<void> _fetchData(
      String projectId, Emitter<TronDashboardState> emit) async {
    try {
      final results = await Future.wait([
        _apiService.getMetrics(projectId, days: 7),
        _apiService.getRepos(projectId),
        _apiService.getDecisions(projectId, status: 'pending'),
        _apiService.getLogs(projectId, limit: 20),
      ]);

      emit(state.copyWith(
        metrics: results[0] as TronMetrics,
        repos: results[1] as List<TronRepo>,
        pendingDecisions: results[2] as List<TronDecision>,
        recentLogs: results[3] as List<TronAgentLog>,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
