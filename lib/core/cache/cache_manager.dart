import 'package:hive_flutter/hive_flutter.dart';
import '../../features/feed/data/models/post.dart';
import '../../features/feed/data/models/reply.dart';
import '../../features/feed/data/models/author.dart';

/// A generic cache manager that wraps Hive for typed caching operations.
/// 
/// Provides methods for storing, retrieving, and managing cached data with
/// TTL (Time To Live) support. Supports typed Hive boxes for type-safe operations.
class CacheManager {
  static const String _defaultBoxName = 'cache';
  static const Duration _defaultTTL = Duration(minutes: 5);

  Box? _box;
  bool _initialized = false;

  /// Initialize the cache manager and open the Hive box.
  /// 
  /// Should be called before using any cache operations.
  Future<void> initialize() async {
    if (_initialized) return;

    _box = await Hive.openBox(_defaultBoxName);
    _initialized = true;
  }

  /// Get a cached value by key.
  /// 
  /// Returns null if the key doesn't exist or if the cache is not initialized.
  T? get<T>(String key) {
    if (!_initialized || _box == null) return null;

    try {
      final value = _box!.get(key);
      if (value == null) return null;

      // Handle typed adapters for Post, Reply, and Author
      if (T == Post && value is Map) {
        return Post.fromJson(Map<String, dynamic>.from(value)) as T;
      } else if (T == Reply && value is Map) {
        return Reply.fromJson(Map<String, dynamic>.from(value)) as T;
      } else if (value is T) {
        return value;
      }

      // Try to deserialize from JSON if it's a Map
      if (value is Map) {
        if (T == Post) {
          return Post.fromJson(Map<String, dynamic>.from(value)) as T;
        } else if (T == Reply) {
          return Reply.fromJson(Map<String, dynamic>.from(value)) as T;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get a cached value with TTL check.
  /// 
  /// Returns the cached value if it exists and is less than [ttl] old.
  /// Returns null if the cache is stale, doesn't exist, or is not initialized.
  /// 
  /// If [ttl] is not provided, defaults to 5 minutes.
  T? getWithTTL<T>(String key, {Duration? ttl}) {
    if (!_initialized || _box == null) return null;

    final effectiveTTL = ttl ?? _defaultTTL;
    final timestampKey = '${key}_timestamp';
    
    try {
      final timestamp = _box!.get(timestampKey) as int?;
      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      if (now.difference(cachedTime) > effectiveTTL) {
        // Cache is stale, remove it
        delete(key);
        return null;
      }

      return get<T>(key);
    } catch (e) {
      return null;
    }
  }

  /// Store a value in the cache with optional TTL timestamp.
  /// 
  /// If [withTTL] is true, also stores a timestamp for TTL checking.
  /// 
  /// For Post and Reply objects, stores as JSON maps to work with Hive adapters.
  Future<void> set<T>(String key, T value, {bool withTTL = true}) async {
    if (!_initialized || _box == null) {
      await initialize();
    }

    try {
      // Convert Post, Reply, and Author to JSON for storage
      // This works with the registered Hive adapters
      if (value is Post) {
        await _box!.put(key, value.toJson());
      } else if (value is Reply) {
        await _box!.put(key, value.toJson());
      } else if (value is Author) {
        await _box!.put(key, value.toJson());
      } else {
        // For primitive types and other values, store directly
        await _box!.put(key, value);
      }

      if (withTTL) {
        final timestampKey = '${key}_timestamp';
        await _box!.put(timestampKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      // Handle errors silently or log them
      rethrow;
    }
  }

  /// Delete a cached value by key.
  /// 
  /// Also removes the associated timestamp if it exists.
  Future<void> delete(String key) async {
    if (!_initialized || _box == null) return;

    try {
      await _box!.delete(key);
      await _box!.delete('${key}_timestamp');
    } catch (e) {
      // Handle errors silently
    }
  }

  /// Clear all cached data.
  Future<void> clear() async {
    if (!_initialized || _box == null) return;

    try {
      await _box!.clear();
    } catch (e) {
      // Handle errors silently
    }
  }

  /// Check if a key exists in the cache.
  bool containsKey(String key) {
    if (!_initialized || _box == null) return false;
    return _box!.containsKey(key);
  }

  /// Get all keys in the cache.
  Iterable<String> getKeys() {
    if (!_initialized || _box == null) return [];
    return _box!.keys.cast<String>();
  }

  /// Close the cache box.
  /// 
  /// Should be called when the cache is no longer needed.
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _initialized = false;
    }
  }
}

