import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'api_error.dart';

part 'api_response.g.dart';

/// Generic API response wrapper providing consistent response structure
/// across all API endpoints with type safety and error handling.
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> extends Equatable {
  /// Indicates if the request was successful
  final bool success;

  /// Response data of type T
  final T? data;

  /// Response message
  final String? message;

  /// HTTP status code
  final int? statusCode;

  /// Error details (when success is false)
  final ApiError? error;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates an API response instance
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.error,
    this.metadata,
  });

  /// Factory constructor for successful responses
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
      metadata: metadata,
    );
  }

  /// Factory constructor for error responses
  factory ApiResponse.error({
    required String message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  /// Factory constructor for error responses with ApiError
  factory ApiResponse.errorWithDetails({
    required ApiError error,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: error.message,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  /// Factory constructor for validation error responses
  factory ApiResponse.validationError({
    required String message,
    Map<String, List<String>>? fieldErrors,
    String? details,
  }) {
    return ApiResponse<T>(
      success: false,
      error: ApiError.validation(
        message: message,
        fieldErrors: fieldErrors,
        details: details,
      ),
      message: message,
      statusCode: 422,
    );
  }

  /// Factory constructor for authentication error responses
  factory ApiResponse.authenticationError({
    String? message,
    String? details,
  }) {
    final error = ApiError.authentication(
      message: message ?? 'Authentication required',
      details: details,
    );
    return ApiResponse<T>(
      success: false,
      error: error,
      message: error.message,
      statusCode: 401,
    );
  }

  /// Creates ApiResponse from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  /// Converts ApiResponse to JSON
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  @override
  List<Object?> get props =>
      [success, data, message, statusCode, error, metadata];

  /// Returns true if this is an error response
  bool get isError => !success;

  /// Returns true if this response has validation errors
  bool get hasValidationErrors => error?.isValidationError == true;

  /// Returns true if this response has authentication errors
  bool get hasAuthenticationError => error?.isAuthenticationError == true;

  /// Returns true if this response has network errors
  bool get hasNetworkError => error?.isNetworkError == true;

  /// Returns user-friendly error message
  String? get userFriendlyErrorMessage => error?.userFriendlyMessage ?? message;

  /// Returns formatted field errors
  String? get formattedFieldErrors => error?.formattedFieldErrors;
}
