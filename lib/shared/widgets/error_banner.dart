import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Types of errors that can be displayed in the error banner
enum ErrorType {
  network,
  server,
  optimisticFailure,
}

/// Error banner widget for displaying transient errors
/// 
/// Features:
/// - Auto-dismisses after 5 seconds
/// - Dismissible by user swipe
/// - Different styles for different error types
/// - Smooth animations
class ErrorBanner extends StatefulWidget {
  final String message;
  final ErrorType errorType;
  final VoidCallback? onDismiss;
  final Duration autoDismissDuration;

  const ErrorBanner({
    super.key,
    required this.message,
    required this.errorType,
    this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 5),
  });

  /// Factory constructor for network errors
  factory ErrorBanner.network({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: message,
      errorType: ErrorType.network,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for server errors
  factory ErrorBanner.server({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: message,
      errorType: ErrorType.server,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for optimistic action failures
  factory ErrorBanner.optimisticFailure({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: message,
      errorType: ErrorType.optimisticFailure,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor that infers error type from DioException
  factory ErrorBanner.fromDioException({
    required DioException error,
    VoidCallback? onDismiss,
  }) {
    final errorType = _inferErrorType(error);
    String message;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.connectionError:
        message = 'Unable to connect. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        message = 'Server error. Please try again later.';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      default:
        message = error.message ?? 'An error occurred. Please try again.';
    }

    return ErrorBanner(
      message: message,
      errorType: errorType,
      onDismiss: onDismiss,
    );
  }

  static ErrorType _inferErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ErrorType.network;
      case DioExceptionType.badResponse:
        return ErrorType.server;
      default:
        return ErrorType.network;
    }
  }

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner>
    with SingleTickerProviderStateMixin {
  Timer? _autoDismissTimer;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto-dismiss after duration
    _autoDismissTimer = Timer(widget.autoDismissDuration, () {
      _dismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;

    _autoDismissTimer?.cancel();
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  Color _getBackgroundColor() {
    switch (widget.errorType) {
      case ErrorType.network:
        return Colors.orange.shade700;
      case ErrorType.server:
        return Colors.red.shade700;
      case ErrorType.optimisticFailure:
        return Colors.orange.shade600;
    }
  }

  IconData _getIcon() {
    switch (widget.errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.optimisticFailure:
        return Icons.sync_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dismissible(
          key: Key('error_banner_${widget.message}'),
          direction: DismissDirection.up,
          onDismissed: (_) => _dismiss(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _dismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

