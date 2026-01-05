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

/// In-memory metrics aggregator
class MetricsCollector {
  final CacheMetrics _cacheMetrics = CacheMetrics();
  final APIMetrics _apiMetrics = APIMetrics();
  final OptimisticMetrics _optimisticMetrics = OptimisticMetrics();

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

  /// Reset all metrics
  void reset() {
    _cacheMetrics.hits = 0;
    _cacheMetrics.misses = 0;
    _apiMetrics.calls.clear();
    _optimisticMetrics.actions.clear();
  }
}

/// Provider for MetricsCollector instance
final metricsCollectorProvider = Provider<MetricsCollector>((ref) {
  return MetricsCollector();
});

