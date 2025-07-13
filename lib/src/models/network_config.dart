import 'package:equatable/equatable.dart';

/// Configuration model for network service initialization
/// Contains all necessary settings for HTTP client setup.
class NetworkConfig extends Equatable {
  /// Base URL for API requests
  final String baseUrl;

  /// Connection timeout duration
  final Duration connectTimeout;

  /// Response receive timeout duration
  final Duration receiveTimeout;

  /// Default headers for all requests
  final Map<String, String> defaultHeaders;

  /// Enable request/response logging
  final bool enableLogging;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Status codes that should trigger retry
  final List<int> retryStatusCodes;

  /// Creates network configuration
  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    this.enableLogging = true,
    this.maxRetries = 3,
    this.retryStatusCodes = const [500, 502, 503, 504],
  });

  /// Creates a copy with updated values
  NetworkConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, String>? defaultHeaders,
    bool? enableLogging,
    int? maxRetries,
    List<int>? retryStatusCodes,
  }) {
    return NetworkConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      enableLogging: enableLogging ?? this.enableLogging,
      maxRetries: maxRetries ?? this.maxRetries,
      retryStatusCodes: retryStatusCodes ?? this.retryStatusCodes,
    );
  }

  @override
  List<Object?> get props => [
        baseUrl,
        connectTimeout,
        receiveTimeout,
        defaultHeaders,
        enableLogging,
        maxRetries,
        retryStatusCodes,
      ];
}
