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

  /// Performs GET request with generic type support
  ///
  /// [path] - API endpoint path
  /// [queryParameters] - Optional query parameters
  /// [cancelToken] - Token for request cancellation
  /// [fromJson] - Optional JSON deserializer function
  ///
  /// Returns deserialized object of type T
  /// Throws [NetworkException] on network errors
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Performs POST request with generic type support
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - Optional query parameters
  /// [cancelToken] - Token for request cancellation
  /// [fromJson] - Optional JSON deserializer function
  ///
  /// Returns deserialized object of type T
  /// Throws [NetworkException] on network errors
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
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
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Performs PUT request with generic type support
  Future<T> put<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response =
          await _dio.put(path, data: data, cancelToken: cancelToken);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Performs DELETE request with generic type support
  Future<T> delete<T>(
    String path, {
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.delete(path, cancelToken: cancelToken);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Uploads file with progress tracking
  ///
  /// [path] - Upload endpoint path
  /// [file] - File to upload
  /// [fields] - Additional form fields
  /// [onSendProgress] - Progress callback
  ///
  /// Returns upload response message
  Future<String> uploadFile(
    String path,
    File file, {
    Map<String, String>? fields,
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
      );

      return response.data?['message'] ?? 'Upload successful';
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw NetworkException('File upload failed: $e');
    }
  }

  /// Downloads file with progress tracking
  ///
  /// [url] - Download URL
  /// [savePath] - Local file save path
  /// [onReceiveProgress] - Progress callback
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkConnectivity();

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
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
