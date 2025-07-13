// lib/src/exceptions/network_exceptions.dart
/// Base class for all network-related exceptions
/// Provides consistent error handling across the application.
class NetworkException implements Exception {
  /// Error message
  final String message;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Additional error details
  final Map<String, dynamic>? details;

  /// Creates network exception
  const NetworkException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when connection fails or times out
class ConnectionException extends NetworkException {
  const ConnectionException(super.message, {super.statusCode, super.details});

  @override
  String toString() => 'ConnectionException: $message';
}

/// Exception thrown for server errors (5xx status codes)
class ServerException extends NetworkException {
  const ServerException(super.message, {super.statusCode, super.details});

  @override
  String toString() => 'ServerException: $message';
}

/// Exception thrown for client errors (4xx status codes)
class ClientException extends NetworkException {
  const ClientException(super.message, {super.statusCode, super.details});

  @override
  String toString() => 'ClientException: $message';
}

/// Exception thrown for unauthorized access (401)
class UnauthorizedException extends NetworkException {
  const UnauthorizedException(super.message, {super.statusCode, super.details});

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown for validation errors (422)
class ValidationException extends NetworkException {
  /// Validation errors map
  final Map<String, List<String>>? errors;

  const ValidationException(
    super.message, {
    super.statusCode,
    super.details,
    this.errors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown for request timeouts
class TimeoutException extends NetworkException {
  const TimeoutException(super.message, {super.statusCode, super.details});

  @override
  String toString() => 'TimeoutException: $message';
}

/// Exception thrown when request is cancelled
class CancelException extends NetworkException {
  const CancelException(super.message, {super.statusCode, super.details});

  @override
  String toString() => 'CancelException: $message';
}
