import 'dart:math' as math;
import 'package:dio/dio.dart';

/// Retry interceptor implementing exponential backoff strategy
/// for failed requests with configurable retry conditions.
class RetryInterceptor extends QueuedInterceptor {
  /// Maximum number of retry attempts
  final int maxRetries;

  /// Base delay between retries
  final Duration baseDelay;

  /// Status codes that should trigger retry
  final List<int> retryStatusCodes;

  /// Creates retry interceptor with configuration
  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const [500, 502, 503, 504],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < maxRetries) {
        // Calculate delay with exponential backoff
        final delay = Duration(
          milliseconds:
              (baseDelay.inMilliseconds * math.pow(2, retryCount)).round(),
        );

        await Future.delayed(delay);

        // Update retry count
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // Continue to next retry or fail
        }
      }
    }

    handler.next(err);
  }

  /// Determines if request should be retried
  bool _shouldRetry(DioException err) {
    // Retry on connection/timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific status codes
    final statusCode = err.response?.statusCode;
    return statusCode != null && retryStatusCodes.contains(statusCode);
  }
}
