import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../metrics/metrics_collector.dart';

/// Provider that monitors the app lifecycle state.
/// 
/// Exposes the current [AppLifecycleState] for use in request cancellation
/// and other lifecycle-aware logic.
final appLifecycleProvider = StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  (ref) => AppLifecycleNotifier(ref),
);

/// Notifier that tracks the app lifecycle state.
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> {
  final Ref _ref;
  
  AppLifecycleNotifier(this._ref) : super(AppLifecycleState.resumed) {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this, _ref));
    // Track initial foreground state
    _trackLifecycleEvent('app_foregrounded');
  }

  void _updateState(AppLifecycleState newState) {
    final oldState = state;
    state = newState;
    
    // Track lifecycle events for metrics
    _trackLifecycleEvent(_getLifecycleEventName(newState), {
      'from': _getLifecycleEventName(oldState),
    });
  }

  String _getLifecycleEventName(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return 'app_foregrounded';
      case AppLifecycleState.inactive:
        return 'app_inactive';
      case AppLifecycleState.paused:
        return 'app_backgrounded';
      case AppLifecycleState.hidden:
        return 'app_hidden';
      case AppLifecycleState.detached:
        return 'app_detached';
    }
  }

  void _trackLifecycleEvent(String event, [Map<String, dynamic>? metadata]) {
    try {
      final metricsCollector = _ref.read(metricsCollectorProvider);
      metricsCollector.trackLifecycleEvent(event, metadata: metadata);
    } catch (e) {
      // Fail silently - metrics shouldn't break the app
    }
  }
}

/// Observer that listens to app lifecycle changes.
class _LifecycleObserver extends WidgetsBindingObserver {
  final AppLifecycleNotifier _notifier;
  final Ref _ref;

  _LifecycleObserver(this._notifier, this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _notifier._updateState(state);
  }
}

/// Extension methods for [AppLifecycleState] to check state.
extension AppLifecycleStateExtension on AppLifecycleState {
  /// Returns true if the app is in the background or inactive.
  bool get isBackgrounded => this == AppLifecycleState.paused || this == AppLifecycleState.inactive;

  /// Returns true if the app is in the foreground and active.
  bool get isForegrounded => this == AppLifecycleState.resumed;

  /// Returns true if the app is hidden (paused or detached).
  bool get isHidden => this == AppLifecycleState.paused || this == AppLifecycleState.hidden;
}

