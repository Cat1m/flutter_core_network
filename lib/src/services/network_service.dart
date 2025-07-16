// lib/src/services/network_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import '../models/network_config.dart';
import '../exceptions/network_exceptions.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/retry_interceptor.dart';
import '../utils/connectivity_helper.dart';

/// Main network service class providing HTTP operations with comprehensive error handling
/// and interceptor support. Implements singleton pattern for application-wide usage.
class NetworkService {
  static NetworkService? _instance;
  static NetworkConfig? _config;

  late final Dio _dio;
  String? _authToken;

  /// Private constructor for singleton pattern
  NetworkService._internal() {
    _dio = Dio();
    if (_config != null) {
      _setupDioClient();
    }
  }

  /// Factory constructor returns singleton instance
  factory NetworkService() {
    _instance ??= NetworkService._internal();
    return _instance!;
  }

  /// Static getter for singleton instance
  static NetworkService get instance {
    _instance ??= NetworkService._internal();
    return _instance!;
  }

  /// Static method to initialize the network service with configuration
  /// Must be called before using any network operations
  static void initialize(NetworkConfig config) {
    _config = config;
    // Create new instance if one doesn't exist
    _instance ??= NetworkService._internal();
    // Setup the dio client with new config
    _instance!._setupDioClient();
  }

  /// Sets up Dio client with configuration and interceptors
  void _setupDioClient() {
    if (_config == null) {
      throw const NetworkException(
          'NetworkService must be initialized with configuration');
    }

    _dio.options = BaseOptions(
      baseUrl: _config!.baseUrl,
      connectTimeout: _config!.connectTimeout,
      receiveTimeout: _config!.receiveTimeout,
      sendTimeout: _config!.connectTimeout,
      headers: Map<String, String>.from(_config!.defaultHeaders),
      validateStatus: (status) => status != null && status < 500,
      followRedirects: true,
      maxRedirects: 3,
      responseType: ResponseType.json,
    );

    _dio.interceptors.clear();

    // Add interceptors in order of priority
    _dio.interceptors.addAll([
      if (_config!.enableLogging) LoggingInterceptor(),
      AuthInterceptor(),
      RetryInterceptor(
        maxRetries: _config!.maxRetries,
        retryStatusCodes: _config!.retryStatusCodes,
      ),
    ]);
  }

  // ==================== HEADER MANAGEMENT METHODS ====================

  /// Adds custom headers to all subsequent requests
  ///
  /// [headers] - Map of headers to add
  ///
  /// Example:
  /// ```dart
  /// networkService.addHeaders({
  ///   'X-Custom-Header': 'value',
  ///   'X-API-Version': '1.0',
  /// });
  /// ```
  void addHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  /// Sets a single header for all subsequent requests
  ///
  /// [key] - Header key
  /// [value] - Header value
  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// Removes a specific header from all subsequent requests
  ///
  /// [key] - Header key to remove
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// Removes multiple headers from all subsequent requests
  ///
  /// [keys] - List of header keys to remove
  void removeHeaders(List<String> keys) {
    for (final key in keys) {
      _dio.options.headers.remove(key);
    }
  }

  /// Clears all custom headers (keeps only default headers from config)
  void clearCustomHeaders() {
    if (_config != null) {
      _dio.options.headers.clear();
      _dio.options.headers.addAll(_config!.defaultHeaders);
    }
  }

  /// Gets current headers
  ///
  /// Returns a copy of current headers map
  Map<String, dynamic> getCurrentHeaders() {
    return Map<String, dynamic>.from(_dio.options.headers);
  }

  /// Checks if a header exists
  ///
  /// [key] - Header key to check
  /// Returns true if header exists
  bool hasHeader(String key) {
    return _dio.options.headers.containsKey(key);
  }

  /// Gets value of a specific header
  ///
  /// [key] - Header key
  /// Returns header value or null if not found
  String? getHeader(String key) {
    return _dio.options.headers[key]?.toString();
  }

  /// Temporarily sets headers for a single request execution
  ///
  /// [headers] - Temporary headers to apply
  /// [request] - Function to execute with temporary headers
  ///
  /// Headers are automatically restored after request completion
  Future<T> withHeaders<T>(
    Map<String, String> headers,
    Future<T> Function() request,
  ) async {
    final originalHeaders = Map<String, dynamic>.from(_dio.options.headers);

    try {
      _dio.options.headers.addAll(headers);
      return await request();
    } finally {
      _dio.options.headers = originalHeaders;
    }
  }

  /// Adds an interceptor to the Dio instance
  ///
  /// [interceptor] - Interceptor to add
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Removes an interceptor from the Dio instance
  ///
  /// [interceptor] - Interceptor to remove
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// Removes all interceptors of a specific type
  ///
  /// [T] - Type of interceptor to remove
  void removeInterceptorsByType<T extends Interceptor>() {
    _dio.interceptors.removeWhere((interceptor) => interceptor is T);
  }

  /// Clears all interceptors and resets to default ones
  void resetInterceptors() {
    _setupDioClient();
  }

  // ==================== HTTP METHODS WITH HEADER SUPPORT ====================

  /// Performs GET request with generic type support and optional headers
  ///
  /// [path] - API endpoint path
  /// [queryParameters] - Optional query parameters
  /// [headers] - Optional headers for this request only
  /// [cancelToken] - Token for request cancellation
  /// [fromJson] - Optional JSON deserializer function
  ///
  /// Returns deserialized object of type T
  /// Throws [NetworkException] on network errors
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: headers != null ? Options(headers: headers) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Performs POST request with generic type support and optional headers
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - Optional query parameters
  /// [headers] - Optional headers for this request only
  /// [cancelToken] - Token for request cancellation
  /// [fromJson] - Optional JSON deserializer function
  ///
  /// Returns deserialized object of type T
  /// Throws [NetworkException] on network errors
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: headers != null ? Options(headers: headers) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Performs PUT request with generic type support and optional headers
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.put(
        path,
        data: data,
        cancelToken: cancelToken,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Performs DELETE request with generic type support and optional headers
  Future<T> delete<T>(
    String path, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.delete(
        path,
        cancelToken: cancelToken,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  // ==================== EXISTING METHODS (unchanged) ====================

  /// Uploads file with progress tracking
  Future<String> uploadFile(
    String path,
    File file, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
  }) async {
    await _checkConnectivity();

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        ...?fields,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: headers != null ? Options(headers: headers) : null,
      );

      return response.data?['message'] ?? 'Upload successful';
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('File upload failed: $e');
    }
  }

  /// Downloads file with progress tracking
  Future<void> downloadFile(
    String url,
    String savePath, {
    Map<String, String>? headers,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkConnectivity();

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: headers != null ? Options(headers: headers) : null,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('File download failed: $e');
    }
  }

  /// Updates the base URL for all requests
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Sets authentication token for requests
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clears authentication token
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  /// Checks network connectivity before making requests
  Future<void> _checkConnectivity() async {
    if (!await ConnectivityHelper.isConnected()) {
      throw const ConnectionException('No internet connection');
    }
  }

  /// Handles response parsing and deserialization
  T _handleResponse<T>(Response response, T Function(dynamic)? fromJson) {
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw ServerException(
        'Server error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    if (fromJson != null) {
      return fromJson(response.data);
    }

    return response.data as T;
  }

  /// Converts DioException to appropriate NetworkException
  NetworkException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Request timed out');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return ClientException('Bad request', statusCode: statusCode);
          case 401:
            return const UnauthorizedException('Unauthorized access');
          case 404:
            return ClientException('Not found', statusCode: statusCode);
          case 422:
            return ValidationException(
              'Validation failed',
              errors: e.response?.data,
            );
          case 500:
          case 502:
          case 503:
            return ServerException(
              'Server error',
              statusCode: statusCode,
            );
          default:
            return NetworkException(
              'HTTP error: $statusCode',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return const CancelException('Request was cancelled');

      case DioExceptionType.connectionError:
        return const ConnectionException('Connection failed');

      default:
        return NetworkException('Network error: ${e.message}');
    }
  }

  /// Provides access to underlying Dio instance for advanced usage
  @visibleForTesting
  Dio get dio => _dio;

  /// Gets current authentication token
  @visibleForTesting
  String? get authToken => _authToken;
}
