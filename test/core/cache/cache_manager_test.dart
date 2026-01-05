import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:coffeespace_agentic_feed/core/cache/cache_manager.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/author.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/reply.dart';

void main() {
  late CacheManager cacheManager;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    cacheManager = CacheManager();
    await cacheManager.initialize();
  });

  tearDown(() async {
    await cacheManager.clear();
    await cacheManager.close();
    try {
      await Hive.deleteFromDisk();
    } catch (e) {
      // Ignore errors during cleanup
    }
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  });

  group('CacheManager', () {
    group('get and set', () {
      test('stores and retrieves string value', () async {
        // Arrange
        const key = 'test_string';
        const value = 'test_value';

        // Act
        await cacheManager.set<String>(key, value);
        final result = cacheManager.get<String>(key);

        // Assert
        expect(result, value);
      });

      test('stores and retrieves int value', () async {
        // Arrange
        const key = 'test_int';
        const value = 42;

        // Act
        await cacheManager.set<int>(key, value);
        final result = cacheManager.get<int>(key);

        // Assert
        expect(result, value);
      });

      test('returns null for non-existent key', () {
        // Act
        final result = cacheManager.get<String>('non_existent');

        // Assert
        expect(result, isNull);
      });

      test('stores and retrieves Post object', () async {
        // Arrange
        const key = 'test_post';
        final post = Post(
          id: 'post_1',
          author: const Author(
            id: 'author_1',
            username: 'test_user',
          ),
          content: 'Test content',
          createdAt: DateTime.now(),
          likeCount: 5,
          repostCount: 2,
          replyCount: 3,
          isLiked: false,
          isReposted: false,
        );

        // Act
        await cacheManager.set<Post>(key, post);
        final result = cacheManager.get<Post>(key);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'post_1');
        expect(result.content, 'Test content');
        expect(result.likeCount, 5);
      });

      test('stores and retrieves Reply object', () async {
        // Arrange
        const key = 'test_reply';
        final reply = Reply(
          id: 'reply_1',
          postId: 'post_1',
          author: const Author(
            id: 'author_1',
            username: 'test_user',
          ),
          content: 'Test reply',
          createdAt: DateTime.now(),
        );

        // Act
        await cacheManager.set<Reply>(key, reply);
        final result = cacheManager.get<Reply>(key);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'reply_1');
        expect(result.content, 'Test reply');
      });

      test('stores and retrieves Author object', () async {
        // Arrange
        const key = 'test_author';
        const author = Author(
          id: 'author_1',
          username: 'test_user',
          displayName: 'Test User',
        );

        // Act
        await cacheManager.set<Author>(key, author);
        final result = cacheManager.get<Author>(key);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'author_1');
        expect(result.username, 'test_user');
      });
    });

    group('getWithTTL', () {
      test('returns cached value when within TTL', () async {
        // Arrange
        const key = 'test_ttl';
        const value = 'test_value';
        await cacheManager.set<String>(key, value);

        // Act
        final result = cacheManager.getWithTTL<String>(key, ttl: const Duration(minutes: 5));

        // Assert
        expect(result, value);
      });

      test('returns null when TTL expired', () async {
        // Arrange
        const key = 'test_ttl_expired';
        const value = 'test_value';
        await cacheManager.set<String>(key, value);

        // Act - use very short TTL
        final result = cacheManager.getWithTTL<String>(
          key,
          ttl: const Duration(milliseconds: 1),
        );

        // Wait for TTL to expire
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        final resultAfterExpiry = cacheManager.getWithTTL<String>(
          key,
          ttl: const Duration(milliseconds: 1),
        );
        expect(resultAfterExpiry, isNull);
      });

      test('uses default TTL when not specified', () async {
        // Arrange
        const key = 'test_default_ttl';
        const value = 'test_value';
        await cacheManager.set<String>(key, value);

        // Act
        final result = cacheManager.getWithTTL<String>(key);

        // Assert
        expect(result, value);
      });
    });

    group('delete', () {
      test('deletes cached value', () async {
        // Arrange
        const key = 'test_delete';
        const value = 'test_value';
        await cacheManager.set<String>(key, value);
        expect(cacheManager.get<String>(key), value);

        // Act
        await cacheManager.delete(key);

        // Assert
        expect(cacheManager.get<String>(key), isNull);
      });

      test('deletes timestamp when deleting key', () async {
        // Arrange
        const key = 'test_delete_timestamp';
        const value = 'test_value';
        await cacheManager.set<String>(key, value);

        // Act
        await cacheManager.delete(key);

        // Assert - timestamp should also be deleted
        final result = cacheManager.getWithTTL<String>(key);
        expect(result, isNull);
      });
    });

    group('clear', () {
      test('clears all cached data', () async {
        // Arrange
        await cacheManager.set<String>('key1', 'value1');
        await cacheManager.set<String>('key2', 'value2');
        expect(cacheManager.get<String>('key1'), 'value1');
        expect(cacheManager.get<String>('key2'), 'value2');

        // Act
        await cacheManager.clear();

        // Assert
        expect(cacheManager.get<String>('key1'), isNull);
        expect(cacheManager.get<String>('key2'), isNull);
      });
    });

    group('containsKey', () {
      test('returns true for existing key', () async {
        // Arrange
        const key = 'test_contains';
        await cacheManager.set<String>(key, 'value');

        // Act
        final result = cacheManager.containsKey(key);

        // Assert
        expect(result, true);
      });

      test('returns false for non-existent key', () {
        // Act
        final result = cacheManager.containsKey('non_existent');

        // Assert
        expect(result, false);
      });
    });

    group('getKeys', () {
      test('returns all keys in cache', () async {
        // Arrange
        await cacheManager.set<String>('key1', 'value1');
        await cacheManager.set<String>('key2', 'value2');

        // Act
        final keys = cacheManager.getKeys();

        // Assert
        expect(keys.length, greaterThanOrEqualTo(2));
        expect(keys.contains('key1'), true);
        expect(keys.contains('key2'), true);
      });

      test('returns empty list when cache is empty', () {
        // Act
        final keys = cacheManager.getKeys();

        // Assert
        expect(keys.isEmpty, true);
      });
    });

    group('initialization', () {
      test('initializes cache manager', () async {
        // Arrange
        final newCacheManager = CacheManager();

        // Act
        await newCacheManager.initialize();

        // Assert
        expect(newCacheManager.containsKey('test'), false); // Should not throw
        await newCacheManager.close();
      });

      test('handles multiple initialization calls', () async {
        // Arrange
        final newCacheManager = CacheManager();

        // Act
        await newCacheManager.initialize();
        await newCacheManager.initialize(); // Second call

        // Assert - should not throw
        expect(newCacheManager.containsKey('test'), false);
        await newCacheManager.close();
      });
    });

    group('edge cases', () {
      test('handles null values gracefully', () async {
        // Act
        final result = cacheManager.get<String>('non_existent');

        // Assert
        expect(result, isNull);
      });

      test('handles empty string key', () async {
        // Arrange
        await cacheManager.set<String>('', 'value');

        // Act
        final result = cacheManager.get<String>('');

        // Assert
        expect(result, 'value');
      });

      test('overwrites existing value', () async {
        // Arrange
        const key = 'test_overwrite';
        await cacheManager.set<String>(key, 'value1');
        expect(cacheManager.get<String>(key), 'value1');

        // Act
        await cacheManager.set<String>(key, 'value2');

        // Assert
        expect(cacheManager.get<String>(key), 'value2');
      });
    });
  });
}

