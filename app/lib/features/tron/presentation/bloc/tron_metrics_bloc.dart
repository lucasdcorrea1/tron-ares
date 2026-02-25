import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/tron_metrics_model.dart';
import '../../data/services/tron_api_service.dart';

// Events
abstract class TronMetricsEvent extends Equatable {
  const TronMetricsEvent();
  @override
  List<Object?> get props => [];
}

class LoadMetricsEvent extends TronMetricsEvent {
  final String projectId;
  final int days;
  const LoadMetricsEvent(this.projectId, {this.days = 30});
  @override
  List<Object?> get props => [projectId, days];
}

// State
class TronMetricsState extends Equatable {
  final TronMetrics? metrics;
  final int selectedDays;
  final bool isLoading;
  final String? error;

  const TronMetricsState({
    this.metrics,
    this.selectedDays = 30,
    this.isLoading = false,
    this.error,
  });

  TronMetricsState copyWith({
    TronMetrics? metrics,
    int? selectedDays,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TronMetricsState(
      metrics: metrics ?? this.metrics,
      selectedDays: selectedDays ?? this.selectedDays,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [metrics, selectedDays, isLoading, error];
}

// Bloc
class TronMetricsBloc extends Bloc<TronMetricsEvent, TronMetricsState> {
  final TronApiService _apiService;

  TronMetricsBloc({required TronApiService apiService})
      : _apiService = apiService,
        super(const TronMetricsState()) {
    on<LoadMetricsEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadMetricsEvent event, Emitter<TronMetricsState> emit) async {
    emit(state.copyWith(
        isLoading: true, clearError: true, selectedDays: event.days));
    try {
      final metrics =
          await _apiService.getMetrics(event.projectId, days: event.days);
      emit(state.copyWith(metrics: metrics, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
