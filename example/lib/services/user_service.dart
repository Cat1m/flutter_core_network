// lib/services/user_service.dart
import 'package:flutter_core_network/flutter_core_network.dart';
import '../models/user.dart';

class UserService extends BaseApiService {
  /// Initialize UserService with default headers
  UserService() {
    _setupDefaultHeaders();
  }

  /// Setup default headers for all user service requests
  void _setupDefaultHeaders() {
    networkService.addHeaders({
      'X-Service': 'user-service',
      'X-Version': '1.0.0',
      'X-Platform': 'flutter',
      'Content-Type': 'application/json',
    });
  }

  /// Set user context headers (call after login)
  void setUserContext(String userId, String role) {
    networkService.addHeaders({
      'X-User-ID': userId,
      'X-User-Role': role,
      'X-Session-ID': _generateSessionId(),
      'X-Session-Start': DateTime.now().toIso8601String(),
    });
  }

  /// Clear user context headers (call on logout)
  void clearUserContext() {
    networkService.removeHeaders([
      'X-User-ID',
      'X-User-Role',
      'X-Session-ID',
      'X-Session-Start',
    ]);
  }

  /// Update user role (when role changes)
  void updateUserRole(String newRole) {
    networkService.setHeader('X-User-Role', newRole);
  }

  /// Gets all users with pagination headers
  Future<ApiResponse<List<User>>> getUsers({
    int page = 2,
    int limit = 10,
    String? filterType,
    String? sortBy,
  }) async {
    return executeRequest<List<User>>(() async {
      // Use per-request headers for pagination
      final response = await networkService.get<List<dynamic>>(
        '/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (filterType != null) 'filter': filterType,
          if (sortBy != null) 'sort': sortBy,
        },
        headers: {
          'X-Request-Type': 'list-users',
          'X-Page': page.toString(),
          'X-Limit': limit.toString(),
          'X-Request-Time': DateTime.now().toIso8601String(),
        },
      );

      return response
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Gets a specific user by ID with audit headers
  Future<ApiResponse<User>> getUser(int id) async {
    return executeRequest<User>(() async {
      final response = await networkService.get<Map<String, dynamic>>(
        '/users/$id',
        headers: {
          'X-Request-Type': 'get-user',
          'X-Target-User-ID': id.toString(),
          'X-Audit-Action': 'view-user-profile',
        },
      );

      return User.fromJson(response);
    });
  }

  /// Creates a new user with audit trail
  Future<ApiResponse<User>> createUser(User user) async {
    return executeRequest<User>(() async {
      final response = await networkService.post<Map<String, dynamic>>(
        '/users',
        data: user.toJson(),
        headers: {
          'X-Request-Type': 'create-user',
          'X-Audit-Action': 'create-user',
          'X-Created-At': DateTime.now().toIso8601String(),
        },
      );

      return User.fromJson(response);
    });
  }

  /// Updates user with version control headers
  Future<ApiResponse<User>> updateUser(User user) async {
    return executeRequest<User>(() async {
      final response = await networkService.put<Map<String, dynamic>>(
        '/users/${user.id}',
        data: user.toJson(),
        headers: {
          'X-Request-Type': 'update-user',
          'X-Audit-Action': 'update-user',
          'X-Updated-At': DateTime.now().toIso8601String(),
          'X-Version': user.id.toString(),
        },
      );

      return User.fromJson(response);
    });
  }

  /// Deletes a user with confirmation headers
  Future<ApiResponse<bool>> deleteUser(int id, {bool confirmed = false}) async {
    return executeRequest<bool>(() async {
      await networkService.delete(
        '/users/$id',
        headers: {
          'X-Request-Type': 'delete-user',
          'X-Audit-Action': 'delete-user',
          'X-Confirmed': confirmed.toString(),
          'X-Deleted-At': DateTime.now().toIso8601String(),
        },
      );
      return true;
    });
  }

  /// Bulk operations with special headers
  Future<ApiResponse<List<User>>> bulkCreateUsers(List<User> users) async {
    return executeRequest<List<User>>(() async {
      final response = await networkService.post<List<dynamic>>(
        '/users/bulk',
        data: users.map((user) => user.toJson()).toList(),
        headers: {
          'X-Request-Type': 'bulk-create',
          'X-Bulk-Operation': 'true',
          'X-Batch-Size': users.length.toString(),
          'X-Batch-ID': _generateBatchId(),
        },
      );

      return response
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Export users with custom format headers
  Future<ApiResponse<String>> exportUsers({
    String format = 'csv',
    List<String>? fields,
  }) async {
    return executeRequest<String>(() async {
      final response = await networkService.get<String>(
        '/users/export',
        queryParameters: {
          'format': format,
          if (fields != null) 'fields': fields.join(','),
        },
        headers: {
          'X-Request-Type': 'export-users',
          'X-Export-Format': format,
          'X-Export-Fields': fields?.join(',') ?? 'all',
          'Accept': _getAcceptHeader(format),
        },
      );

      return response;
    });
  }

  /// Search users with advanced headers
  Future<ApiResponse<List<User>>> searchUsers(
    String query, {
    List<String>? searchFields,
    int page = 1,
    int limit = 10,
  }) async {
    return executeRequest<List<User>>(() async {
      final response = await networkService.get<List<dynamic>>(
        '/users/search',
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
          if (searchFields != null) 'fields': searchFields.join(','),
        },
        headers: {
          'X-Request-Type': 'search-users',
          'X-Search-Query': query,
          'X-Search-Fields': searchFields?.join(',') ?? 'all',
          'X-Search-ID': _generateSearchId(),
        },
      );

      return response
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Execute request with temporary headers
  Future<ApiResponse<T>> executeWithTempHeaders<T>(
    Map<String, String> tempHeaders,
    Future<T> Function() request,
  ) async {
    return executeRequest<T>(() async {
      return await networkService.withHeaders(tempHeaders, request);
    });
  }

  /// Admin operation with elevated privileges
  Future<ApiResponse<List<User>>> getAdminUsers() async {
    return executeWithTempHeaders<List<User>>(
      {
        'X-Admin-Access': 'true',
        'X-Privilege-Level': 'admin',
        'X-Operation': 'admin-user-list',
      },
      () async {
        final response = await networkService.get<List<dynamic>>(
          '/admin/users',
        );
        return response
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Check current service headers
  Map<String, dynamic> getCurrentHeaders() {
    return networkService.getCurrentHeaders();
  }

  /// Helper method to generate session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Helper method to generate batch ID
  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Helper method to generate search ID
  String _generateSearchId() {
    return 'search_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Helper method to get accept header based on format
  String _getAcceptHeader(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      default:
        return 'application/json';
    }
  }
}
