import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_metrics_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronAgentsEvent extends Equatable {
  const TronAgentsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAgentsEvent extends TronAgentsEvent {
  final String projectId;
  const LoadAgentsEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

// State
class TronAgentsState extends Equatable {
  final Map<String, TronAgentMetrics> agents;
  final bool isLoading;
  final String? error;

  const TronAgentsState({
    this.agents = const {},
    this.isLoading = false,
    this.error,
  });

  TronAgentsState copyWith({
    Map<String, TronAgentMetrics>? agents,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TronAgentsState(
      agents: agents ?? this.agents,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [agents, isLoading, error];
}

// Bloc
class TronAgentsBloc extends Bloc<TronAgentsEvent, TronAgentsState> {
  final TronApiService _apiService;

  TronAgentsBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronAgentsState()) {
    on<LoadAgentsEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadAgentsEvent event, Emitter<TronAgentsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final agents = await _apiService.getAgentsStatus(event.projectId);
      emit(state.copyWith(agents: agents, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
