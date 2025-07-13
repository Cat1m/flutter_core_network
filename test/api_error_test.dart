// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_core_network/flutter_core_network.dart';

// void main() {
//   group('ApiError', () {
//     test('should create validation error with field errors', () {
//       // Arrange
//       final fieldErrors = {
//         'email': ['Email is required', 'Email format is invalid'],
//         'password': ['Password must be at least 8 characters'],
//       };

//       // Act
//       final error = ApiError.validation(
//         message: 'Validation failed',
//         fieldErrors: fieldErrors,
//         details: 'Form validation errors',
//       );

//       // Assert
//       expect(error.code, equals('VALIDATION_ERROR'));
//       expect(error.message, equals('Validation failed'));
//       expect(error.isValidationError, isTrue);
//       expect(error.fieldErrors, equals(fieldErrors));
//       expect(error.formattedFieldErrors, isNotNull);
//       expect(error.formattedFieldErrors, contains('email: Email is required'));
//     });

//     test('should create authentication error', () {
//       // Act
//       final error = ApiError.authentication(
//         message: 'Invalid credentials',
//         details: 'Username or password is incorrect',
//       );

//       // Assert
//       expect(error.code, equals('AUTHENTICATION_ERROR'));
//       expect(error.message, equals('Invalid credentials'));
//       expect(error.isAuthenticationError, isTrue);
//       expect(error.userFriendlyMessage, equals('Please log in to continue'));
//     });

//     test('should create server error with metadata', () {
//       // Arrange
//       final metadata = {
//         'request_id': '12345',
//         'timestamp': '2023-01-01T00:00:00Z',
//       };

//       // Act
//       final error = ApiError.server(
//         message: 'Internal server error',
//         details: 'Database connection failed',
//         metadata: metadata,
//       );

//       // Assert
//       expect(error.code, equals('SERVER_ERROR'));
//       expect(error.message, equals('Internal server error'));
//       expect(error.isServerError, isTrue);
//       expect(error.metadata, equals(metadata));
//       expect(error.userFriendlyMessage,
//           equals('Something went wrong on our end. Please try again later'));
//     });

//     test('should serialize to and from JSON', () {
//       // Arrange
//       final originalError = ApiError.validation(
//         message: 'Validation failed',
//         fieldErrors: {
//           'email': ['Required']
//         },
//       );

//       // Act
//       final json = originalError.toJson();
//       final deserializedError = ApiError.fromJson(json);

//       // Assert
//       expect(deserializedError.code, equals(originalError.code));
//       expect(deserializedError.message, equals(originalError.message));
//       expect(deserializedError.fieldErrors, equals(originalError.fieldErrors));
//     });
//   });

//   group('ApiResponse with ApiError', () {
//     test('should create validation error response', () {
//       // Arrange
//       final fieldErrors = {
//         'email': ['Required']
//       };

//       // Act
//       final response = ApiResponse<User>.validationError(
//         message: 'Validation failed',
//         fieldErrors: fieldErrors,
//       );

//       // Assert
//       expect(response.success, isFalse);
//       expect(response.hasValidationErrors, isTrue);
//       expect(response.error?.fieldErrors, equals(fieldErrors));
//       expect(response.statusCode, equals(422));
//     });

//     test('should create authentication error response', () {
//       // Act
//       final response = ApiResponse<User>.authenticationError(
//         message: 'Token expired',
//       );

//       // Assert
//       expect(response.success, isFalse);
//       expect(response.hasAuthenticationError, isTrue);
//       expect(response.error?.code, equals('AUTHENTICATION_ERROR'));
//       expect(response.statusCode, equals(401));
//     });
//   });
// }
