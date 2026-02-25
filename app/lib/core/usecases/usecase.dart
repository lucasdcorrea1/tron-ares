import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Base class for all use cases in the application
/// Follows Clean Architecture principles where use cases are the entry points
/// to the domain layer
///
/// [Type] is the return type of the use case
/// [Params] is the parameters required by the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use when a use case doesn't require any parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
