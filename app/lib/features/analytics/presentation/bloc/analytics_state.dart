import 'package:equatable/equatable.dart';

import '../../domain/entities/stats_entity.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final ProfileStats stats;
  final String selectedPeriod;

  const AnalyticsLoaded({
    required this.stats,
    this.selectedPeriod = 'month',
  });

  @override
  List<Object?> get props => [stats, selectedPeriod];

  AnalyticsLoaded copyWith({
    ProfileStats? stats,
    String? selectedPeriod,
  }) {
    return AnalyticsLoaded(
      stats: stats ?? this.stats,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
