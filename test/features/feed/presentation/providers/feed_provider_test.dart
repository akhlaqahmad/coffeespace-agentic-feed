import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coffeespace_agentic_feed/core/cache/cache_manager.dart';
import 'package:coffeespace_agentic_feed/core/metrics/metrics_collector.dart';
import 'package:coffeespace_agentic_feed/core/network/api_client.dart';
import 'package:coffeespace_agentic_feed/core/network/models/feed_page.dart';
import 'package:coffeespace_agentic_feed/core/utils/connectivity_monitor.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/author.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/repositories/feed_repository.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/providers/feed_provider.dart';

import 'feed_provider_test.mocks.dart';

@GenerateMocks([FeedRepository, CacheManager, ApiClient, MetricsCollector])
void main() {
  late MockFeedRepository mockRepository;
  late ProviderContainer container;

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
    mockRepository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepository),
        isOnlineProvider.overrideWith((ref) => Future.value(true)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FeedNotifier', () {
    group('loadInitial', () {
      test('transitions from loading to success state', () async {
        // Arrange
        final feedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        
        when(mockRepository.getCachedFeed()).thenReturn(null);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => feedPage);

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        // Assert
        final state = container.read(feedProvider);
        expect(state.hasValue, true);
        expect(state.value!.posts.length, 1);
        expect(state.value!.posts[0].id, 'post_1');
        expect(state.value!.nextCursor, 'cursor_1');
        expect(state.value!.isFromCache, false);
      });

      test('shows cached data immediately then fetches fresh data', () async {
        // Arrange
        final cachedFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        final freshFeedPage = FeedPage(
          posts: [testPost, testPost.copyWith(id: 'post_2')],
          nextCursor: 'cursor_2',
        );
        
        when(mockRepository.getCachedFeed()).thenReturn(cachedFeedPage);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => freshFeedPage);

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        // Assert
        final state = container.read(feedProvider);
        expect(state.hasValue, true);
        // Should show fresh data after fetch
        expect(state.value!.posts.length, 2);
        expect(state.value!.isFromCache, false);
      });

      test('transitions to error state when fetch fails', () async {
        // Arrange
        when(mockRepository.getCachedFeed()).thenReturn(null);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/feed'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        // Assert
        final state = container.read(feedProvider);
        expect(state.hasError, true);
        expect(state.error, isA<DioException>());
      });

      test('keeps cached data when fetch fails', () async {
        // Arrange
        final cachedFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        
        when(mockRepository.getCachedFeed()).thenReturn(cachedFeedPage);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/feed'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        // Assert
        final state = container.read(feedProvider);
        expect(state.hasValue, true);
        expect(state.value!.posts.length, 1);
        expect(state.value!.isFromCache, true);
        expect(state.value!.error, isNotNull);
      });
    });

    group('loadMore', () {
      test('appends new posts to existing list (pagination)', () async {
        // Arrange
        final initialFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        final moreFeedPage = FeedPage(
          posts: [testPost.copyWith(id: 'post_2')],
          nextCursor: 'cursor_2',
        );
        
        when(mockRepository.getCachedFeed()).thenReturn(null);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => initialFeedPage);

        // Load initial data
        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        // Setup for loadMore
        when(mockRepository.getFeed(
          cursor: 'cursor_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => moreFeedPage);

        // Act
        await notifier.loadMore();

        // Assert
        final state = container.read(feedProvider);
        expect(state.value!.posts.length, 2);
        expect(state.value!.posts[0].id, 'post_1');
        expect(state.value!.posts[1].id, 'post_2');
        expect(state.value!.nextCursor, 'cursor_2');
        expect(state.value!.isLoadingMore, false);
      });

      test('does not load more when hasMore is false', () async {
        // Arrange
        final feedPage = FeedPage(
          posts: [testPost],
          nextCursor: null, // No more pages
        );
        
        when(mockRepository.getCachedFeed()).thenReturn(null);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => feedPage);

        // Load initial data
        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        // Act
        await notifier.loadMore();

        // Assert
        final state = container.read(feedProvider);
        expect(state.value!.posts.length, 1); // Should not have loaded more
        verify(mockRepository.getFeed(
          cursor: anyNamed('cursor'),
          cancelToken: anyNamed('cancelToken'),
        )).called(1); // Only initial load
      });

      test('sets isLoadingMore to true during pagination', () async {
        // Arrange
        final initialFeedPage = FeedPage(
          posts: [testPost],
          nextCursor: 'cursor_1',
        );
        final moreFeedPage = FeedPage(
          posts: [testPost.copyWith(id: 'post_2')],
          nextCursor: null,
        );
        
        when(mockRepository.getCachedFeed()).thenReturn(null);
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => initialFeedPage);

        final notifier = container.read(feedProvider.notifier);
        await notifier.loadInitial();

        when(mockRepository.getFeed(
          cursor: 'cursor_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async {
          // Check isLoadingMore is true
          final state = container.read(feedProvider);
          expect(state.value!.isLoadingMore, true);
          return moreFeedPage;
        });

        // Act
        await notifier.loadMore();

        // Assert
        final state = container.read(feedProvider);
        expect(state.value!.isLoadingMore, false);
      });
    });

    group('refresh', () {
      test('clears cache and fetches fresh data', () async {
        // Arrange
        final freshFeedPage = FeedPage(
          posts: [testPost, testPost.copyWith(id: 'post_2')],
          nextCursor: 'cursor_1',
        );
        
        when(mockRepository.clearCache()).thenAnswer((_) async {});
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => freshFeedPage);

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.refresh();

        // Assert
        final state = container.read(feedProvider);
        expect(state.value!.posts.length, 2);
        expect(state.value!.isFromCache, false);
        verify(mockRepository.clearCache()).called(1);
        verify(mockRepository.getFeed(cancelToken: anyNamed('cancelToken'))).called(1);
      });

      test('transitions to loading state during refresh', () async {
        // Arrange
        final feedPage = FeedPage(
          posts: [testPost],
          nextCursor: null,
        );
        
        when(mockRepository.clearCache()).thenAnswer((_) async {});
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async {
          // Check loading state
          final state = container.read(feedProvider);
          expect(state.isLoading, true);
          return feedPage;
        });

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.refresh();

        // Assert
        final state = container.read(feedProvider);
        expect(state.hasValue, true);
      });

      test('handles errors during refresh', () async {
        // Arrange
        when(mockRepository.clearCache()).thenAnswer((_) async {});
        when(mockRepository.getFeed(cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/feed'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act
        final notifier = container.read(feedProvider.notifier);
        await notifier.refresh();

        // Assert
        final state = container.read(feedProvider);
        expect(state.hasError, true);
      });
    });
  });
}

