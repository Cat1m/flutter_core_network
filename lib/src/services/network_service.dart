// lib/src/services/network_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import '../models/network_config.dart';
import '../exceptions/network_exceptions.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/retry_interceptor.dart';
import '../utils/connectivity_helper.dart';

/// Enhanced NetworkService with flexible URL management
class NetworkService {
  static NetworkService? _instance;
  static NetworkConfig? _config;

  late final Dio _dio;
  String? _authToken;

  /// Map of service names to their base URLs
  final Map<String, String> _serviceUrls = {};

  /// Current environment (dev, staging, prod)
  String _currentEnvironment = 'prod';

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
  static void initialize(NetworkConfig config) {
    _config = config;
    _instance ??= NetworkService._internal();
    _instance!._setupDioClient();
  }

  // ==================== URL MANAGEMENT METHODS ====================

  /// Register a service with its base URL
  ///
  /// [serviceName] - Name of the service (e.g., 'auth', 'user', 'payment')
  /// [baseUrl] - Base URL for the service
  /// [environment] - Environment this URL applies to (optional)
  ///
  /// Example:
  /// ```dart
  /// networkService.registerService('auth', 'https://auth.example.com');
  /// networkService.registerService('user', 'https://user-api.example.com');
  /// ```
  void registerService(String serviceName, String baseUrl,
      {String? environment}) {
    final key =
        environment != null ? '${serviceName}_$environment' : serviceName;
    _serviceUrls[key] = baseUrl;
  }

  /// Register multiple services at once
  ///
  /// [services] - Map of service names to base URLs
  /// [environment] - Environment these URLs apply to (optional)
  void registerServices(Map<String, String> services, {String? environment}) {
    services.forEach((serviceName, baseUrl) {
      registerService(serviceName, baseUrl, environment: environment);
    });
  }

  /// Set current environment
  ///
  /// [environment] - Environment to use (dev, staging, prod)
  void setEnvironment(String environment) {
    _currentEnvironment = environment;
  }

  /// Get base URL for a service
  ///
  /// [serviceName] - Name of the service
  /// [environment] - Specific environment (optional, uses current if not provided)
  ///
  /// Returns base URL or null if not found
  String? getServiceUrl(String serviceName, {String? environment}) {
    final env = environment ?? _currentEnvironment;
    final key = '${serviceName}_$env';

    // Try environment-specific URL first
    if (_serviceUrls.containsKey(key)) {
      return _serviceUrls[key];
    }

    // Fall back to service without environment
    return _serviceUrls[serviceName];
  }

  /// Build full URL for a service endpoint
  ///
  /// [serviceName] - Name of the service
  /// [path] - Endpoint path
  /// [environment] - Specific environment (optional)
  ///
  /// Returns full URL
  String buildServiceUrl(String serviceName, String path,
      {String? environment}) {
    final baseUrl = getServiceUrl(serviceName, environment: environment);

    if (baseUrl == null) {
      throw NetworkException('Service "$serviceName" not registered');
    }

    // Handle path formatting
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return '$cleanBaseUrl/$cleanPath';
  }

  /// Remove a registered service
  ///
  /// [serviceName] - Name of the service to remove
  /// [environment] - Specific environment (optional)
  void unregisterService(String serviceName, {String? environment}) {
    final key =
        environment != null ? '${serviceName}_$environment' : serviceName;
    _serviceUrls.remove(key);
  }

  /// Get all registered services
  ///
  /// Returns map of service keys to URLs
  Map<String, String> getRegisteredServices() {
    return Map<String, String>.from(_serviceUrls);
  }

  /// Clear all registered services
  void clearServices() {
    _serviceUrls.clear();
  }

  /// Check if a service is registered
  ///
  /// [serviceName] - Name of the service
  /// [environment] - Specific environment (optional)
  bool isServiceRegistered(String serviceName, {String? environment}) {
    return getServiceUrl(serviceName, environment: environment) != null;
  }

  // ==================== ENHANCED HTTP METHODS ====================

  /// Performs GET request with service-specific URL support
  ///
  /// [path] - API endpoint path or service:path format
  /// [serviceName] - Name of the service (optional, can be in path)
  /// [queryParameters] - Optional query parameters
  /// [headers] - Optional headers for this request only
  /// [cancelToken] - Token for request cancellation
  /// [fromJson] - Optional JSON deserializer function
  ///
  /// Examples:
  /// ```dart
  /// // Using service parameter
  /// await networkService.get('/users', serviceName: 'user');
  ///
  /// // Using service:path format
  /// await networkService.get('user:/users');
  ///
  /// // Using full URL
  /// await networkService.get('https://api.example.com/users');
  /// ```
  Future<T> get<T>(
    String path, {
    String? serviceName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    final fullUrl = _buildRequestUrl(path, serviceName);

    try {
      final response = await _dio.get(
        fullUrl,
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

  /// Performs POST request with service-specific URL support
  Future<T> post<T>(
    String path, {
    String? serviceName,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    final fullUrl = _buildRequestUrl(path, serviceName);

    try {
      final response = await _dio.post(
        fullUrl,
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

  /// Performs PUT request with service-specific URL support
  Future<T> put<T>(
    String path, {
    String? serviceName,
    dynamic data,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    final fullUrl = _buildRequestUrl(path, serviceName);

    try {
      final response = await _dio.put(
        fullUrl,
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

  /// Performs DELETE request with service-specific URL support
  Future<T> delete<T>(
    String path, {
    String? serviceName,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    final fullUrl = _buildRequestUrl(path, serviceName);

    try {
      final response = await _dio.delete(
        fullUrl,
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

  /// Execute request with a specific service context
  ///
  /// [serviceName] - Service to use for this request
  /// [request] - Request function to execute
  ///
  /// Temporarily sets base URL to service URL
  Future<T> withService<T>(
    String serviceName,
    Future<T> Function() request,
  ) async {
    final serviceUrl = getServiceUrl(serviceName);
    if (serviceUrl == null) {
      throw NetworkException('Service "$serviceName" not registered');
    }

    final originalBaseUrl = _dio.options.baseUrl;

    try {
      _dio.options.baseUrl = serviceUrl;
      return await request();
    } finally {
      _dio.options.baseUrl = originalBaseUrl;
    }
  }

  /// Build request URL based on path and service
  String _buildRequestUrl(String path, String? serviceName) {
    // If path is already a full URL, return as-is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Check if path contains service notation (service:path)
    if (path.contains(':')) {
      final parts = path.split(':');
      if (parts.length == 2) {
        final service = parts[0];
        final endpoint = parts[1];
        return buildServiceUrl(service, endpoint);
      }
    }

    // If serviceName is provided, build service URL
    if (serviceName != null) {
      return buildServiceUrl(serviceName, path);
    }

    // Default behavior - use current base URL
    return path;
  }

  // ==================== EXISTING METHODS (updated) ====================

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

    _dio.interceptors.addAll([
      if (_config!.enableLogging) LoggingInterceptor(),
      AuthInterceptor(),
      RetryInterceptor(
        maxRetries: _config!.maxRetries,
        retryStatusCodes: _config!.retryStatusCodes,
      ),
    ]);
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

  /// Header management methods (từ version trước)
  void addHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  void removeHeaders(List<String> keys) {
    for (final key in keys) {
      _dio.options.headers.remove(key);
    }
  }

  void clearCustomHeaders() {
    if (_config != null) {
      _dio.options.headers.clear();
      _dio.options.headers.addAll(_config!.defaultHeaders);
    }
  }

  Map<String, dynamic> getCurrentHeaders() {
    return Map<String, dynamic>.from(_dio.options.headers);
  }

  bool hasHeader(String key) {
    return _dio.options.headers.containsKey(key);
  }

  String? getHeader(String key) {
    return _dio.options.headers[key]?.toString();
  }

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

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  void removeInterceptorsByType<T extends Interceptor>() {
    _dio.interceptors.removeWhere((interceptor) => interceptor is T);
  }

  void resetInterceptors() {
    _setupDioClient();
  }

  // Rest of existing methods remain the same...
  Future<void> _checkConnectivity() async {
    if (!await ConnectivityHelper.isConnected()) {
      throw const ConnectionException('No internet connection');
    }
  }

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

  @visibleForTesting
  Dio get dio => _dio;

  @visibleForTesting
  String? get authToken => _authToken;
}
