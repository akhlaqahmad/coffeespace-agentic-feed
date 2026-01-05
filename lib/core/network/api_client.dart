import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'models/feed_page.dart';
import '../../features/feed/data/models/post.dart';
import '../../features/feed/data/models/reply.dart';
import '../../features/feed/data/models/author.dart';
import 'mock_data.dart';

/// Mock API client for testing optimistic updates and offline scenarios
class ApiClient {
  final Dio _dio;
  final Random _random = Random();
  final MockDataGenerator _mockData = MockDataGenerator();
  double _currentFailureRate = 0.2;

  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = 'https://api.coffeespace.mock';
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  /// Get current failure rate
  double _getFailureRate() {
    return _currentFailureRate;
  }

  /// Set failure rate (called from debug menu)
  void setFailureRate(double rate) {
    _currentFailureRate = rate.clamp(0.0, 1.0);
  }

  /// Simulates network delay (300-800ms)
  Future<void> _simulateDelay() async {
    final delay = 300 + _random.nextInt(500); // 300-800ms
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Simulates network failure based on configurable rate
  void _simulateFailure() {
    final failureRate = _getFailureRate();
    if (_random.nextDouble() < failureRate) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
        error: 'Simulated network failure',
      );
    }
  }

  /// GET /feed?cursor={cursor}&limit=50
  /// Returns FeedPage with posts and nextCursor
  Future<FeedPage> getFeed({
    String? cursor,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    await _simulateDelay();
    _simulateFailure();

    if (cancelToken?.isCancelled == true) {
      throw DioException(
        requestOptions: RequestOptions(path: '/feed'),
        type: DioExceptionType.cancel,
      );
    }

    final posts = _mockData.getFeedPosts(cursor: cursor, limit: limit);
    final nextCursor = posts.length == limit
        ? 'cursor_${DateTime.now().millisecondsSinceEpoch}'
        : null;

    return FeedPage(
      posts: posts,
      nextCursor: nextCursor,
    );
  }

  /// POST /posts/{id}/like
  /// Toggles like, returns updated post
  Future<Post> toggleLike({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    await _simulateDelay();
    _simulateFailure();

    if (cancelToken?.isCancelled == true) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/like'),
        type: DioExceptionType.cancel,
      );
    }

    final post = _mockData.getPostById(postId);
    if (post == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/like'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/$postId/like'),
          statusCode: 404,
        ),
      );
    }

    return post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
  }

  /// POST /posts/{id}/repost
  /// Toggles repost, returns updated post
  Future<Post> toggleRepost({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    await _simulateDelay();
    _simulateFailure();

    if (cancelToken?.isCancelled == true) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/repost'),
        type: DioExceptionType.cancel,
      );
    }

    final post = _mockData.getPostById(postId);
    if (post == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/repost'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/$postId/repost'),
          statusCode: 404,
        ),
      );
    }

    return post.copyWith(
      isReposted: !post.isReposted,
      repostCount: post.isReposted ? post.repostCount - 1 : post.repostCount + 1,
    );
  }

  /// POST /posts/{id}/replies
  /// Creates reply, returns new reply
  Future<Reply> createReply({
    required String postId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    await _simulateDelay();
    _simulateFailure();

    if (cancelToken?.isCancelled == true) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/replies'),
        type: DioExceptionType.cancel,
      );
    }

    final post = _mockData.getPostById(postId);
    if (post == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/replies'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/$postId/replies'),
          statusCode: 404,
        ),
      );
    }

    final reply = _mockData.createReply(
      postId: postId,
      content: content,
    );

    // Update post reply count
    _mockData.updatePostReplyCount(postId, 1);

    return reply;
  }

  /// GET /posts/{id}/replies
  /// Returns list of replies
  Future<List<Reply>> getReplies({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    await _simulateDelay();
    _simulateFailure();

    if (cancelToken?.isCancelled == true) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/replies'),
        type: DioExceptionType.cancel,
      );
    }

    final post = _mockData.getPostById(postId);
    if (post == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$postId/replies'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/$postId/replies'),
          statusCode: 404,
        ),
      );
    }

    return _mockData.getRepliesByPostId(postId);
  }
}

