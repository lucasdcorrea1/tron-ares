import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_task_model.dart';
import '../../data/models/tron_repo_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronKanbanEvent extends Equatable {
  const TronKanbanEvent();
  @override
  List<Object?> get props => [];
}

class LoadKanbanEvent extends TronKanbanEvent {
  final String projectId;
  const LoadKanbanEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class FilterByRepoEvent extends TronKanbanEvent {
  final String? repoId;
  const FilterByRepoEvent(this.repoId);
  @override
  List<Object?> get props => [repoId];
}

class MoveTaskEvent extends TronKanbanEvent {
  final String projectId;
  final String taskId;
  final String newStatus;
  const MoveTaskEvent({
    required this.projectId,
    required this.taskId,
    required this.newStatus,
  });
  @override
  List<Object?> get props => [projectId, taskId, newStatus];
}

// State
class TronKanbanState extends Equatable {
  final List<TronTask> allTasks;
  final List<TronRepo> repos;
  final String? filterRepoId;
  final bool isLoading;
  final String? error;

  const TronKanbanState({
    this.allTasks = const [],
    this.repos = const [],
    this.filterRepoId,
    this.isLoading = false,
    this.error,
  });

  List<TronTask> get filteredTasks {
    if (filterRepoId == null) return allTasks;
    return allTasks.where((t) => t.repoId == filterRepoId).toList();
  }

  List<TronTask> get todoTasks =>
      filteredTasks.where((t) => t.status == 'todo').toList();
  List<TronTask> get inProgressTasks =>
      filteredTasks.where((t) => t.status == 'in_progress').toList();
  List<TronTask> get reviewTasks =>
      filteredTasks.where((t) => t.status == 'review').toList();
  List<TronTask> get doneTasks =>
      filteredTasks.where((t) => t.status == 'done').toList();

  TronKanbanState copyWith({
    List<TronTask>? allTasks,
    List<TronRepo>? repos,
    String? filterRepoId,
    bool? isLoading,
    String? error,
    bool clearFilter = false,
    bool clearError = false,
  }) {
    return TronKanbanState(
      allTasks: allTasks ?? this.allTasks,
      repos: repos ?? this.repos,
      filterRepoId: clearFilter ? null : filterRepoId ?? this.filterRepoId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props =>
      [allTasks, repos, filterRepoId, isLoading, error];
}

// Bloc
class TronKanbanBloc extends Bloc<TronKanbanEvent, TronKanbanState> {
  final TronApiService _apiService;

  TronKanbanBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronKanbanState()) {
    on<LoadKanbanEvent>(_onLoad);
    on<FilterByRepoEvent>(_onFilter);
    on<MoveTaskEvent>(_onMoveTask);
  }

  Future<void> _onLoad(
      LoadKanbanEvent event, Emitter<TronKanbanState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final results = await Future.wait([
        _apiService.getTasks(event.projectId),
        _apiService.getRepos(event.projectId),
      ]);

      emit(state.copyWith(
        allTasks: results[0] as List<TronTask>,
        repos: results[1] as List<TronRepo>,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onFilter(FilterByRepoEvent event, Emitter<TronKanbanState> emit) {
    if (event.repoId == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(filterRepoId: event.repoId));
    }
  }

  Future<void> _onMoveTask(
      MoveTaskEvent event, Emitter<TronKanbanState> emit) async {
    try {
      await _apiService.moveTask(
          event.projectId, event.taskId, event.newStatus);
      final updated = state.allTasks.map((t) {
        if (t.id == event.taskId) {
          return t.copyWith(status: event.newStatus);
        }
        return t;
      }).toList();
      emit(state.copyWith(allTasks: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
