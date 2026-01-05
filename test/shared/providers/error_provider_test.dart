import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coffeespace_agentic_feed/shared/providers/error_provider.dart';
import 'package:coffeespace_agentic_feed/shared/widgets/error_banner.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    // Wait a bit to allow any pending timers to complete
    // This prevents "Tried to use ErrorNotifier after dispose" errors
    container.dispose();
  });

  group('ErrorNotifier', () {
    group('addError', () {
      test('adds error to state', () {
        // Arrange
        final error = AppError(
          message: 'Test error',
          errorType: ErrorType.network,
        );

        // Act
        container.read(errorProvider.notifier).addError(error);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 1);
        expect(state.errors[0].message, 'Test error');
        expect(state.errors[0].errorType, ErrorType.network);
      });

      test('adds multiple errors', () {
        // Arrange
        final error1 = AppError(
          message: 'Error 1',
          errorType: ErrorType.network,
        );
        final error2 = AppError(
          message: 'Error 2',
          errorType: ErrorType.server,
        );

        // Act
        container.read(errorProvider.notifier).addError(error1);
        container.read(errorProvider.notifier).addError(error2);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 2);
        expect(state.errors[0].message, 'Error 1');
        expect(state.errors[1].message, 'Error 2');
      });

      test('auto-removes error after 5 seconds', () async {
        // Arrange - use a separate container that won't be disposed
        final testContainer = ProviderContainer();
        final error = AppError(
          message: 'Test error',
          errorType: ErrorType.network,
        );

        // Act
        testContainer.read(errorProvider.notifier).addError(error);
        
        // Assert - error should be present initially
        var state = testContainer.read(errorProvider);
        expect(state.errors.length, 1);
        
        // Wait for auto-remove (5 seconds)
        await Future.delayed(const Duration(seconds: 5, milliseconds: 100));
        
        // Assert - error should be removed
        state = testContainer.read(errorProvider);
        expect(state.errors.length, 0);
        
        // Cleanup
        testContainer.dispose();
      });
    });

    group('removeError', () {
      test('removes error by ID', () {
        // Arrange
        final error = AppError(
          message: 'Test error',
          errorType: ErrorType.network,
        );
        container.read(errorProvider.notifier).addError(error);
        
        final stateBefore = container.read(errorProvider);
        expect(stateBefore.errors.length, 1);
        final errorId = stateBefore.errors[0].id!;

        // Act
        container.read(errorProvider.notifier).removeError(errorId);

        // Assert
        final stateAfter = container.read(errorProvider);
        expect(stateAfter.errors.length, 0);
      });

      test('does not remove non-existent error', () {
        // Arrange
        final error = AppError(
          message: 'Test error',
          errorType: ErrorType.network,
        );
        container.read(errorProvider.notifier).addError(error);

        // Act
        container.read(errorProvider.notifier).removeError('non_existent_id');

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 1); // Still present
      });
    });

    group('clear', () {
      test('clears all errors', () {
        // Arrange
        final error1 = AppError(
          message: 'Error 1',
          errorType: ErrorType.network,
        );
        final error2 = AppError(
          message: 'Error 2',
          errorType: ErrorType.server,
        );
        container.read(errorProvider.notifier).addError(error1);
        container.read(errorProvider.notifier).addError(error2);

        // Act
        container.read(errorProvider.notifier).clear();

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 0);
      });
    });

    group('addDioError', () {
      test('converts DioException to AppError', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        // Act
        container.read(errorProvider.notifier).addDioError(dioException);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 1);
        expect(state.errors[0].errorType, ErrorType.network);
        expect(state.errors[0].message, contains('timeout'));
      });

      test('handles different DioException types', () {
        // Arrange
        final connectionError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );
        final badResponse = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
        );

        // Act
        container.read(errorProvider.notifier).addDioError(connectionError);
        container.read(errorProvider.notifier).addDioError(badResponse);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 2);
        expect(state.errors[0].errorType, ErrorType.network);
        expect(state.errors[1].errorType, ErrorType.server);
      });
    });

    group('addException', () {
      test('converts generic exception to AppError', () {
        // Arrange
        final exception = Exception('Generic error');

        // Act
        container.read(errorProvider.notifier).addException(exception);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 1);
        expect(state.errors[0].errorType, ErrorType.server);
        expect(state.errors[0].message, contains('Generic error'));
      });

      test('handles DioException via addException', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        // Act
        container.read(errorProvider.notifier).addException(dioException);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 1);
        expect(state.errors[0].errorType, ErrorType.network);
      });
    });

    group('addOptimisticFailure', () {
      test('adds optimistic failure error', () {
        // Arrange
        const message = 'Failed to like post';

        // Act
        container.read(errorProvider.notifier).addOptimisticFailure(message);

        // Assert
        final state = container.read(errorProvider);
        expect(state.errors.length, 1);
        expect(state.errors[0].message, message);
        expect(state.errors[0].errorType, ErrorType.optimisticFailure);
      });
    });

    group('AppError', () {
      test('creates error with timestamp and ID', () {
        // Arrange & Act
        final error = AppError(
          message: 'Test error',
          errorType: ErrorType.network,
        );

        // Assert
        expect(error.message, 'Test error');
        expect(error.errorType, ErrorType.network);
        expect(error.timestamp, isNotNull);
        expect(error.id, isNotNull);
      });

      test('fromDioException handles connection timeout', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        // Act
        final error = AppError.fromDioException(dioException);

        // Assert
        expect(error.errorType, ErrorType.network);
        expect(error.message, contains('timeout'));
      });

      test('fromDioException handles bad response', () {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
        );

        // Act
        final error = AppError.fromDioException(dioException);

        // Assert
        expect(error.errorType, ErrorType.server);
        expect(error.message, contains('Server error'));
      });

      test('optimisticFailure factory creates correct error', () {
        // Arrange & Act
        final error = AppError.optimisticFailure('Failed to like post');

        // Assert
        expect(error.message, 'Failed to like post');
        expect(error.errorType, ErrorType.optimisticFailure);
      });
    });
  });
}

