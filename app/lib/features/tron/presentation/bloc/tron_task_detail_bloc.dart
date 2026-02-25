import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_task_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronTaskDetailEvent extends Equatable {
  const TronTaskDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadTaskDetailEvent extends TronTaskDetailEvent {
  final String projectId;
  final String taskId;
  const LoadTaskDetailEvent(
      {required this.projectId, required this.taskId});
  @override
  List<Object?> get props => [projectId, taskId];
}

class ApproveTaskEvent extends TronTaskDetailEvent {
  final String projectId;
  final String taskId;
  const ApproveTaskEvent(
      {required this.projectId, required this.taskId});
  @override
  List<Object?> get props => [projectId, taskId];
}

class RejectTaskEvent extends TronTaskDetailEvent {
  final String projectId;
  final String taskId;
  final String reason;
  const RejectTaskEvent({
    required this.projectId,
    required this.taskId,
    required this.reason,
  });
  @override
  List<Object?> get props => [projectId, taskId, reason];
}

// State
class TronTaskDetailState extends Equatable {
  final TronTask? task;
  final bool isLoading;
  final String? error;
  final String? actionMessage;

  const TronTaskDetailState({
    this.task,
    this.isLoading = false,
    this.error,
    this.actionMessage,
  });

  TronTaskDetailState copyWith({
    TronTask? task,
    bool? isLoading,
    String? error,
    String? actionMessage,
    bool clearError = false,
  }) {
    return TronTaskDetailState(
      task: task ?? this.task,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [task, isLoading, error, actionMessage];
}

// Bloc
class TronTaskDetailBloc
    extends Bloc<TronTaskDetailEvent, TronTaskDetailState> {
  final TronApiService _apiService;

  TronTaskDetailBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronTaskDetailState()) {
    on<LoadTaskDetailEvent>(_onLoad);
    on<ApproveTaskEvent>(_onApprove);
    on<RejectTaskEvent>(_onReject);
  }

  Future<void> _onLoad(
      LoadTaskDetailEvent event, Emitter<TronTaskDetailState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final task =
          await _apiService.getTask(event.projectId, event.taskId);
      emit(state.copyWith(task: task, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onApprove(
      ApproveTaskEvent event, Emitter<TronTaskDetailState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _apiService.updateTask(
        event.projectId,
        event.taskId,
        {'cio_decision': 'approved'},
      );
      final updated = state.task?.copyWith(cioDecision: 'approved');
      emit(state.copyWith(
        task: updated,
        isLoading: false,
        actionMessage: 'Task aprovada pelo CIO',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onReject(
      RejectTaskEvent event, Emitter<TronTaskDetailState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _apiService.updateTask(
        event.projectId,
        event.taskId,
        {'cio_decision': 'rejected', 'rejection_reason': event.reason},
      );
      final updated = state.task?.copyWith(cioDecision: 'rejected');
      emit(state.copyWith(
        task: updated,
        isLoading: false,
        actionMessage: 'Task rejeitada pelo CIO',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
