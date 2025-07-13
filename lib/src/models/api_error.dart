import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

/// API error model for structured error responses
/// Provides consistent error information across all API endpoints.
@JsonSerializable()
class ApiError extends Equatable {
  /// Error code identifier
  final String code;

  /// Human-readable error message
  final String message;

  /// Additional error details
  final String? details;

  /// Field-specific validation errors
  final Map<String, List<String>>? fieldErrors;

  /// Error metadata for debugging
  final Map<String, dynamic>? metadata;

  /// Timestamp when error occurred
  final DateTime? timestamp;

  /// Creates an API error instance
  const ApiError({
    required this.code,
    required this.message,
    this.details,
    this.fieldErrors,
    this.metadata,
    this.timestamp,
  });

  /// Factory constructor for validation errors
  factory ApiError.validation({
    required String message,
    Map<String, List<String>>? fieldErrors,
    String? details,
  }) {
    return ApiError(
      code: 'VALIDATION_ERROR',
      message: message,
      details: details,
      fieldErrors: fieldErrors,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for authentication errors
  factory ApiError.authentication({
    required String message,
    String? details,
  }) {
    return ApiError(
      code: 'AUTHENTICATION_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for authorization errors
  factory ApiError.authorization({
    required String message,
    String? details,
  }) {
    return ApiError(
      code: 'AUTHORIZATION_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for server errors
  factory ApiError.server({
    required String message,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    return ApiError(
      code: 'SERVER_ERROR',
      message: message,
      details: details,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for network errors
  factory ApiError.network({
    required String message,
    String? details,
  }) {
    return ApiError(
      code: 'NETWORK_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for timeout errors
  factory ApiError.timeout({
    required String message,
    String? details,
  }) {
    return ApiError(
      code: 'TIMEOUT_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for unknown errors
  factory ApiError.unknown({
    required String message,
    String? details,
  }) {
    return ApiError(
      code: 'UNKNOWN_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }

  /// Creates ApiError from JSON
  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  /// Converts ApiError to JSON
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);

  /// Returns a user-friendly error message
  String get userFriendlyMessage {
    switch (code) {
      case 'VALIDATION_ERROR':
        return fieldErrors?.isNotEmpty == true
            ? 'Please check the highlighted fields and try again'
            : message;
      case 'AUTHENTICATION_ERROR':
        return 'Please log in to continue';
      case 'AUTHORIZATION_ERROR':
        return 'You don\'t have permission to perform this action';
      case 'NETWORK_ERROR':
        return 'Please check your internet connection and try again';
      case 'TIMEOUT_ERROR':
        return 'Request timed out. Please try again';
      case 'SERVER_ERROR':
        return 'Something went wrong on our end. Please try again later';
      default:
        return message;
    }
  }

  /// Returns formatted field errors as a single string
  String? get formattedFieldErrors {
    if (fieldErrors == null || fieldErrors!.isEmpty) return null;

    final errorMessages = <String>[];
    fieldErrors!.forEach((field, errors) {
      for (final error in errors) {
        errorMessages.add('$field: $error');
      }
    });

    return errorMessages.join('\n');
  }

  /// Checks if this is a validation error
  bool get isValidationError => code == 'VALIDATION_ERROR';

  /// Checks if this is an authentication error
  bool get isAuthenticationError => code == 'AUTHENTICATION_ERROR';

  /// Checks if this is an authorization error
  bool get isAuthorizationError => code == 'AUTHORIZATION_ERROR';

  /// Checks if this is a network error
  bool get isNetworkError => code == 'NETWORK_ERROR';

  /// Checks if this is a server error
  bool get isServerError => code == 'SERVER_ERROR';

  @override
  List<Object?> get props => [
        code,
        message,
        details,
        fieldErrors,
        metadata,
        timestamp,
      ];

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}
