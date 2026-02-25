import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_agent_log_model.dart';
import '../../data/services/tron_api_service.dart';
import '../../data/services/tron_websocket_service.dart';

// Events
abstract class TronLogsEvent extends Equatable {
  const TronLogsEvent();
  @override
  List<Object?> get props => [];
}

class LoadLogsEvent extends TronLogsEvent {
  final String projectId;
  const LoadLogsEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class FilterLogsEvent extends TronLogsEvent {
  final String? agent;
  final String? repoId;
  const FilterLogsEvent({this.agent, this.repoId});
  @override
  List<Object?> get props => [agent, repoId];
}

class NewLogReceivedEvent extends TronLogsEvent {
  final TronAgentLog log;
  const NewLogReceivedEvent(this.log);
  @override
  List<Object?> get props => [log.id];
}

class ConnectWebSocketEvent extends TronLogsEvent {
  final String projectId;
  const ConnectWebSocketEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class DisconnectWebSocketEvent extends TronLogsEvent {
  const DisconnectWebSocketEvent();
}

// State
class TronLogsState extends Equatable {
  final List<TronAgentLog> logs;
  final String? filterAgent;
  final String? filterRepoId;
  final bool isLoading;
  final bool isWsConnected;
  final String? error;

  const TronLogsState({
    this.logs = const [],
    this.filterAgent,
    this.filterRepoId,
    this.isLoading = false,
    this.isWsConnected = false,
    this.error,
  });

  List<TronAgentLog> get filteredLogs {
    return logs.where((log) {
      if (filterAgent != null && log.agent != filterAgent) return false;
      if (filterRepoId != null && log.repoId != filterRepoId) return false;
      return true;
    }).toList();
  }

  TronLogsState copyWith({
    List<TronAgentLog>? logs,
    String? filterAgent,
    String? filterRepoId,
    bool? isLoading,
    bool? isWsConnected,
    String? error,
    bool clearAgent = false,
    bool clearRepo = false,
    bool clearError = false,
  }) {
    return TronLogsState(
      logs: logs ?? this.logs,
      filterAgent: clearAgent ? null : filterAgent ?? this.filterAgent,
      filterRepoId: clearRepo ? null : filterRepoId ?? this.filterRepoId,
      isLoading: isLoading ?? this.isLoading,
      isWsConnected: isWsConnected ?? this.isWsConnected,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props =>
      [logs, filterAgent, filterRepoId, isLoading, isWsConnected, error];
}

// Bloc
class TronLogsBloc extends Bloc<TronLogsEvent, TronLogsState> {
  final TronApiService _apiService;
  final TronWebSocketService _wsService;
  StreamSubscription<TronAgentLog>? _wsSubscription;

  TronLogsBloc({
    required TronApiService apiService,
    required TronWebSocketService wsService,
  })  : _apiService = apiService,
        _wsService = wsService,
        super(const TronLogsState()) {
    on<LoadLogsEvent>(_onLoad);
    on<FilterLogsEvent>(_onFilter);
    on<NewLogReceivedEvent>(_onNewLog);
    on<ConnectWebSocketEvent>(_onConnect);
    on<DisconnectWebSocketEvent>(_onDisconnect);
  }

  Future<void> _onLoad(
      LoadLogsEvent event, Emitter<TronLogsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final logs = await _apiService.getLogs(event.projectId, limit: 100);
      emit(state.copyWith(logs: logs, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onFilter(FilterLogsEvent event, Emitter<TronLogsState> emit) {
    emit(state.copyWith(
      filterAgent: event.agent,
      filterRepoId: event.repoId,
      clearAgent: event.agent == null,
      clearRepo: event.repoId == null,
    ));
  }

  void _onNewLog(NewLogReceivedEvent event, Emitter<TronLogsState> emit) {
    final updated = [event.log, ...state.logs];
    if (updated.length > 500) {
      updated.removeRange(500, updated.length);
    }
    emit(state.copyWith(logs: updated));
  }

  void _onConnect(
      ConnectWebSocketEvent event, Emitter<TronLogsState> emit) {
    _wsService.connect(event.projectId);
    _wsSubscription?.cancel();
    _wsSubscription = _wsService.logStream.listen((log) {
      add(NewLogReceivedEvent(log));
    });
    emit(state.copyWith(isWsConnected: true));
  }

  void _onDisconnect(
      DisconnectWebSocketEvent event, Emitter<TronLogsState> emit) {
    _wsSubscription?.cancel();
    _wsService.disconnect();
    emit(state.copyWith(isWsConnected: false));
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
