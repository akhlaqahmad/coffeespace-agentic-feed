import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/request_manager.dart';
import '../../data/models/post.dart';
import '../../data/models/reply.dart';
import '../../data/models/author.dart';
import '../../data/models/optimistic_state.dart';
import '../../data/repositories/feed_repository.dart';
import '../providers/feed_provider.dart';

/// State class for replies list
class RepliesState {
  final List<Reply> replies;
  final bool isLoading;
  final String? error;

  const RepliesState({
    this.replies = const [],
    this.isLoading = false,
    this.error,
  });

  RepliesState copyWith({
    List<Reply>? replies,
    bool? isLoading,
    String? error,
  }) {
    return RepliesState(
      replies: replies ?? this.replies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for replies with optimistic updates
class RepliesNotifier extends StateNotifier<RepliesState> {
  final FeedRepository _repository;
  final Ref _ref;
  final String _postId;
  final Map<String, String> _tempIdToRequestId = {};
  final Map<String, Timer> _timeoutTimers = {};
  RequestManager? _requestManager;

  RepliesNotifier(this._repository, this._ref, this._postId)
      : super(const RepliesState()) {
    _initialize();
  }

  void _initialize() {
    _requestManager = _ref.createRequestManager();
    _ref.onDispose(() {
      _requestManager?.dispose();
      _timeoutTimers.values.forEach((timer) => timer.cancel());
    });
    loadReplies();
  }

  /// Loads replies for the post
  Future<void> loadReplies() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final replies = await _repository.getReplies(
        postId: _postId,
        cancelToken: _requestManager?.cancelToken,
      );

      // Filter out any failed optimistic replies
      final confirmedReplies = replies.where((reply) {
        return reply.optimisticState != OptimisticState.failed;
      }).toList();

      state = state.copyWith(
        replies: confirmedReplies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Adds a reply with optimistic updates
  /// 
  /// Implements:
  /// - Temporary ID assignment until confirmed by API
  /// - Optimistic state updates (pending -> confirmed/failed)
  /// - Auto-refresh parent post's replyCount
  /// - Timeout handling (revert after 10s)
  /// - Prevents duplicates by tracking temp IDs
  Future<void> addReply(String content, Author currentUser) async {
    // Generate temporary ID
    final tempId = 'temp_reply_${DateTime.now().millisecondsSinceEpoch}';
    final requestId = 'reply_${DateTime.now().millisecondsSinceEpoch}_$_postId';

    // Store mapping
    _tempIdToRequestId[tempId] = requestId;

    // Step 1: Create optimistic reply with pending state
    final optimisticReply = Reply(
      id: tempId,
      postId: _postId,
      author: currentUser,
      content: content,
      createdAt: DateTime.now(),
      optimisticState: OptimisticState.pending,
    );

    // Update replies state immediately
    final updatedReplies = [optimisticReply, ...state.replies];
    state = state.copyWith(replies: updatedReplies);

    // Update parent post's replyCount optimistically
    _updateParentPostReplyCount(1);

    // Step 2: Set timeout timer (10 seconds)
    final timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_tempIdToRequestId[tempId] == requestId) {
        _revertReply(tempId, 'Request timeout');
      }
    });
    _timeoutTimers[tempId] = timeoutTimer;

    // Step 3: Make API call in background
    try {
      final confirmedReply = await _repository.addReply(
        postId: _postId,
        content: content,
        cancelToken: _requestManager?.cancelToken,
      );

      // Check if this request is still valid
      if (_tempIdToRequestId[tempId] != requestId) {
        return; // A newer request exists or was reverted
      }

      // Step 4: On success - replace temp reply with confirmed reply
      final updatedRepliesList = state.replies.map((reply) {
        if (reply.id == tempId) {
          return confirmedReply.copyWith(
            optimisticState: OptimisticState.confirmed,
          );
        }
        return reply;
      }).toList();

      // Remove any duplicates (in case API returned same reply)
      final seenIds = <String>{};
      final deduplicatedReplies = updatedRepliesList.where((reply) {
        if (seenIds.contains(reply.id)) {
          return false;
        }
        seenIds.add(reply.id);
        return true;
      }).toList();

      state = state.copyWith(replies: deduplicatedReplies);

      // Cleanup
      _tempIdToRequestId.remove(tempId);
      _timeoutTimers[tempId]?.cancel();
      _timeoutTimers.remove(tempId);
    } catch (e) {
      // Check if this request is still valid
      if (_tempIdToRequestId[tempId] != requestId) {
        return;
      }

      // Step 5: On failure - revert changes and set failed state
      _revertReply(tempId, e.toString());
    }
  }

  void _revertReply(String tempId, String error) {
    // Mark the reply as failed instead of removing it
    final updatedReplies = state.replies.map((reply) {
      if (reply.id == tempId) {
        return reply.copyWith(
          optimisticState: OptimisticState.failed,
        );
      }
      return reply;
    }).toList();

    state = state.copyWith(replies: updatedReplies);

    // Revert parent post's replyCount
    _updateParentPostReplyCount(-1);

    // Cleanup
    _tempIdToRequestId.remove(tempId);
    _timeoutTimers[tempId]?.cancel();
    _timeoutTimers.remove(tempId);
  }

  /// Retries a failed reply
  Future<void> retryReply(String replyId) async {
    // Find the failed reply
    final failedReply = state.replies.firstWhere(
      (reply) => reply.id == replyId,
      orElse: () => throw Exception('Reply not found: $replyId'),
    );

    if (failedReply.optimisticState != OptimisticState.failed) {
      return; // Only retry failed replies
    }

    // Remove the failed reply from the list
    final updatedReplies = state.replies
        .where((reply) => reply.id != replyId)
        .toList();

    state = state.copyWith(replies: updatedReplies);

    // Retry by calling addReply with the same content
    await addReply(failedReply.content, failedReply.author);
  }

  void _updateParentPostReplyCount(int delta) {
    final feedNotifier = _ref.read(feedProvider.notifier);
    feedNotifier.updatePostReplyCount(_postId, delta);
  }
}

/// Provider family for replies by post ID
final repliesProvider = StateNotifierProvider.family<
    RepliesNotifier, RepliesState, String>((ref, postId) {
  final repository = ref.watch(feedRepositoryProvider);
  return RepliesNotifier(repository, ref, postId);
});

/// Helper provider to get current user (mock for now)
/// In a real app, this would come from auth provider
final currentUserProvider = Provider<Author>((ref) {
  // Mock current user - replace with actual auth provider
  return const Author(
    id: 'current_user',
    username: 'current_user',
    displayName: 'Current User',
  );
});

