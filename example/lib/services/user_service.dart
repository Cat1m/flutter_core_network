// example/lib/services/user_service.dart
import 'package:flutter_core_network/flutter_core_network.dart';
import '../models/user.dart';

class UserService extends BaseApiService {
  /// Gets all users from the API
  Future<ApiResponse<List<User>>> getUsers() async {
    return executeRequest<List<User>>(() async {
      final response = await networkService.get<List<dynamic>>('/users');
      return response
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Gets a specific user by ID
  Future<ApiResponse<User>> getUser(int id) async {
    return executeRequest<User>(() async {
      final response = await networkService.get<Map<String, dynamic>>(
        '/users/$id',
      );
      return User.fromJson(response);
    });
  }

  /// Creates a new user
  Future<ApiResponse<User>> createUser(User user) async {
    return executeRequest<User>(() async {
      final response = await networkService.post<Map<String, dynamic>>(
        '/users',
        data: user.toJson(),
      );
      return User.fromJson(response);
    });
  }

  /// Updates an existing user
  Future<ApiResponse<User>> updateUser(User user) async {
    return executeRequest<User>(() async {
      final response = await networkService.put<Map<String, dynamic>>(
        '/users/${user.id}',
        data: user.toJson(),
      );
      return User.fromJson(response);
    });
  }

  /// Deletes a user
  Future<ApiResponse<bool>> deleteUser(int id) async {
    return executeRequest<bool>(() async {
      await networkService.delete('/users/$id');
      return true;
    });
  }
}
