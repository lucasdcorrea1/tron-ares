import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Following Clean Architecture, failures are used in the domain layer
/// to represent errors without depending on exceptions
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Failure related to database operations
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database operation failed',
    super.code,
  });
}

/// Failure related to cache operations
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache operation failed',
    super.code,
  });
}

/// Failure for invalid input data
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred',
    super.code,
  });
}

/// Failure when a resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.code,
  });
}

/// Failure related to server/API operations
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message: message);
}

/// Failure related to network/connection issues
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error']) : super(message: message);
}

/// Failure for authentication errors
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message: message);
}
