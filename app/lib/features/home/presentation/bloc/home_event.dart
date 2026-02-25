import 'package:equatable/equatable.dart';

/// Base class for all home events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load home data
class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent();
}

/// Event to refresh home data
class RefreshHomeDataEvent extends HomeEvent {
  const RefreshHomeDataEvent();
}
