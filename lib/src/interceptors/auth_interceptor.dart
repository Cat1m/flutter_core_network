import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Authentication interceptor for automatic token management
/// Handles token injection and refresh logic.
class AuthInterceptor extends QueuedInterceptor {
  String? _accessToken;
  String? _refreshToken;

  /// Sets authentication tokens
  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clears authentication tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authorization header if token exists
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle token refresh on 401 errors
    if (err.response?.statusCode == 401 && _refreshToken != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          _accessToken = newToken;

          // Retry original request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';

          final dio = Dio();
          final response = await dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Refresh failed, clear tokens
        clearTokens();
      }
    }

    handler.next(err);
  }

  /// Refreshes access token using refresh token
  Future<String?> _refreshAccessToken() async {
    if (_refreshToken == null) return null;

    try {
      final dio = Dio();
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );

      return response.data['access_token'] as String?;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return null;
    }
  }
}
