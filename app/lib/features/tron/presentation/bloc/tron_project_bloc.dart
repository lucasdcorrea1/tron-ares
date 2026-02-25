import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_project_model.dart';
import '../../data/models/tron_repo_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronProjectEvent extends Equatable {
  const TronProjectEvent();
  @override
  List<Object?> get props => [];
}

class LoadProjectsEvent extends TronProjectEvent {
  const LoadProjectsEvent();
}

class SelectProjectEvent extends TronProjectEvent {
  final TronProject project;
  const SelectProjectEvent(this.project);
  @override
  List<Object?> get props => [project.id];
}

class CreateProjectEvent extends TronProjectEvent {
  final String name;
  final String description;
  const CreateProjectEvent({required this.name, required this.description});
  @override
  List<Object?> get props => [name, description];
}

class ImportRepoEvent extends TronProjectEvent {
  final String projectId;
  final String repoUrl;
  const ImportRepoEvent({required this.projectId, required this.repoUrl});
  @override
  List<Object?> get props => [projectId, repoUrl];
}

class LoadReposEvent extends TronProjectEvent {
  final String projectId;
  const LoadReposEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

// State
class TronProjectState extends Equatable {
  final List<TronProject> projects;
  final TronProject? selectedProject;
  final List<TronRepo> repos;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TronProjectState({
    this.projects = const [],
    this.selectedProject,
    this.repos = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TronProjectState copyWith({
    List<TronProject>? projects,
    TronProject? selectedProject,
    List<TronRepo>? repos,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TronProjectState(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      repos: repos ?? this.repos,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props =>
      [projects, selectedProject, repos, isLoading, error, successMessage];
}

// Bloc
class TronProjectBloc extends Bloc<TronProjectEvent, TronProjectState> {
  final TronApiService _apiService;

  TronProjectBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronProjectState()) {
    on<LoadProjectsEvent>(_onLoadProjects);
    on<SelectProjectEvent>(_onSelectProject);
    on<CreateProjectEvent>(_onCreateProject);
    on<ImportRepoEvent>(_onImportRepo);
    on<LoadReposEvent>(_onLoadRepos);
  }

  Future<void> _onLoadProjects(
      LoadProjectsEvent event, Emitter<TronProjectState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final projects = await _apiService.getProjects();
      emit(state.copyWith(
        projects: projects,
        isLoading: false,
        selectedProject:
            projects.isNotEmpty ? projects.first : null,
      ));
      if (projects.isNotEmpty) {
        add(LoadReposEvent(projects.first.id));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSelectProject(
      SelectProjectEvent event, Emitter<TronProjectState> emit) async {
    emit(state.copyWith(selectedProject: event.project));
    add(LoadReposEvent(event.project.id));
  }

  Future<void> _onCreateProject(
      CreateProjectEvent event, Emitter<TronProjectState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final project = await _apiService.createProject(
        name: event.name,
        description: event.description,
      );
      final updated = [...state.projects, project];
      emit(state.copyWith(
        projects: updated,
        selectedProject: project,
        isLoading: false,
        successMessage: 'Projeto criado com sucesso',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onImportRepo(
      ImportRepoEvent event, Emitter<TronProjectState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final repo =
          await _apiService.importRepo(event.projectId, event.repoUrl);
      final updated = [...state.repos, repo];
      emit(state.copyWith(
        repos: updated,
        isLoading: false,
        successMessage: 'Repositorio importado',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadRepos(
      LoadReposEvent event, Emitter<TronProjectState> emit) async {
    try {
      final repos = await _apiService.getRepos(event.projectId);
      emit(state.copyWith(repos: repos));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
