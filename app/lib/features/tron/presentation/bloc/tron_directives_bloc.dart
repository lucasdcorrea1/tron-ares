import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_directive_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronDirectivesEvent extends Equatable {
  const TronDirectivesEvent();
  @override
  List<Object?> get props => [];
}

class LoadDirectivesEvent extends TronDirectivesEvent {
  final String projectId;
  const LoadDirectivesEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class CreateDirectiveEvent extends TronDirectivesEvent {
  final String projectId;
  final String content;
  final String scope;
  final String? targetRepoId;
  final String? targetAgent;
  const CreateDirectiveEvent({
    required this.projectId,
    required this.content,
    required this.scope,
    this.targetRepoId,
    this.targetAgent,
  });
  @override
  List<Object?> get props =>
      [projectId, content, scope, targetRepoId, targetAgent];
}

class DeactivateDirectiveEvent extends TronDirectivesEvent {
  final String projectId;
  final String directiveId;
  const DeactivateDirectiveEvent({
    required this.projectId,
    required this.directiveId,
  });
  @override
  List<Object?> get props => [projectId, directiveId];
}

// State
class TronDirectivesState extends Equatable {
  final List<TronDirective> directives;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TronDirectivesState({
    this.directives = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  List<TronDirective> get activeDirectives =>
      directives.where((d) => d.isActive).toList();

  List<TronDirective> get inactiveDirectives =>
      directives.where((d) => !d.isActive).toList();

  TronDirectivesState copyWith({
    List<TronDirective>? directives,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
  }) {
    return TronDirectivesState(
      directives: directives ?? this.directives,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [directives, isLoading, error, successMessage];
}

// Bloc
class TronDirectivesBloc
    extends Bloc<TronDirectivesEvent, TronDirectivesState> {
  final TronApiService _apiService;

  TronDirectivesBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronDirectivesState()) {
    on<LoadDirectivesEvent>(_onLoad);
    on<CreateDirectiveEvent>(_onCreate);
    on<DeactivateDirectiveEvent>(_onDeactivate);
  }

  Future<void> _onLoad(
      LoadDirectivesEvent event, Emitter<TronDirectivesState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final directives = await _apiService.getDirectives(event.projectId);
      emit(state.copyWith(directives: directives, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreate(
      CreateDirectiveEvent event, Emitter<TronDirectivesState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final directive = await _apiService.createDirective(
        event.projectId,
        {
          'content': event.content,
          'scope': event.scope,
          'target_repo_id': event.targetRepoId,
          'target_agent': event.targetAgent,
        },
      );
      final updated = [directive, ...state.directives];
      emit(state.copyWith(
        directives: updated,
        isLoading: false,
        successMessage: 'Diretiva criada',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDeactivate(
      DeactivateDirectiveEvent event,
      Emitter<TronDirectivesState> emit) async {
    try {
      await _apiService.deactivateDirective(
          event.projectId, event.directiveId);
      final updated = state.directives.map((d) {
        if (d.id == event.directiveId) {
          return TronDirective.fromJson({
            ...d.toJson(),
            'is_active': false,
            'deactivated_at': DateTime.now().toIso8601String(),
          });
        }
        return d;
      }).toList();
      emit(state.copyWith(directives: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
