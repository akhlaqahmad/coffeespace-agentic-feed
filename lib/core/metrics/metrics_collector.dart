import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metrics data structures
class CacheMetrics {
  int hits = 0;
  int misses = 0;

  double get hitRate => hits + misses > 0 ? hits / (hits + misses) : 0.0;

  CacheMetrics copyWith({int? hits, int? misses}) {
    return CacheMetrics()
      ..hits = hits ?? this.hits
      ..misses = misses ?? this.misses;
  }
}

class APIMetrics {
  final Map<String, List<APICall>> calls = {};

  int get totalCalls => calls.values.fold(0, (sum, list) => sum + list.length);
  
  int get successCount => calls.values.fold(
    0,
    (sum, list) => sum + list.where((call) => call.success).length,
  );

  int get failureCount => calls.values.fold(
    0,
    (sum, list) => sum + list.where((call) => !call.success).length,
  );

  double get successRate => totalCalls > 0 ? successCount / totalCalls : 0.0;

  double getAverageLatency(String endpoint) {
    final endpointCalls = calls[endpoint] ?? [];
    if (endpointCalls.isEmpty) return 0.0;
    
    final totalLatency = endpointCalls
        .map((call) => call.latencyMs)
        .reduce((a, b) => a + b);
    return totalLatency / endpointCalls.length;
  }

  double getOverallAverageLatency() {
    if (totalCalls == 0) return 0.0;
    
    final totalLatency = calls.values.fold(
      0.0,
      (sum, list) => sum + list.fold(0.0, (s, call) => s + call.latencyMs),
    );
    return totalLatency / totalCalls;
  }
}

class APICall {
  final String endpoint;
  final bool success;
  final double latencyMs;
  final DateTime timestamp;

  APICall({
    required this.endpoint,
    required this.success,
    required this.latencyMs,
    required this.timestamp,
  });
}

class OptimisticMetrics {
  final Map<String, List<OptimisticAction>> actions = {};

  int get totalActions => actions.values.fold(0, (sum, list) => sum + list.length);
  
  int get successCount => actions.values.fold(
    0,
    (sum, list) => sum + list.where((action) => action.success).length,
  );

  int get failureCount => actions.values.fold(
    0,
    (sum, list) => sum + list.where((action) => !action.success).length,
  );

  double get successRate => totalActions > 0 ? successCount / totalActions : 0.0;
}

class OptimisticAction {
  final String action;
  final bool success;
  final DateTime timestamp;

  OptimisticAction({
    required this.action,
    required this.success,
    required this.timestamp,
  });
}

/// User interaction metrics
class UserInteractionMetrics {
  final Map<String, List<UserInteraction>> interactions = {};

  int get totalInteractions => interactions.values.fold(0, (sum, list) => sum + list.length);

  int getInteractionCount(String type) {
    return interactions[type]?.length ?? 0;
  }
}

class UserInteraction {
  final String type;
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;

  UserInteraction({
    required this.type,
    this.parameters,
    required this.timestamp,
  });
}

/// App lifecycle metrics
class LifecycleMetrics {
  final List<LifecycleEvent> events = [];
  DateTime? _sessionStart;
  DateTime? _lastForegroundTime;

  int get totalEvents => events.length;

  int get sessionCount => events.where((e) => e.event == 'app_foregrounded').length;

  Duration? get currentSessionDuration {
    if (_sessionStart == null) return null;
    return DateTime.now().difference(_sessionStart!);
  }

  void startSession() {
    _sessionStart = DateTime.now();
  }

  void endSession() {
    _sessionStart = null;
  }

  void recordForeground() {
    _lastForegroundTime = DateTime.now();
  }
}

class LifecycleEvent {
  final String event;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  LifecycleEvent({
    required this.event,
    required this.timestamp,
    this.metadata,
  });
}

/// Connectivity metrics
class ConnectivityMetrics {
  final List<ConnectivityEvent> events = [];
  bool? _lastKnownState;
  DateTime? _lastStateChange;

  int get totalStateChanges => events.length;

  Duration? get currentOfflineDuration {
    if (_lastKnownState == true || _lastStateChange == null) return null;
    return DateTime.now().difference(_lastStateChange!);
  }

  bool? get lastKnownState => _lastKnownState;

  void recordStateChange(bool isOnline) {
    _lastKnownState = isOnline;
    _lastStateChange = DateTime.now();
  }
}

class ConnectivityEvent {
  final bool isOnline;
  final DateTime timestamp;
  final String? networkType;

  ConnectivityEvent({
    required this.isOnline,
    required this.timestamp,
    this.networkType,
  });
}

/// Error metrics
class ErrorMetrics {
  final Map<String, List<ErrorEvent>> errors = {};

  int get totalErrors => errors.values.fold(0, (sum, list) => sum + list.length);

  int getErrorCount(String type) {
    return errors[type]?.length ?? 0;
  }

  double get errorRate {
    // Error rate is calculated as errors per hour (approximate)
    if (errors.isEmpty) return 0.0;
    final oldestError = errors.values
        .expand((list) => list)
        .map((e) => e.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final hoursSinceOldest = DateTime.now().difference(oldestError).inHours;
    if (hoursSinceOldest == 0) return totalErrors.toDouble();
    return totalErrors / hoursSinceOldest;
  }
}

class ErrorEvent {
  final String type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  ErrorEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.context,
  });
}

/// In-memory metrics aggregator
class MetricsCollector {
  final CacheMetrics _cacheMetrics = CacheMetrics();
  final APIMetrics _apiMetrics = APIMetrics();
  final OptimisticMetrics _optimisticMetrics = OptimisticMetrics();
  final UserInteractionMetrics _userInteractionMetrics = UserInteractionMetrics();
  final LifecycleMetrics _lifecycleMetrics = LifecycleMetrics();
  final ConnectivityMetrics _connectivityMetrics = ConnectivityMetrics();
  final ErrorMetrics _errorMetrics = ErrorMetrics();

  /// Track a cache hit
  void trackCacheHit(String key) {
    _cacheMetrics.hits++;
  }

  /// Track a cache miss
  void trackCacheMiss(String key) {
    _cacheMetrics.misses++;
  }

  /// Track an API call with success status and latency
  void trackAPICall(String endpoint, bool success, double latencyMs) {
    final calls = _apiMetrics.calls.putIfAbsent(endpoint, () => []);
    calls.add(APICall(
      endpoint: endpoint,
      success: success,
      latencyMs: latencyMs,
      timestamp: DateTime.now(),
    ));

    // Keep only last 1000 calls per endpoint to prevent memory issues
    if (calls.length > 1000) {
      calls.removeRange(0, calls.length - 1000);
    }
  }

  /// Track an optimistic action
  void trackOptimisticAction(String action, bool success) {
    final actions = _optimisticMetrics.actions.putIfAbsent(action, () => []);
    actions.add(OptimisticAction(
      action: action,
      success: success,
      timestamp: DateTime.now(),
    ));

    // Keep only last 1000 actions per type to prevent memory issues
    if (actions.length > 1000) {
      actions.removeRange(0, actions.length - 1000);
    }
  }

  /// Get cache metrics
  CacheMetrics getCacheMetrics() => _cacheMetrics;

  /// Get API metrics
  APIMetrics getAPIMetrics() => _apiMetrics;

  /// Get optimistic metrics
  OptimisticMetrics getOptimisticMetrics() => _optimisticMetrics;

  /// Get user interaction metrics
  UserInteractionMetrics getUserInteractionMetrics() => _userInteractionMetrics;

  /// Get lifecycle metrics
  LifecycleMetrics getLifecycleMetrics() => _lifecycleMetrics;

  /// Get connectivity metrics
  ConnectivityMetrics getConnectivityMetrics() => _connectivityMetrics;

  /// Get error metrics
  ErrorMetrics getErrorMetrics() => _errorMetrics;

  /// Track a user interaction (screen view, button click, etc.)
  void trackUserInteraction(String type, {Map<String, dynamic>? parameters}) {
    final interactions = _userInteractionMetrics.interactions.putIfAbsent(type, () => []);
    interactions.add(UserInteraction(
      type: type,
      parameters: parameters,
      timestamp: DateTime.now(),
    ));

    // Keep only last 1000 interactions per type to prevent memory issues
    if (interactions.length > 1000) {
      interactions.removeRange(0, interactions.length - 1000);
    }
  }

  /// Track a screen view
  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    trackUserInteraction('screen_view', parameters: {
      'screen': screenName,
      ...?parameters,
    });
  }

  /// Track an app lifecycle event
  void trackLifecycleEvent(String event, {Map<String, dynamic>? metadata}) {
    _lifecycleMetrics.events.add(LifecycleEvent(
      event: event,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));

    // Handle specific lifecycle events
    switch (event) {
      case 'app_foregrounded':
        _lifecycleMetrics.startSession();
        _lifecycleMetrics.recordForeground();
        break;
      case 'app_backgrounded':
      case 'app_paused':
        _lifecycleMetrics.endSession();
        break;
    }

    // Keep only last 500 events to prevent memory issues
    if (_lifecycleMetrics.events.length > 500) {
      _lifecycleMetrics.events.removeRange(0, _lifecycleMetrics.events.length - 500);
    }
  }

  /// Track a connectivity state change
  void trackConnectivityChange(bool isOnline, {String? networkType}) {
    _connectivityMetrics.events.add(ConnectivityEvent(
      isOnline: isOnline,
      timestamp: DateTime.now(),
      networkType: networkType,
    ));
    _connectivityMetrics.recordStateChange(isOnline);

    // Keep only last 200 events to prevent memory issues
    if (_connectivityMetrics.events.length > 200) {
      _connectivityMetrics.events.removeRange(0, _connectivityMetrics.events.length - 200);
    }
  }

  /// Track an error
  void trackError(String type, String message, {Map<String, dynamic>? context}) {
    final errors = _errorMetrics.errors.putIfAbsent(type, () => []);
    errors.add(ErrorEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      context: context,
    ));

    // Keep only last 500 errors per type to prevent memory issues
    if (errors.length > 500) {
      errors.removeRange(0, errors.length - 500);
    }
  }

  /// Reset all metrics
  void reset() {
    _cacheMetrics.hits = 0;
    _cacheMetrics.misses = 0;
    _apiMetrics.calls.clear();
    _optimisticMetrics.actions.clear();
    _userInteractionMetrics.interactions.clear();
    _lifecycleMetrics.events.clear();
    _lifecycleMetrics.endSession();
    _connectivityMetrics.events.clear();
    _errorMetrics.errors.clear();
  }
}

/// Provider for MetricsCollector instance
final metricsCollectorProvider = Provider<MetricsCollector>((ref) {
  return MetricsCollector();
});

