import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_core_network/flutter_core_network.dart';

class MockNetworkService extends Mock implements NetworkService {}

class TestApiService extends BaseApiService {
  TestApiService({super.networkService});

  Future<ApiResponse<String>> testRequest() async {
    return executeRequest<String>(() async {
      return await networkService.get<String>('/test');
    });
  }
}

void main() {
  group('BaseApiService', () {
    late TestApiService apiService;
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockNetworkService = MockNetworkService();
      apiService = TestApiService(networkService: mockNetworkService);
    });

    test('should return success response when request succeeds', () async {
      // Arrange
      when(() => mockNetworkService.get<String>('/test'))
          .thenAnswer((_) async => 'success');

      // Act
      final result = await apiService.testRequest();

      // Assert
      expect(result.success, isTrue);
      expect(result.data, equals('success'));
    });

    test('should return error response when request fails', () async {
      // Arrange
      when(() => mockNetworkService.get<String>('/test'))
          .thenThrow(const ValidationException(
        'Validation failed',
        errors: {
          'email': ['Required']
        },
      ));

      // Act
      final result = await apiService.testRequest();

      // Assert
      expect(result.success, isFalse);
      expect(result.hasValidationErrors, isTrue);
      expect(result.error?.fieldErrors?['email'], contains('Required'));
    });

    test('should return authentication error response', () async {
      // Arrange
      when(() => mockNetworkService.get<String>('/test'))
          .thenThrow(const UnauthorizedException('Token expired'));

      // Act
      final result = await apiService.testRequest();

      // Assert
      expect(result.success, isFalse);
      expect(result.hasAuthenticationError, isTrue);
      expect(result.error?.code, equals('AUTHENTICATION_ERROR'));
      expect(result.statusCode, equals(401));
    });
  });
}
