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

    test('should create NetworkConfig with default values', () {
      const config = NetworkConfig(
        baseUrl: 'https://api.example.com',
      );

      expect(config.baseUrl, equals('https://api.example.com'));
      expect(config.enableLogging, isTrue);
      expect(config.maxRetries, equals(3));
      expect(config.connectTimeout, equals(const Duration(seconds: 30)));
    });
  });
}
