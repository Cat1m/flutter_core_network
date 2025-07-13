import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:flutter_core_network/flutter_core_network.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('NetworkService', () {
    late NetworkService networkService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      NetworkService.initialize(const NetworkConfig(
        baseUrl: 'https://api.example.com',
        enableLogging: false,
      ));
      networkService = NetworkService();
    });

    group('GET requests', () {
      test('should return data when request is successful', () async {
        // Arrange
        final mockResponse = Response(
          data: {'id': 1, 'name': 'Test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(() => mockDio.get(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await networkService.get<Map<String, dynamic>>('/test');

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['name'], equals('Test'));
      });

      test('should throw NetworkException when request fails', () async {
        // Arrange
        when(() => mockDio.get(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // Act & Assert
        expect(
          () => networkService.get('/test'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('POST requests', () {
      test('should send data and return response', () async {
        // Arrange
        final requestData = {'name': 'New Item'};
        final mockResponse = Response(
          data: {'id': 2, 'name': 'New Item'},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await networkService.post<Map<String, dynamic>>(
          '/test',
          data: requestData,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals(2));
      });
    });

    group('Authentication', () {
      test('should set auth token', () {
        // Act
        networkService.setAuthToken('test-token');

        // Assert
        expect(networkService.authToken, equals('test-token'));
      });

      test('should clear auth token', () {
        // Arrange
        networkService.setAuthToken('test-token');

        // Act
        networkService.clearAuthToken();

        // Assert
        expect(networkService.authToken, isNull);
      });
    });
  });
}
