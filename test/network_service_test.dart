// test/network_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core_network/flutter_core_network.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'models/user.dart';

void main() {
  group('NetworkService with JSONPlaceholder', () {
    late NetworkService networkService;
    late DioAdapter dioAdapter;

    setUp(() {
      // Initialize with JSONPlaceholder API
      NetworkService.initialize(const NetworkConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        enableLogging: false,
      ));

      networkService = NetworkService.instance;

      // Create adapter for mocking HTTP requests
      dioAdapter = DioAdapter(dio: networkService.dio);
    });

    tearDown(() {
      dioAdapter.close();
    });

    group('Initialization', () {
      test('should initialize with JSONPlaceholder URL', () {
        // Act
        NetworkService.initialize(const NetworkConfig(
          baseUrl: 'https://jsonplaceholder.typicode.com',
          enableLogging: true,
        ));

        // Assert
        expect(NetworkService.instance, isNotNull);
        expect(NetworkService.instance.dio.options.baseUrl,
            equals('https://jsonplaceholder.typicode.com'));
      });
    });

    group('User API Tests', () {
      test('should get users list successfully', () async {
        // Arrange
        const path = '/users';
        final mockUsers = [
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
          },
          {
            "id": 2,
            "name": "Ervin Howell",
            "username": "Antonette",
            "email": "Shanna@melissa.tv",
            "address": {
              "street": "Victor Plains",
              "suite": "Suite 879",
              "city": "Wisokyburgh",
              "zipcode": "90566-7771",
              "geo": {"lat": "-43.9509", "lng": "-34.4618"}
            },
            "phone": "010-692-6593 x09125",
            "website": "anastasia.net",
            "company": {
              "name": "Deckow-Crist",
              "catchPhrase": "Proactive didactic contingency",
              "bs": "synergize scalable supply-chains"
            }
          }
        ];

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, mockUsers),
        );

        // Act
        final result = await networkService.get<List<dynamic>>(path);

        // Assert
        expect(result, isA<List<dynamic>>());
        expect(result.length, equals(2));

        // Test converting to User objects
        final users = result
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        expect(users.first.name, equals('Leanne Graham'));
        expect(users.first.email, equals('Sincere@april.biz'));
      });

      test('should get single user successfully', () async {
        // Arrange
        const path = '/users/1';
        final mockUser = {
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

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, mockUser),
        );

        // Act
        final result = await networkService.get<Map<String, dynamic>>(path);

        // Assert
        expect(result, isA<Map<String, dynamic>>());

        // Test converting to User object
        final user = User.fromJson(result);
        expect(user.id, equals(1));
        expect(user.name, equals('Leanne Graham'));
        expect(user.username, equals('Bret'));
        expect(user.email, equals('Sincere@april.biz'));
        expect(user.address.city, equals('Gwenborough'));
        expect(user.company.name, equals('Romaguera-Crona'));
      });

      test('should create user successfully', () async {
        // Arrange
        const path = '/users';
        const newUser = User(
          id: 0, // Will be assigned by server
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
          company: const Company(
            name: 'John Corp',
            catchPhrase: 'Innovation at its best',
            bs: 'revolutionary solutions',
          ),
        );

        final responseUser = {
          "id": 11, // JSONPlaceholder returns id 11 for new users
          ...newUser.toJson()
        };

        dioAdapter.onPost(
          path,
          (server) => server.reply(201, responseUser),
          data: newUser.toJson(),
        );

        // Act
        final result = await networkService.post<Map<String, dynamic>>(
          path,
          data: newUser.toJson(),
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());

        final createdUser = User.fromJson(result);
        expect(createdUser.id, equals(11));
        expect(createdUser.name, equals('John Doe'));
        expect(createdUser.email, equals('john@example.com'));
      });

      test('should handle 404 error when user not found', () async {
        // Arrange
        const path = '/users/999';

        dioAdapter.onGet(
          path,
          (server) => server.reply(404, {'error': 'User not found'}),
        );

        // Act & Assert
        expect(
          () => networkService.get(path),
          throwsA(isA<ClientException>()),
        );
      });

      test('should handle server error', () async {
        // Arrange
        const path = '/users';

        dioAdapter.onGet(
          path,
          (server) => server.reply(500, {'error': 'Internal server error'}),
        );

        // Act & Assert
        expect(
          () => networkService.get(path),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('Posts API Tests', () {
      test('should get posts successfully', () async {
        // Arrange
        const path = '/posts';
        final mockPosts = [
          {
            "userId": 1,
            "id": 1,
            "title":
                "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
            "body":
                "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
          },
          {
            "userId": 1,
            "id": 2,
            "title": "qui est esse",
            "body":
                "est rerum tempore vitae\nsequi sint nihil reprehenderit dolor beatae ea dolores neque\nfugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis\nqui aperiam non debitis possimus qui neque nisi nulla"
          }
        ];

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, mockPosts),
        );

        // Act
        final result = await networkService.get<List<dynamic>>(path);

        // Assert
        expect(result, isA<List<dynamic>>());
        expect(result.length, equals(2));
        expect(result.first['userId'], equals(1));
        expect(result.first['title'], isNotEmpty);
      });
    });

    group('Authentication', () {
      test('should set auth token', () {
        // Act
        networkService.setAuthToken('test-token');

        // Assert
        expect(networkService.authToken, equals('test-token'));
        expect(networkService.dio.options.headers['Authorization'],
            equals('Bearer test-token'));
      });

      test('should clear auth token', () {
        // Arrange
        networkService.setAuthToken('test-token');

        // Act
        networkService.clearAuthToken();

        // Assert
        expect(networkService.authToken, isNull);
        expect(networkService.dio.options.headers['Authorization'], isNull);
      });
    });

    group('Configuration Updates', () {
      test('should update base URL', () {
        // Arrange
        const newBaseUrl = 'https://api.github.com';

        // Act
        networkService.updateBaseUrl(newBaseUrl);

        // Assert
        expect(networkService.dio.options.baseUrl, equals(newBaseUrl));
      });
    });
  });
}
