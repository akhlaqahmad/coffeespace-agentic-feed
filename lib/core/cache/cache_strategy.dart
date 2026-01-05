import 'cache_manager.dart';

/// Cache strategy enum defining different caching behaviors.
enum CacheStrategy {
  /// Return cache if exists, else fetch from network.
  cacheFirst,

  /// Fetch from network first, fallback to cache on error.
  networkFirst,

  /// Return cache immediately, fetch in background and update cache.
  staleWhileRevalidate,
}

/// Result of a cache strategy execution.
class CacheResult<T> {
  final T? data;
  final bool fromCache;
  final bool isStale;

  const CacheResult({
    required this.data,
    required this.fromCache,
    this.isStale = false,
  });
}

/// Execute a cache strategy pattern.
/// 
/// [strategy] - The cache strategy to use
/// [cacheManager] - The cache manager instance
/// [key] - The cache key
/// [fetchFn] - Async function to fetch data from network
/// [ttl] - Optional TTL duration (defaults to 5 minutes)
/// 
/// Returns a [CacheResult] containing the data and metadata about its source.
Future<CacheResult<T>> executeCacheStrategy<T>({
  required CacheStrategy strategy,
  required CacheManager cacheManager,
  required String key,
  required Future<T> Function() fetchFn,
  Duration? ttl,
}) async {
  switch (strategy) {
    case CacheStrategy.cacheFirst:
      return _cacheFirst<T>(
        cacheManager: cacheManager,
        key: key,
        fetchFn: fetchFn,
      );

    case CacheStrategy.networkFirst:
      return _networkFirst<T>(
        cacheManager: cacheManager,
        key: key,
        fetchFn: fetchFn,
      );

    case CacheStrategy.staleWhileRevalidate:
      return _staleWhileRevalidate<T>(
        cacheManager: cacheManager,
        key: key,
        fetchFn: fetchFn,
        ttl: ttl,
      );
  }
}

/// Cache-first strategy: Return cache if exists, else fetch from network.
Future<CacheResult<T>> _cacheFirst<T>({
  required CacheManager cacheManager,
  required String key,
  required Future<T> Function() fetchFn,
}) async {
  // Try to get from cache first
  final cachedData = cacheManager.get<T>(key);
  if (cachedData != null) {
    return CacheResult<T>(
      data: cachedData,
      fromCache: true,
    );
  }

  // Cache miss, fetch from network
  try {
    final networkData = await fetchFn();
    await cacheManager.set<T>(key, networkData);
    return CacheResult<T>(
      data: networkData,
      fromCache: false,
    );
  } catch (e) {
    // Network error, return null data
    return CacheResult<T>(
      data: null,
      fromCache: false,
    );
  }
}

/// Network-first strategy: Fetch from network, fallback to cache on error.
Future<CacheResult<T>> _networkFirst<T>({
  required CacheManager cacheManager,
  required String key,
  required Future<T> Function() fetchFn,
}) async {
  // Try network first
  try {
    final networkData = await fetchFn();
    await cacheManager.set<T>(key, networkData);
    return CacheResult<T>(
      data: networkData,
      fromCache: false,
    );
  } catch (e) {
    // Network error, try cache
    final cachedData = cacheManager.get<T>(key);
    return CacheResult<T>(
      data: cachedData,
      fromCache: true,
    );
  }
}

/// Stale-while-revalidate strategy: Return cache immediately, fetch in background and update.
Future<CacheResult<T>> _staleWhileRevalidate<T>({
  required CacheManager cacheManager,
  required String key,
  required Future<T> Function() fetchFn,
  Duration? ttl,
}) async {
  // Get cached data (even if stale)
  final cachedData = cacheManager.get<T>(key);
  final isStale = cachedData != null && cacheManager.getWithTTL<T>(key, ttl: ttl) == null;

  // Return cached data immediately if available
  final result = CacheResult<T>(
    data: cachedData,
    fromCache: true,
    isStale: isStale,
  );

  // Fetch fresh data in background (don't await)
  fetchFn().then((networkData) async {
    await cacheManager.set<T>(key, networkData);
  }).catchError((e) {
    // Silently handle background fetch errors
  });

  // If no cache exists, wait for network fetch
  if (cachedData == null) {
    try {
      final networkData = await fetchFn();
      await cacheManager.set<T>(key, networkData);
      return CacheResult<T>(
        data: networkData,
        fromCache: false,
      );
    } catch (e) {
      return result; // Return null data if fetch fails
    }
  }

  return result;
}

