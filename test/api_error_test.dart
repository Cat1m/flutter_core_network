// test/base_api_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_core_network/flutter_core_network.dart';
import 'models/user.dart';

class MockNetworkService extends Mock implements NetworkService {}

class TestUserService extends BaseApiService {
  TestUserService({super.networkService});

  Future<ApiResponse<List<User>>> getUsers() async {
    return executeRequest<List<User>>(() async {
      final response = await networkService.get<List<dynamic>>('/users');
      return response
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<ApiResponse<User>> getUser(int id) async {
    return executeRequest<User>(() async {
      final response =
          await networkService.get<Map<String, dynamic>>('/users/$id');
      return User.fromJson(response);
    });
  }

  Future<ApiResponse<User>> createUser(User user) async {
    return executeRequest<User>(() async {
      final response = await networkService.post<Map<String, dynamic>>(
        '/users',
        data: user.toJson(),
      );
      return User.fromJson(response);
    });
  }
}

void main() {
  group('BaseApiService with JSONPlaceholder', () {
    late TestUserService userService;
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockNetworkService = MockNetworkService();
      userService = TestUserService(networkService: mockNetworkService);
    });

    group('User Operations', () {
      test('should return users list when API call succeeds', () async {
        // Arrange
        final mockUsersData = [
          {
            "id": 1,
            "name": "Leanne Graham",
            "username": "Bret",
            "email": "Sincere@april.biz",
            "address": {
              "street": "Kulas Light",
              "suite": "Apt. 556",
              "city": "Gwenborough",
              "zipcode": "92998-3874",
              "geo": {"lat": "-37.3159", "lng": "81.1496"}
            },
            "phone": "1-770-736-8031 x56442",
            "website": "hildegard.org",
            "company": {
              "name": "Romaguera-Crona",
              "catchPhrase": "Multi-layered client-server neural-net",
              "bs": "harness real-time e-markets"
            }
          }
        ];

        when(() => mockNetworkService.get<List<dynamic>>('/users'))
            .thenAnswer((_) async => mockUsersData);

        // Act
        final result = await userService.getUsers();

        // Assert
        expect(result.success, isTrue);
        expect(result.data?.length, equals(1));
        expect(result.data?.first.name, equals('Leanne Graham'));
        expect(result.data?.first.email, equals('Sincere@april.biz'));
      });

      test('should return single user when API call succeeds', () async {
        // Arrange
        final mockUserData = {
          "id": 1,
          "name": "Leanne Graham",
          "username": "Bret",
          "email": "Sincere@april.biz",
          "address": {
            "street": "Kulas Light",
            "suite": "Apt. 556",
            "city": "Gwenborough",
            "zipcode": "92998-3874",
            "geo": {"lat": "-37.3159", "lng": "81.1496"}
          },
          "phone": "1-770-736-8031 x56442",
          "website": "hildegard.org",
          "company": {
            "name": "Romaguera-Crona",
            "catchPhrase": "Multi-layered client-server neural-net",
            "bs": "harness real-time e-markets"
          }
        };

        when(() => mockNetworkService.get<Map<String, dynamic>>('/users/1'))
            .thenAnswer((_) async => mockUserData);

        // Act
        final result = await userService.getUser(1);

        // Assert
        expect(result.success, isTrue);
        expect(result.data?.id, equals(1));
        expect(result.data?.name, equals('Leanne Graham'));
      });

      test('should create user when API call succeeds', () async {
        // Arrange
        const newUser = User(
          id: 0,
          name: 'John Doe',
          username: 'johndoe',
          email: 'john@example.com',
          phone: '123-456-7890',
          website: 'johndoe.com',
          address: Address(
            street: '123 Main St',
            suite: 'Apt 1',
            city: 'Anytown',
            zipcode: '12345',
            geo: Geo(lat: '40.7128', lng: '-74.0060'),
          ),
          company: Company(
            name: 'John Corp',
            catchPhrase: 'Innovation at its best',
            bs: 'revolutionary solutions',
          ),
        );

        final createdUserData = {"id": 11, ...newUser.toJson()};

        when(() => mockNetworkService.post<Map<String, dynamic>>(
              '/users',
              data: newUser.toJson(),
            )).thenAnswer((_) async => createdUserData);

        // Act
        final result = await userService.createUser(newUser);

        // Assert
        expect(result.success, isTrue);
        expect(result.data?.id, equals(11));
        expect(result.data?.name, equals('John Doe'));
      });
    });

    group('Error Handling', () {
      test('should return validation error response when validation fails',
          () async {
        // Arrange
        when(() => mockNetworkService.get<List<dynamic>>('/users'))
            .thenThrow(const ValidationException(
          'Validation failed',
          errors: {
            'email': ['Required']
          },
        ));

        // Act
        final result = await userService.getUsers();

        // Assert
        expect(result.success, isFalse);
        expect(result.hasValidationErrors, isTrue);
        expect(result.error?.fieldErrors?['email'], contains('Required'));
      });

      test('should return authentication error response', () async {
        // Arrange
        when(() => mockNetworkService.get<Map<String, dynamic>>('/users/1'))
            .thenThrow(const UnauthorizedException('Token expired'));

        // Act
        final result = await userService.getUser(1);

        // Assert
        expect(result.success, isFalse);
        expect(result.hasAuthenticationError, isTrue);
        expect(result.error?.code, equals('AUTHENTICATION_ERROR'));
        expect(result.statusCode, equals(401));
      });

      test('should return server error response', () async {
        // Arrange
        when(() => mockNetworkService.get<List<dynamic>>('/users')).thenThrow(
            const ServerException('Internal server error', statusCode: 500));

        // Act
        final result = await userService.getUsers();

        // Assert
        expect(result.success, isFalse);
        expect(result.error?.isServerError, isTrue);
        expect(result.statusCode, equals(500));
      });
    });
  });
}
