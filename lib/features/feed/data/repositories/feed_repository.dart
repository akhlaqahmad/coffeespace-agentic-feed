import 'package:dio/dio.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/models/feed_page.dart';
import '../models/post.dart';
import '../models/reply.dart';

/// Repository for feed data operations.
/// 
/// Handles fetching feed data from API, caching, and managing feed-related
/// operations like likes, reposts, and replies. Uses staleWhileRevalidate
/// strategy for optimal user experience.
class FeedRepository {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  static const String _feedCacheKey = 'feed';
  static const String _feedCursorCacheKey = 'feed_cursor';

  FeedRepository({
    required ApiClient apiClient,
    required CacheManager cacheManager,
  })  : _apiClient = apiClient,
        _cacheManager = cacheManager;

  /// Fetches feed from API with optional cursor for pagination.
  /// 
  /// Uses staleWhileRevalidate strategy: returns cached data immediately
  /// if available, then fetches fresh data in the background.
  /// 
  /// [cursor] - Optional cursor for pagination
  /// [cancelToken] - Token to cancel the request
  /// 
  /// Returns [FeedPage] with posts and nextCursor
  Future<FeedPage> getFeed({
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    // Use staleWhileRevalidate strategy for optimal UX
    final cacheKey = cursor == null ? _feedCacheKey : '$_feedCacheKey_$cursor';
    
    // Get cached data immediately if available
    final cachedJson = _cacheManager.get<Map<String, dynamic>>(cacheKey);
    FeedPage? cachedFeed;
    if (cachedJson != null) {
      try {
        cachedFeed = FeedPage.fromJson(cachedJson);
      } catch (e) {
        // Invalid cache, ignore
      }
    }

    // Return cached data immediately if available
    if (cachedFeed != null) {
      // Fetch fresh data in background (don't await)
      _apiClient.getFeed(
        cursor: cursor,
        cancelToken: cancelToken,
      ).then((freshFeed) async {
        await _cacheManager.set<Map<String, dynamic>>(
          cacheKey,
          freshFeed.toJson(),
        );
      }).catchError((e) {
        // Silently handle background fetch errors
      });
      
      return cachedFeed;
    }

    // No cache, fetch from network
    try {
      final feedPage = await _apiClient.getFeed(
        cursor: cursor,
        cancelToken: cancelToken,
      );
      await _cacheManager.set<Map<String, dynamic>>(
        cacheKey,
        feedPage.toJson(),
      );
      return feedPage;
    } catch (e) {
      // If network fails and we have stale cache, return it
      if (cachedFeed != null) {
        return cachedFeed;
      }
      rethrow;
    }
  }

  /// Gets cached feed data without making network request.
  /// 
  /// Returns the most recent cached feed page, or null if no cache exists.
  FeedPage? getCachedFeed() {
    final cachedFeed = _cacheManager.get<Map<String, dynamic>>(_feedCacheKey);
    if (cachedFeed != null) {
      try {
        return FeedPage.fromJson(cachedFeed);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Toggles like status for a post.
  /// 
  /// Makes API call to toggle like and returns updated post.
  /// 
  /// [postId] - ID of the post to toggle like
  /// [cancelToken] - Token to cancel the request
  /// 
  /// Returns updated [Post] with new like status
  Future<Post> toggleLike({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    final updatedPost = await _apiClient.toggleLike(
      postId: postId,
      cancelToken: cancelToken,
    );
    return updatedPost;
  }

  /// Toggles repost status for a post.
  /// 
  /// Makes API call to toggle repost and returns updated post.
  /// 
  /// [postId] - ID of the post to toggle repost
  /// [cancelToken] - Token to cancel the request
  /// 
  /// Returns updated [Post] with new repost status
  Future<Post> toggleRepost({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    final updatedPost = await _apiClient.toggleRepost(
      postId: postId,
      cancelToken: cancelToken,
    );
    return updatedPost;
  }

  /// Fetches replies for a specific post.
  /// 
  /// [postId] - ID of the post to get replies for
  /// [cancelToken] - Token to cancel the request
  /// 
  /// Returns list of [Reply] objects
  Future<List<Reply>> getReplies({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    final replies = await _apiClient.getReplies(
      postId: postId,
      cancelToken: cancelToken,
    );
    return replies;
  }

  /// Adds a reply to a post.
  /// 
  /// [postId] - ID of the post to reply to
  /// [content] - Content of the reply
  /// [cancelToken] - Token to cancel the request
  /// 
  /// Returns the newly created [Reply]
  Future<Reply> addReply({
    required String postId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    final reply = await _apiClient.createReply(
      postId: postId,
      content: content,
      cancelToken: cancelToken,
    );
    return reply;
  }

  /// Clears the feed cache.
  /// 
  /// Useful for pull-to-refresh scenarios.
  Future<void> clearCache() async {
    await _cacheManager.delete(_feedCacheKey);
    await _cacheManager.delete(_feedCursorCacheKey);
    // Clear all paginated feed caches
    final keys = _cacheManager.getKeys();
    for (final key in keys) {
      if (key.startsWith('$_feedCacheKey_')) {
        await _cacheManager.delete(key);
      }
    }
  }
}

