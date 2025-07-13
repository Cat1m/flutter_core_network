// lib/src/services/base_api_service.dart
import 'package:meta/meta.dart';
import '../models/api_error.dart';
import 'network_service.dart';
import '../models/api_response.dart';
import '../exceptions/network_exceptions.dart';

/// Abstract base class for API services providing common functionality
/// and standardized error handling patterns.
abstract class BaseApiService {
  /// Network service instance for making HTTP requests
  @protected
  final NetworkService networkService;

  /// Creates base API service with network service dependency
  BaseApiService({NetworkService? networkService})
      : networkService = networkService ?? NetworkService();

  /// Executes network request with standardized error handling
  ///
  /// [request] - Function that performs the network request
  /// [onError] - Optional custom error handler
  ///
  /// Returns [ApiResponse] wrapping the result
  @protected
  Future<ApiResponse<T>> executeRequest<T>(
    Future<T> Function() request, {
    String Function(NetworkException)? onError,
  }) async {
    try {
      final result = await request();
      return ApiResponse.success(
        data: result,
        message: 'Request successful',
      );
    } on NetworkException catch (e) {
      if (onError != null) {
        final errorMessage = onError(e);
        return ApiResponse.error(
          message: errorMessage,
          statusCode: e.statusCode,
        );
      }
      return createErrorResponse<T>(e);
    } catch (e) {
      return ApiResponse.errorWithDetails(
        error: ApiError.unknown(
          message: 'An unexpected error occurred',
          details: e.toString(),
        ),
      );
    }
  }

  /// Provides default error messages for common network exceptions
  String _getDefaultErrorMessage(NetworkException exception) {
    switch (exception.runtimeType) {
      case const (ConnectionException):
        return 'Please check your internet connection and try again';
      case const (TimeoutException):
        return 'Request timed out. Please try again';
      case const (UnauthorizedException):
        return 'You need to log in to access this feature';
      case const (ServerException):
        return 'Server error. Please try again later';
      case const (ValidationException):
        return 'Invalid data provided';
      default:
        return 'Network error occurred. Please try again';
    }
  }

  /// Creates appropriate ApiResponse based on exception type
  @protected
  ApiResponse<T> createErrorResponse<T>(NetworkException exception) {
    switch (exception.runtimeType) {
      case const (ValidationException):
        final validationEx = exception as ValidationException;
        return ApiResponse.validationError(
          message: validationEx.message,
          fieldErrors: validationEx.errors,
        );
      case const (UnauthorizedException):
        return ApiResponse.authenticationError(
          message: exception.message,
        );
      case const (ConnectionException):
        return ApiResponse.errorWithDetails(
          error: ApiError.network(message: exception.message),
          statusCode: exception.statusCode,
        );
      case const (TimeoutException):
        return ApiResponse.errorWithDetails(
          error: ApiError.timeout(message: exception.message),
          statusCode: exception.statusCode,
        );
      case const (ServerException):
        return ApiResponse.errorWithDetails(
          error: ApiError.server(message: exception.message),
          statusCode: exception.statusCode,
        );
      default:
        return ApiResponse.errorWithDetails(
          error: ApiError.unknown(message: exception.message),
          statusCode: exception.statusCode,
        );
    }
  }

  /// Handles pagination for list requests
  @protected
  Future<ApiResponse<List<T>>> handlePaginatedRequest<T>(
    Future<List<T>> Function() request,
    int page,
    int limit,
  ) async {
    try {
      final result = await request();
      return ApiResponse.success(
        data: result,
        metadata: {
          'page': page,
          'limit': limit,
          'total': result.length,
        },
      );
    } on NetworkException catch (e) {
      return ApiResponse.error(
        message: _getDefaultErrorMessage(e),
        statusCode: e.statusCode,
      );
    }
  }

  /// Retry logic for failed requests with exponential backoff
  @protected
  Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;

        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }

    throw const NetworkException('Max retries exceeded');
  }
}
