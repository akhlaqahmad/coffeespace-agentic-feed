import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_manager.dart';

/// Provider for the global CacheManager instance.
final cacheManagerProvider = Provider<CacheManager>((ref) {
  final manager = CacheManager();
  manager.initialize();
  return manager;
});

