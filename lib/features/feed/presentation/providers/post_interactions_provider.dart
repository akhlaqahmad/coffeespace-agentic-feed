import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_providers.dart';
import '../../../../core/metrics/metrics_collector.dart';
import '../../../../core/network/request_manager.dart';
import '../../../../core/utils/connectivity_monitor.dart';
import '../../../../shared/providers/error_provider.dart';
import '../../data/models/post.dart';
import '../../data/models/optimistic_state.dart';
import '../../data/repositories/feed_repository.dart';
import '../providers/feed_provider.dart';

/// State class for tracking interaction requests
class _InteractionRequest {
  final String requestId;
  final DateTime timestamp;
  final Post originalPost;

  _InteractionRequest({
    required this.requestId,
    required this.timestamp,
    required this.originalPost,
  });
}

/// Provider for like interactions with optimistic updates
class LikeInteractionNotifier extends StateNotifier<Map<String, Post>> {
  final FeedRepository _repository;
  final Ref _ref;
  final Map<String, _InteractionRequest> _pendingRequests = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Timer> _timeoutTimers = {};
  RequestManager? _requestManager;

  LikeInteractionNotifier(this._repository, this._ref) : super({}) {
    _initialize();
  }

  void _initialize() {
    _requestManager = _ref.createRequestManager();
    _ref.onDispose(() {
      _requestManager?.dispose();
      _debounceTimers.values.forEach((timer) => timer.cancel());
      _timeoutTimers.values.forEach((timer) => timer.cancel());
    });
  }

  /// Toggles like status with optimistic updates
  /// 
  /// Implements:
  /// - Debounce (500ms) to prevent double-taps
  /// - Request ID tracking to prevent race conditions
  /// - Optimistic state updates (pending -> confirmed/failed)
  /// - Timeout handling (revert after 10s)
  /// - Cache updates
  Future<void> toggleLike(String postId) async {
    // Cancel existing debounce timer
    _debounceTimers[postId]?.cancel();

    // Get current post from feed provider
    final feedState = _ref.read(feedProvider).valueOrNull;
    if (feedState == null) return;

    final currentPost = feedState.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found: $postId'),
    );

    // Check if there's a pending request (prevent concurrent actions)
    if (_pendingRequests.containsKey(postId)) {
      // Cancel old request and let new one proceed
      _pendingRequests[postId]!.requestId;
      _timeoutTimers[postId]?.cancel();
    }

    // Generate new request ID
    final requestId = 'like_${DateTime.now().millisecondsSinceEpoch}_${postId}';
    final originalPost = currentPost;

    // Store pending request
    _pendingRequests[postId] = _InteractionRequest(
      requestId: requestId,
      timestamp: DateTime.now(),
      originalPost: originalPost,
    );

    // Debounce: wait 500ms before executing
    final debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _executeLikeToggle(postId, requestId, originalPost);
    });
    _debounceTimers[postId] = debounceTimer;
  }

  Future<void> _executeLikeToggle(
    String postId,
    String requestId,
    Post originalPost,
  ) async {
    // Check if this request is still the latest
    final currentRequest = _pendingRequests[postId];
    if (currentRequest == null || currentRequest.requestId != requestId) {
      return; // A newer request exists, ignore this one
    }

    // Get current post from feed provider
    final feedState = _ref.read(feedProvider).valueOrNull;
    if (feedState == null) return;

    final currentPost = feedState.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => originalPost,
    );

    // Step 1: Optimistic update - set to pending
    final optimisticPost = currentPost.copyWith(
      isLiked: !currentPost.isLiked,
      likeCount: currentPost.isLiked
          ? currentPost.likeCount - 1
          : currentPost.likeCount + 1,
      optimisticState: OptimisticState.pending,
    );

    // Update feed provider state immediately
    _updateFeedPost(postId, optimisticPost);

    // Update cache synchronously
    await _updateCache(postId, optimisticPost);

    // Step 2: Set timeout timer (10 seconds)
    final timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_pendingRequests[postId]?.requestId == requestId) {
        _revertLikeToggle(postId, originalPost, 'Request timeout');
      }
    });
    _timeoutTimers[postId] = timeoutTimer;

    // Step 3: Check connectivity before making API call
    final isOnline = await _ref.read(isOnlineProvider.future);
    if (!isOnline) {
      // Offline: revert optimistic update and show error
      _revertLikeToggle(
        postId,
        originalPost,
        'No internet connection',
      );
      _ref.read(errorProvider.notifier).addError(
        AppError(
          message: 'Cannot like post while offline',
          errorType: ErrorType.network,
        ),
      );
      return;
    }

    // Step 4: Make API call in background
    try {
      final updatedPost = await _repository.toggleLike(
        postId: postId,
        cancelToken: _requestManager?.cancelToken,
      );

      // Check if this request is still the latest
      if (_pendingRequests[postId]?.requestId != requestId) {
        return; // A newer request exists, ignore this response
      }

      // Step 5: On success - update to confirmed
      final metricsCollector = _ref.read(metricsCollectorProvider);
      metricsCollector.trackOptimisticAction('like', true);

      final confirmedPost = updatedPost.copyWith(
        optimisticState: OptimisticState.confirmed,
      );

      _updateFeedPost(postId, confirmedPost);
      await _updateCache(postId, confirmedPost);

      // Cleanup
      _pendingRequests.remove(postId);
      _timeoutTimers[postId]?.cancel();
      _timeoutTimers.remove(postId);
    } catch (e) {
      // Check if this request is still the latest
      if (_pendingRequests[postId]?.requestId != requestId) {
        return; // A newer request exists, ignore this error
      }

      // Step 6: On failure - revert changes and set failed state
      _revertLikeToggle(postId, originalPost, e.toString());
    }
  }

  void _revertLikeToggle(String postId, Post originalPost, String error) {
    final metricsCollector = _ref.read(metricsCollectorProvider);
    metricsCollector.trackOptimisticAction('like', false);

    final failedPost = originalPost.copyWith(
      optimisticState: OptimisticState.failed,
    );

    _updateFeedPost(postId, failedPost);
    _updateCache(postId, failedPost);

    // Cleanup
    _pendingRequests.remove(postId);
    _timeoutTimers[postId]?.cancel();
    _timeoutTimers.remove(postId);

    // Show error banner for optimistic failure
    if (error.contains('DioException') || error.contains('network')) {
      _ref.read(errorProvider.notifier).addOptimisticFailure(
        'Failed to like post. Please try again.',
      );
    } else {
      _ref.read(errorProvider.notifier).addOptimisticFailure(
        'Failed to like post. Please try again.',
      );
    }
  }

  void _updateFeedPost(String postId, Post updatedPost) {
    final feedNotifier = _ref.read(feedProvider.notifier);
    feedNotifier.updatePost(postId, updatedPost);
  }

  Future<void> _updateCache(String postId, Post updatedPost) async {
    final cacheManager = _ref.read(cacheManagerProvider);
    final cacheKey = 'post_$postId';
    await cacheManager.set<Post>(cacheKey, updatedPost);
  }
}

/// Provider for like interactions
final likeInteractionProvider =
    StateNotifierProvider<LikeInteractionNotifier, Map<String, Post>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return LikeInteractionNotifier(repository, ref);
});

/// Provider for repost interactions with optimistic updates
class RepostInteractionNotifier extends StateNotifier<Map<String, Post>> {
  final FeedRepository _repository;
  final Ref _ref;
  final Map<String, _InteractionRequest> _pendingRequests = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Timer> _timeoutTimers = {};
  RequestManager? _requestManager;

  RepostInteractionNotifier(this._repository, this._ref) : super({}) {
    _initialize();
  }

  void _initialize() {
    _requestManager = _ref.createRequestManager();
    _ref.onDispose(() {
      _requestManager?.dispose();
      _debounceTimers.values.forEach((timer) => timer.cancel());
      _timeoutTimers.values.forEach((timer) => timer.cancel());
    });
  }

  /// Toggles repost status with optimistic updates
  Future<void> toggleRepost(String postId) async {
    // Cancel existing debounce timer
    _debounceTimers[postId]?.cancel();

    // Get current post from feed provider
    final feedState = _ref.read(feedProvider).valueOrNull;
    if (feedState == null) return;

    final currentPost = feedState.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found: $postId'),
    );

    // Check if there's a pending request
    if (_pendingRequests.containsKey(postId)) {
      _timeoutTimers[postId]?.cancel();
    }

    // Generate new request ID
    final requestId = 'repost_${DateTime.now().millisecondsSinceEpoch}_$postId';
    final originalPost = currentPost;

    // Store pending request
    _pendingRequests[postId] = _InteractionRequest(
      requestId: requestId,
      timestamp: DateTime.now(),
      originalPost: originalPost,
    );

    // Debounce: wait 500ms before executing
    final debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _executeRepostToggle(postId, requestId, originalPost);
    });
    _debounceTimers[postId] = debounceTimer;
  }

  Future<void> _executeRepostToggle(
    String postId,
    String requestId,
    Post originalPost,
  ) async {
    // Check if this request is still the latest
    final currentRequest = _pendingRequests[postId];
    if (currentRequest == null || currentRequest.requestId != requestId) {
      return;
    }

    // Get current post from feed provider
    final feedState = _ref.read(feedProvider).valueOrNull;
    if (feedState == null) return;

    final currentPost = feedState.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => originalPost,
    );

    // Step 1: Optimistic update - set to pending
    final optimisticPost = currentPost.copyWith(
      isReposted: !currentPost.isReposted,
      repostCount: currentPost.isReposted
          ? currentPost.repostCount - 1
          : currentPost.repostCount + 1,
      optimisticState: OptimisticState.pending,
    );

    // Update feed provider state immediately
    _updateFeedPost(postId, optimisticPost);

    // Update cache synchronously
    await _updateCache(postId, optimisticPost);

    // Step 2: Set timeout timer (10 seconds)
    final timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_pendingRequests[postId]?.requestId == requestId) {
        _revertRepostToggle(postId, originalPost, 'Request timeout');
      }
    });
    _timeoutTimers[postId] = timeoutTimer;

    // Step 3: Check connectivity before making API call
    final isOnline = await _ref.read(isOnlineProvider.future);
    if (!isOnline) {
      // Offline: revert optimistic update and show error
      _revertRepostToggle(
        postId,
        originalPost,
        'No internet connection',
      );
      _ref.read(errorProvider.notifier).addError(
        AppError(
          message: 'Cannot repost while offline',
          errorType: ErrorType.network,
        ),
      );
      return;
    }

    // Step 4: Make API call in background
    try {
      final updatedPost = await _repository.toggleRepost(
        postId: postId,
        cancelToken: _requestManager?.cancelToken,
      );

      // Check if this request is still the latest
      if (_pendingRequests[postId]?.requestId != requestId) {
        return;
      }

      // Step 5: On success - update to confirmed
      final metricsCollector = _ref.read(metricsCollectorProvider);
      metricsCollector.trackOptimisticAction('repost', true);

      final confirmedPost = updatedPost.copyWith(
        optimisticState: OptimisticState.confirmed,
      );

      _updateFeedPost(postId, confirmedPost);
      await _updateCache(postId, confirmedPost);

      // Cleanup
      _pendingRequests.remove(postId);
      _timeoutTimers[postId]?.cancel();
      _timeoutTimers.remove(postId);
    } catch (e) {
      // Check if this request is still the latest
      if (_pendingRequests[postId]?.requestId != requestId) {
        return;
      }

      // Step 6: On failure - revert changes and set failed state
      _revertRepostToggle(postId, originalPost, e.toString());
    }
  }

  void _revertRepostToggle(String postId, Post originalPost, String error) {
    final metricsCollector = _ref.read(metricsCollectorProvider);
    metricsCollector.trackOptimisticAction('repost', false);

    final failedPost = originalPost.copyWith(
      optimisticState: OptimisticState.failed,
    );

    _updateFeedPost(postId, failedPost);
    _updateCache(postId, failedPost);

    // Cleanup
    _pendingRequests.remove(postId);
    _timeoutTimers[postId]?.cancel();
    _timeoutTimers.remove(postId);

    // Show error banner for optimistic failure
    if (error.contains('DioException') || error.contains('network')) {
      _ref.read(errorProvider.notifier).addOptimisticFailure(
        'Failed to repost. Please try again.',
      );
    } else {
      _ref.read(errorProvider.notifier).addOptimisticFailure(
        'Failed to repost. Please try again.',
      );
    }
  }

  void _updateFeedPost(String postId, Post updatedPost) {
    final feedNotifier = _ref.read(feedProvider.notifier);
    feedNotifier.updatePost(postId, updatedPost);
  }

  Future<void> _updateCache(String postId, Post updatedPost) async {
    final cacheManager = _ref.read(cacheManagerProvider);
    final cacheKey = 'post_$postId';
    await cacheManager.set<Post>(cacheKey, updatedPost);
  }
}

/// Provider for repost interactions
final repostInteractionProvider =
    StateNotifierProvider<RepostInteractionNotifier, Map<String, Post>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return RepostInteractionNotifier(repository, ref);
});

