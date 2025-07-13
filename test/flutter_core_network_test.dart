// test/flutter_core_network_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core_network/flutter_core_network.dart';

void main() {
  group('Flutter Core Network Package', () {
    test('should export all required classes', () {
      // Test that main classes are accessible
      expect(NetworkService, isNotNull);
      expect(NetworkConfig, isNotNull);
      expect(ApiResponse, isNotNull);
      expect(ApiError, isNotNull);
      expect(BaseApiService, isNotNull);
    });

    test('should create NetworkConfig with JSONPlaceholder URL', () {
      const config = NetworkConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
      );

      expect(config.baseUrl, equals('https://jsonplaceholder.typicode.com'));
      expect(config.enableLogging, isTrue);
      expect(config.maxRetries, equals(3));
      expect(config.connectTimeout, equals(const Duration(seconds: 30)));
    });

    test('should initialize NetworkService with JSONPlaceholder', () {
      // Act
      NetworkService.initialize(const NetworkConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        enableLogging: true,
        maxRetries: 2,
      ));

      // Assert
      final instance = NetworkService.instance;
      expect(instance, isNotNull);
      expect(instance.dio.options.baseUrl,
          equals('https://jsonplaceholder.typicode.com'));
    });

    test('should support multiple environments', () {
      const environments = {
        'development': 'https://dev-api.example.com',
        'staging': 'https://staging-api.example.com',
        'production': 'https://jsonplaceholder.typicode.com',
      };

      for (final entry in environments.entries) {
        NetworkService.initialize(NetworkConfig(
          baseUrl: entry.value,
          enableLogging: entry.key == 'development',
        ));

        expect(
            NetworkService.instance.dio.options.baseUrl, equals(entry.value));
      }
    });
  });
}
