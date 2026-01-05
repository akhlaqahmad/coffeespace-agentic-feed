import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages request cancellation for Riverpod providers
class RequestManager {
  final CancelToken _cancelToken = CancelToken();

  /// Cancel all pending requests
  void cancel() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel('Request cancelled');
    }
  }

  /// Get the cancel token for use with Dio requests
  CancelToken get cancelToken => _cancelToken;

  /// Check if requests are cancelled
  bool get isCancelled => _cancelToken.isCancelled;

  /// Dispose resources
  void dispose() {
    cancel();
  }
}

/// Extension to integrate RequestManager with Riverpod's ref.onDispose
extension RequestManagerExtension on Ref {
  /// Creates a RequestManager that automatically cancels on dispose
  RequestManager createRequestManager() {
    final manager = RequestManager();
    onDispose(() {
      manager.dispose();
    });
    return manager;
  }
}

