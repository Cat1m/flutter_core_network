/// Flutter Core Network Service
///
/// A comprehensive network service package for Flutter applications.
/// 
/// This package provides:
/// - HTTP client with Dio
/// - Request/Response interceptors
/// - Error handling and custom exceptions
/// - File upload/download capabilities
/// - Retry mechanism with exponential backoff
/// - Network connectivity detection
/// - Request/Response logging
/// - Automatic token management
///
/// ## Usage
/// 
/// ```dart
/// import 'package:flutter_core_network/flutter_core_network.dart';
/// 
/// // Initialize the service
/// NetworkService.initialize(
///   baseUrl: 'https://api.example.com',
///   connectTimeout: Duration(seconds: 30),
///   enableLogging: true,
/// );
/// 
/// // Use the service
/// final networkService = NetworkService.instance;
/// final response = await networkService.get('/users');
/// ```
library flutter_core_network;

// Core services
export 'src/services/network_service.dart';
export 'src/services/base_api_service.dart';

// Models
export 'src/models/api_response.dart';
export 'src/models/api_error.dart';
export 'src/models/network_config.dart';
export 'src/models/paginated_response.dart';

// Exceptions
export 'src/exceptions/network_exceptions.dart';

// Interceptors
export 'src/interceptors/logging_interceptor.dart';
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/retry_interceptor.dart';

// Utils
export 'src/utils/network_utils.dart';
export 'src/utils/connectivity_helper.dart';
