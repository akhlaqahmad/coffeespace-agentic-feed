import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that monitors the app lifecycle state.
/// 
/// Exposes the current [AppLifecycleState] for use in request cancellation
/// and other lifecycle-aware logic.
final appLifecycleProvider = StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  (ref) => AppLifecycleNotifier(),
);

/// Notifier that tracks the app lifecycle state.
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> {
  AppLifecycleNotifier() : super(AppLifecycleState.resumed) {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }

  void _updateState(AppLifecycleState newState) {
    state = newState;
  }
}

/// Observer that listens to app lifecycle changes.
class _LifecycleObserver extends WidgetsBindingObserver {
  final AppLifecycleNotifier _notifier;

  _LifecycleObserver(this._notifier);

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

