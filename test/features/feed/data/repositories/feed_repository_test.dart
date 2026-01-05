import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:coffeespace_agentic_feed/core/cache/cache_manager.dart';
import 'package:coffeespace_agentic_feed/core/metrics/metrics_collector.dart';
import 'package:coffeespace_agentic_feed/core/network/api_client.dart';
import 'package:coffeespace_agentic_feed/core/network/models/feed_page.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/author.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/repositories/feed_repository.dart';

import 'feed_repository_test.mocks.dart';

@GenerateMocks([ApiClient, CacheManager, MetricsCollector])
void main() {
  late MockApiClient mockApiClient;
  late MockCacheManager mockCacheManager;
  late MockMetricsCollector mockMetricsCollector;
  late FeedRepository repository;

  final testAuthor = const Author(
    id: 'test_author',
    username: 'test_user',
    displayName: 'Test User',
  );

  final testPost = Post(
    id: 'post_1',
    author: testAuthor,
    content: 'Test post content',
    createdAt: DateTime.now(),
    likeCount: 5,
    repostCount: 2,
    replyCount: 3,
    isLiked: false,
    isReposted: false,
  );

  setUp(() {
    mockApiClient = MockApiClient();
    mockCacheManager = MockCacheManager();
    mockMetricsCollector = MockMetricsCollector();
    repository = FeedRepository(
      apiClient: mockApiClient,
      cacheManager: mockCacheManager,
      metricsCollector: mockMetricsCollector,
    );
  });

  group('FeedRepository', () {
    group('getFeed', () {
      test('returns cached data immediately when available (cache hit)', () async {
        // Arrange
        final cachedFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        final cachedJson = cachedFeedPage.toJson();
        
        when(mockCacheManager.get<Map<String, dynamic>>('feed'))
            .thenReturn(cachedJson);
        when(mockCacheManager.get<Map<String, dynamic>>('feed_cursor_1'))
            .thenReturn(null);

        // Act
        final result = await repository.getFeed();

        // Assert
        expect(result.posts.length, 1);
        expect(result.posts[0].id, 'post_1');
        expect(result.nextCursor, 'cursor_1');
        verify(mockCacheManager.get<Map<String, dynamic>>('feed')).called(1);
      });

      test('fetches from API when cache is empty (cache miss)', () async {
        // Arrange
        final feedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        
        when(mockCacheManager.get<Map<String, dynamic>>('feed'))
            .thenReturn(null);
        when(mockApiClient.getFeed(cursor: null, cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => feedPage);
        when(mockCacheManager.set<Map<String, dynamic>>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getFeed();

        // Assert
        expect(result.posts.length, 1);
        expect(result.posts[0].id, 'post_1');
        verify(mockApiClient.getFeed(cursor: null, cancelToken: anyNamed('cancelToken'))).called(1);
        verify(mockCacheManager.set<Map<String, dynamic>>('feed', any, withTTL: anyNamed('withTTL'))).called(1);
      });

      test('uses stale-while-revalidate strategy - returns cache and fetches in background', () async {
        // Arrange
        final cachedFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        final cachedJson = cachedFeedPage.toJson();
        final freshFeedPage = FeedPage(
          posts: [testPost, testPost.copyWith(id: 'post_2')],
          nextCursor: 'cursor_2',
        );
        
        when(mockCacheManager.get<Map<String, dynamic>>('feed'))
            .thenReturn(cachedJson);
        when(mockApiClient.getFeed(cursor: null, cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => freshFeedPage);
        when(mockCacheManager.set<Map<String, dynamic>>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getFeed();
        
        // Wait a bit to ensure background fetch completes
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(result.posts.length, 1); // Should return cached data immediately
        verify(mockApiClient.getFeed(cursor: null, cancelToken: anyNamed('cancelToken'))).called(1);
        verify(mockCacheManager.set<Map<String, dynamic>>('feed', any, withTTL: anyNamed('withTTL'))).called(1);
      });

      test('returns stale cache when network fails', () async {
        // Arrange
        final cachedFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        final cachedJson = cachedFeedPage.toJson();
        
        when(mockCacheManager.get<Map<String, dynamic>>('feed'))
            .thenReturn(cachedJson);
        when(mockApiClient.getFeed(cursor: null, cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/feed'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act
        final result = await repository.getFeed();

        // Assert
        expect(result.posts.length, 1);
        expect(result.posts[0].id, 'post_1');
      });

      test('cancels request when cancelToken is provided', () async {
        // Arrange
        final cancelToken = CancelToken();
        cancelToken.cancel();
        
        when(mockCacheManager.get<Map<String, dynamic>>('feed'))
            .thenReturn(null);
        when(mockApiClient.getFeed(cursor: null, cancelToken: cancelToken))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/feed'),
              type: DioExceptionType.cancel,
            ));

        // Act & Assert
        expect(
          () => repository.getFeed(cancelToken: cancelToken),
          throwsA(isA<DioException>()),
        );
      });

      test('handles pagination with cursor', () async {
        // Arrange
        final feedPage = FeedPage(
          posts: [testPost.copyWith(id: 'post_2')],
          nextCursor: 'cursor_2',
        );
        
        when(mockCacheManager.get<Map<String, dynamic>>('feed_cursor_1'))
            .thenReturn(null);
        when(mockApiClient.getFeed(cursor: 'cursor_1', cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => feedPage);
        when(mockCacheManager.set<Map<String, dynamic>>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getFeed(cursor: 'cursor_1');

        // Assert
        expect(result.posts.length, 1);
        expect(result.posts[0].id, 'post_2');
        verify(mockApiClient.getFeed(cursor: 'cursor_1', cancelToken: anyNamed('cancelToken'))).called(1);
      });
    });

    group('toggleLike', () {
      test('toggles like and tracks metrics', () async {
        // Arrange
        final updatedPost = testPost.copyWith(
          isLiked: true,
          likeCount: 6,
        );
        
        when(mockApiClient.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => updatedPost);

        // Act
        final result = await repository.toggleLike(postId: 'post_1');

        // Assert
        expect(result.isLiked, true);
        expect(result.likeCount, 6);
        verify(mockApiClient.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).called(1);
        verify(mockMetricsCollector.trackAPICall(any, any, any)).called(1);
      });

      test('tracks failed API calls', () async {
        // Arrange
        when(mockApiClient.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/posts/post_1/like'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => repository.toggleLike(postId: 'post_1'),
          throwsA(isA<DioException>()),
        );
        verify(mockMetricsCollector.trackAPICall(any, false, any)).called(1);
      });
    });

    group('toggleRepost', () {
      test('toggles repost and tracks metrics', () async {
        // Arrange
        final updatedPost = testPost.copyWith(
          isReposted: true,
          repostCount: 3,
        );
        
        when(mockApiClient.toggleRepost(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => updatedPost);

        // Act
        final result = await repository.toggleRepost(postId: 'post_1');

        // Assert
        expect(result.isReposted, true);
        expect(result.repostCount, 3);
        verify(mockApiClient.toggleRepost(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).called(1);
        verify(mockMetricsCollector.trackAPICall(any, any, any)).called(1);
      });
    });

    group('clearCache', () {
      test('clears feed cache and cursor cache', () async {
        // Arrange
        when(mockCacheManager.delete(any)).thenAnswer((_) async {});
        when(mockCacheManager.getKeys()).thenReturn(['feed', 'feed_cursor', 'feed_cursor_1']);

        // Act
        await repository.clearCache();

        // Assert
        verify(mockCacheManager.delete('feed')).called(1);
        verify(mockCacheManager.delete('feed_cursor')).called(1);
        verify(mockCacheManager.delete('feed_cursor_1')).called(1);
      });
    });
  });
}

