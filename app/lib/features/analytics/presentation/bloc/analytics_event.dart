import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalyticsEvent extends AnalyticsEvent {
  const LoadAnalyticsEvent();
}

class RefreshAnalyticsEvent extends AnalyticsEvent {
  const RefreshAnalyticsEvent();
}

class ChangePeriodEvent extends AnalyticsEvent {
  final String period;

  const ChangePeriodEvent(this.period);

  @override
  List<Object?> get props => [period];
}
