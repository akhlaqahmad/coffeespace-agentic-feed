import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/request_manager.dart';
import '../../../../core/utils/app_lifecycle.dart';
import '../../data/repositories/feed_repository.dart';
import '../../data/models/post.dart';
import '../../../../core/network/models/feed_page.dart';

/// Provider for ApiClient instance.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for FeedRepository instance.
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    apiClient: ref.watch(apiClientProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
});

/// State class for feed with pagination support.
class FeedState {
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  FeedState copyWith({
    List<Post>? posts,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }

  bool get hasMore => nextCursor != null;
}

/// Notifier for feed state management with pagination.
class FeedNotifier extends StateNotifier<AsyncValue<FeedState>> {
  final FeedRepository _repository;
  final Ref _ref;
  RequestManager? _requestManager;
  CancelToken? _currentCancelToken;

  FeedNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    // Create request manager that cancels on dispose
    _requestManager = _ref.createRequestManager();
    _currentCancelToken = _requestManager!.cancelToken;

    // Load initial feed
    loadInitial();

    // Listen to app lifecycle and cancel requests when backgrounded
    _ref.listen<AppLifecycleState>(
      appLifecycleProvider,
      (previous, next) {
        if (next.isBackgrounded && _currentCancelToken != null) {
          _currentCancelToken!.cancel('App backgrounded');
        }
      },
    );

    // Cancel requests on dispose
    _ref.onDispose(() {
      _requestManager?.dispose();
    });
  }

  /// Loads the initial feed page.
  /// 
  /// Shows cached data immediately, then fetches fresh data.
  Future<void> loadInitial() async {
    state = const AsyncValue.loading();

    // Try to get cached data immediately
    final cachedFeed = _repository.getCachedFeed();
    if (cachedFeed != null) {
      state = AsyncValue.data(
        FeedState(
          posts: cachedFeed.posts,
          nextCursor: cachedFeed.nextCursor,
        ),
      );
    }

    // Fetch fresh data
    try {
      _currentCancelToken = _requestManager?.cancelToken;
      final feedPage = await _repository.getFeed(
        cancelToken: _currentCancelToken,
      );

      state = AsyncValue.data(
        FeedState(
          posts: feedPage.posts,
          nextCursor: feedPage.nextCursor,
        ),
      );
    } catch (e, stackTrace) {
      // If we have cached data, keep showing it
      if (cachedFeed != null) {
        state = AsyncValue.data(
          FeedState(
            posts: cachedFeed.posts,
            nextCursor: cachedFeed.nextCursor,
            error: e.toString(),
          ),
        );
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Loads more feed items (pagination).
  /// 
  /// Appends new posts to the existing list using cursor-based pagination.
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true),
    );

    try {
      _currentCancelToken = _requestManager?.cancelToken;
      final feedPage = await _repository.getFeed(
        cursor: currentState.nextCursor,
        cancelToken: _currentCancelToken,
      );

      final updatedState = currentState.copyWith(
        posts: [...currentState.posts, ...feedPage.posts],
        nextCursor: feedPage.nextCursor,
        isLoadingMore: false,
      );

      state = AsyncValue.data(updatedState);
    } catch (e, stackTrace) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Refreshes the feed (pull-to-refresh).
  /// 
  /// Clears cache and fetches fresh data from the beginning.
  Future<void> refresh() async {
    // Clear cache
    await _repository.clearCache();

    // Reset state and load fresh data
    state = const AsyncValue.loading();

    try {
      _currentCancelToken = _requestManager?.cancelToken;
      final feedPage = await _repository.getFeed(
        cancelToken: _currentCancelToken,
      );

      state = AsyncValue.data(
        FeedState(
          posts: feedPage.posts,
          nextCursor: feedPage.nextCursor,
        ),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Toggles like status for a post.
  /// 
  /// Updates the post in the feed state optimistically.
  /// 
  /// NOTE: This method is kept for backward compatibility.
  /// New code should use likeInteractionProvider instead.
  @Deprecated('Use likeInteractionProvider.toggleLike instead')
  Future<void> toggleLike(String postId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
        );
      }
      return post;
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(posts: updatedPosts),
    );

    // Make API call
    try {
      _currentCancelToken = _requestManager?.cancelToken;
      final updatedPost = await _repository.toggleLike(
        postId: postId,
        cancelToken: _currentCancelToken,
      );

      // Update with server response
      final finalPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          return updatedPost;
        }
        return post;
      }).toList();

      state = AsyncValue.data(
        currentState.copyWith(posts: finalPosts),
      );
    } catch (e) {
      // Revert optimistic update on error
      state = AsyncValue.data(
        currentState.copyWith(posts: currentState.posts),
      );
      rethrow;
    }
  }

  /// Toggles repost status for a post.
  /// 
  /// Updates the post in the feed state optimistically.
  /// 
  /// NOTE: This method is kept for backward compatibility.
  /// New code should use repostInteractionProvider instead.
  @Deprecated('Use repostInteractionProvider.toggleRepost instead')
  Future<void> toggleRepost(String postId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isReposted: !post.isReposted,
          repostCount:
              post.isReposted ? post.repostCount - 1 : post.repostCount + 1,
        );
      }
      return post;
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(posts: updatedPosts),
    );

    // Make API call
    try {
      _currentCancelToken = _requestManager?.cancelToken;
      final updatedPost = await _repository.toggleRepost(
        postId: postId,
        cancelToken: _currentCancelToken,
      );

      // Update with server response
      final finalPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          return updatedPost;
        }
        return post;
      }).toList();

      state = AsyncValue.data(
        currentState.copyWith(posts: finalPosts),
      );
    } catch (e) {
      // Revert optimistic update on error
      state = AsyncValue.data(
        currentState.copyWith(posts: currentState.posts),
      );
      rethrow;
    }
  }

  /// Updates a single post in the feed state.
  /// 
  /// Used by interaction providers to update posts optimistically.
  /// This method ensures thread-safe updates and prevents duplicates.
  void updatePost(String postId, Post updatedPost) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedPosts = currentState.posts.map((post) {
      return post.id == postId ? updatedPost : post;
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(posts: updatedPosts),
    );
  }

  /// Updates the reply count for a post.
  /// 
  /// Used by replies provider to update parent post's replyCount.
  void updatePostReplyCount(String postId, int delta) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedPosts = currentState.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          replyCount: (post.replyCount + delta).clamp(0, double.infinity).toInt(),
        );
      }
      return post;
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(posts: updatedPosts),
    );
  }
}

/// Provider for feed state management.
final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<FeedState>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repository, ref);
});

