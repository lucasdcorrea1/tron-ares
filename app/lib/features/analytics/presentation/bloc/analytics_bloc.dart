import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/analytics_remote_datasource.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRemoteDataSource dataSource;

  AnalyticsBloc({required this.dataSource}) : super(AnalyticsInitial()) {
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
    on<RefreshAnalyticsEvent>(_onRefreshAnalytics);
    on<ChangePeriodEvent>(_onChangePeriod);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final stats = await dataSource.getProfileStats();
      emit(AnalyticsLoaded(stats: stats));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onRefreshAnalytics(
    RefreshAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      final stats = await dataSource.getProfileStats();
      final currentState = state;
      if (currentState is AnalyticsLoaded) {
        emit(currentState.copyWith(stats: stats));
      } else {
        emit(AnalyticsLoaded(stats: stats));
      }
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnalyticsLoaded) {
      emit(currentState.copyWith(selectedPeriod: event.period));
    }
  }
}
