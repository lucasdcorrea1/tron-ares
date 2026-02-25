/// Base class for all exceptions in the application
/// Exceptions are used in the data layer and converted to Failures
/// before reaching the domain layer
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception for database-related errors
class DatabaseException extends AppException {
  const DatabaseException({
    super.message = 'Database operation failed',
    super.code,
  });
}

/// Exception for cache-related errors
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache operation failed',
    super.code,
  });
}

/// Exception for validation errors
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
  });
}

/// Exception for not found resources
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.code,
  });
}
