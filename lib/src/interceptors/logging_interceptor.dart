import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logging interceptor for request/response monitoring
/// Provides detailed logging with sensitive data filtering.
class LoggingInterceptor extends Interceptor {
  final Logger _logger;
  final bool _logRequestBody;
  final bool _logResponseBody;
  final List<String> _sensitiveHeaders;

  /// Creates logging interceptor with configuration
  LoggingInterceptor({
    Logger? logger,
    bool logRequestBody = true,
    bool logResponseBody = true,
    List<String> sensitiveHeaders = const [
      'authorization',
      'cookie',
      'x-api-key',
    ],
  })  : _logger = logger ?? Logger(),
        _logRequestBody = logRequestBody,
        _logResponseBody = logResponseBody,
        _sensitiveHeaders =
            sensitiveHeaders.map((h) => h.toLowerCase()).toList();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i('📤 REQUEST: ${options.method} ${options.uri}');

      // Log headers (filter sensitive ones)
      if (options.headers.isNotEmpty) {
        final filteredHeaders = Map<String, dynamic>.from(options.headers);
        for (final header in _sensitiveHeaders) {
          if (filteredHeaders.containsKey(header)) {
            filteredHeaders[header] = '***';
          }
        }
        _logger.d('Headers: $filteredHeaders');
      }

      // Log query parameters
      if (options.queryParameters.isNotEmpty) {
        _logger.d('Query Parameters: ${options.queryParameters}');
      }

      // Log request body
      if (_logRequestBody && options.data != null) {
        _logger.d('Request Body: ${options.data}');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
          '📥 RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');

      // Log response headers
      if (response.headers.map.isNotEmpty) {
        _logger.d('Response Headers: ${response.headers.map}');
      }

      // Log response body
      if (_logResponseBody && response.data != null) {
        _logger.d('Response Body: ${response.data}');
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e('❌ ERROR: ${err.message}');

      if (err.response != null) {
        _logger.e('Status Code: ${err.response!.statusCode}');
        _logger.e('Response Data: ${err.response!.data}');
      }

      _logger.e('Request Options: ${err.requestOptions.uri}');
    }

    handler.next(err);
  }
}
