import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_manager.dart';
import '../metrics/metrics_collector.dart';

/// Provider for the global CacheManager instance.
final cacheManagerProvider = Provider<CacheManager>((ref) {
  final metricsCollector = ref.watch(metricsCollectorProvider);
  final manager = CacheManager(metricsCollector: metricsCollector);
  manager.initialize();
  return manager;
});

