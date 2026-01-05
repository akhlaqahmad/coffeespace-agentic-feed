import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/error_banner.dart';

/// Represents an error that should be displayed to the user
class AppError {
  final String message;
  final ErrorType errorType;
  final DateTime timestamp;
  final String? id;

  AppError({
    required this.message,
    required this.errorType,
    DateTime? timestamp,
    String? id,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Creates an AppError from a DioException
  factory AppError.fromDioException(DioException error) {
    ErrorType errorType;
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorType = ErrorType.network;
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.connectionError:
        errorType = ErrorType.network;
        message = 'Unable to connect. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorType = ErrorType.server;
        message = 'Server error. Please try again later.';
        break;
      case DioExceptionType.cancel:
        errorType = ErrorType.network;
        message = 'Request cancelled.';
        break;
      default:
        errorType = ErrorType.network;
        message = error.message ?? 'An error occurred. Please try again.';
    }

    return AppError(
      message: message,
      errorType: errorType,
    );
  }

  /// Creates an AppError from a generic exception
  factory AppError.fromException(Object error) {
    if (error is DioException) {
      return AppError.fromDioException(error);
    }

    return AppError(
      message: error.toString(),
      errorType: ErrorType.server,
    );
  }

  /// Creates an AppError for optimistic action failures
  factory AppError.optimisticFailure(String message) {
    return AppError(
      message: message,
      errorType: ErrorType.optimisticFailure,
    );
  }
}

/// State class for error notifications
class ErrorState {
  final List<AppError> errors;

  const ErrorState({this.errors = const []});

  ErrorState copyWith({
    List<AppError>? errors,
  }) {
    return ErrorState(
      errors: errors ?? this.errors,
    );
  }

  ErrorState addError(AppError error) {
    return ErrorState(
      errors: [...errors, error],
    );
  }

  ErrorState removeError(String errorId) {
    return ErrorState(
      errors: errors.where((e) => e.id != errorId).toList(),
    );
  }

  ErrorState clear() {
    return const ErrorState();
  }
}

/// Notifier for managing error state
class ErrorNotifier extends StateNotifier<ErrorState> {
  final Map<String, Timer> _autoRemoveTimers = {};

  ErrorNotifier() : super(const ErrorState());

  /// Adds an error to be displayed
  void addError(AppError error) {
    state = state.addError(error);

    // Auto-remove after 5 seconds
    final timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (state.errors.any((e) => e.id == error.id)) {
        removeError(error.id!);
      }
      _autoRemoveTimers.remove(error.id);
    });
    _autoRemoveTimers[error.id!] = timer;
  }

  /// Removes an error by ID
  void removeError(String errorId) {
    _autoRemoveTimers[errorId]?.cancel();
    _autoRemoveTimers.remove(errorId);
    if (mounted) {
      state = state.removeError(errorId);
    }
  }

  /// Clears all errors
  void clear() {
    _autoRemoveTimers.values.forEach((timer) => timer.cancel());
    _autoRemoveTimers.clear();
    if (mounted) {
      state = state.clear();
    }
  }

  /// Adds an error from a DioException
  void addDioError(DioException error) {
    addError(AppError.fromDioException(error));
  }

  /// Adds an error from a generic exception
  void addException(Object error) {
    addError(AppError.fromException(error));
  }

  /// Adds an optimistic failure error
  void addOptimisticFailure(String message) {
    addError(AppError.optimisticFailure(message));
  }
}

/// Provider for error state management
final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
});

