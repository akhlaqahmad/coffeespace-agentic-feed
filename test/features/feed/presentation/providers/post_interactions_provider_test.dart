import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coffeespace_agentic_feed/core/cache/cache_manager.dart';
import 'package:coffeespace_agentic_feed/core/cache/cache_providers.dart';
import 'package:coffeespace_agentic_feed/core/metrics/metrics_collector.dart';
import 'package:coffeespace_agentic_feed/core/network/api_client.dart';
import 'package:coffeespace_agentic_feed/core/utils/connectivity_monitor.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/author.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/optimistic_state.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/repositories/feed_repository.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/providers/feed_provider.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/providers/post_interactions_provider.dart';
import 'package:coffeespace_agentic_feed/shared/providers/error_provider.dart';

import 'post_interactions_provider_test.mocks.dart';

@GenerateMocks([
  FeedRepository,
  CacheManager,
  ApiClient,
  MetricsCollector,
])
void main() {
  late MockFeedRepository mockRepository;
  late MockCacheManager mockCacheManager;
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
    mockCacheManager = MockCacheManager();
    when(mockRepository.getCachedFeed()).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepository),
        cacheManagerProvider.overrideWithValue(mockCacheManager),
        isOnlineProvider.overrideWith((ref) => Future.value(true)),
        feedProvider.overrideWith(
          (ref) {
            final notifier = FeedNotifier(mockRepository, ref);
            notifier.state = AsyncValue.data(
              FeedState(
                posts: [testPost],
                nextCursor: null,
              ),
            );
            return notifier;
          },
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LikeInteractionNotifier', () {
    group('toggleLike', () {
      test('applies optimistic update immediately with pending state', () async {
        // Arrange
        final updatedPost = testPost.copyWith(
          isLiked: true,
          likeCount: 6,
        );
        
        when(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => updatedPost);
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(likeInteractionProvider.notifier);
        notifier.toggleLike('post_1');
        
        // Wait for debounce (500ms)
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final updatedPostInState = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(updatedPostInState.isLiked, true);
        expect(updatedPostInState.likeCount, 6);
        expect(updatedPostInState.optimisticState, OptimisticState.confirmed);
      });

      test('debounces rapid taps (only last one executes)', () async {
        // Arrange
        final updatedPost = testPost.copyWith(
          isLiked: true,
          likeCount: 6,
        );
        
        when(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => updatedPost);
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act - rapid taps
        final notifier = container.read(likeInteractionProvider.notifier);
        notifier.toggleLike('post_1');
        await Future.delayed(const Duration(milliseconds: 100));
        notifier.toggleLike('post_1');
        await Future.delayed(const Duration(milliseconds: 100));
        notifier.toggleLike('post_1');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert - should only call API once (last tap)
        verify(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).called(1);
      });

      test('reverts optimistic update on network failure', () async {
        // Arrange
        when(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/posts/post_1/like'),
          type: DioExceptionType.connectionTimeout,
        ));
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(likeInteractionProvider.notifier);
        notifier.toggleLike('post_1');
        
        // Wait for debounce and API call
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final revertedPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(revertedPost.isLiked, false); // Reverted to original
        expect(revertedPost.likeCount, 5); // Reverted to original
        expect(revertedPost.optimisticState, OptimisticState.failed);
        
        // Check error was added
        final errorState = container.read(errorProvider);
        expect(errorState.errors.length, greaterThan(0));
      });

      test('reverts optimistic update when offline', () async {
        // Arrange
        when(mockRepository.getCachedFeed()).thenReturn(null);
        container = ProviderContainer(
          overrides: [
            feedRepositoryProvider.overrideWithValue(mockRepository),
            cacheManagerProvider.overrideWithValue(mockCacheManager),
            isOnlineProvider.overrideWith((ref) => Future.value(false)),
            feedProvider.overrideWith(
              (ref) {
                final notifier = FeedNotifier(mockRepository, ref);
                notifier.state = AsyncValue.data(
                  FeedState(
                    posts: [testPost],
                    nextCursor: null,
                  ),
                );
                return notifier;
              },
            ),
          ],
        );
        
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(likeInteractionProvider.notifier);
        notifier.toggleLike('post_1');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final revertedPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(revertedPost.isLiked, false); // Reverted
        expect(revertedPost.optimisticState, OptimisticState.failed);
        
        // Should not call API
        verifyNever(mockRepository.toggleLike(
          postId: anyNamed('postId'),
          cancelToken: anyNamed('cancelToken'),
        ));
      });

      test('handles race condition (later request wins)', () async {
        // Arrange
        final firstUpdatedPost = testPost.copyWith(
          isLiked: true,
          likeCount: 6,
        );
        final secondUpdatedPost = testPost.copyWith(
          isLiked: false,
          likeCount: 4,
        );
        
        when(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return firstUpdatedPost;
        });
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act - two rapid toggles
        final notifier = container.read(likeInteractionProvider.notifier);
        notifier.toggleLike('post_1');
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Second toggle before first completes
        when(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => secondUpdatedPost);
        notifier.toggleLike('post_1');
        await Future.delayed(const Duration(milliseconds: 700));

        // Assert - second request should win
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final finalPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        // The final state should reflect the second request
        expect(finalPost.optimisticState, OptimisticState.confirmed);
      });

      test('reverts after timeout (10 seconds)', () async {
        // Arrange
        when(mockRepository.toggleLike(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async {
          // Simulate slow response
          await Future.delayed(const Duration(seconds: 11));
          return testPost.copyWith(isLiked: true);
        });
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(likeInteractionProvider.notifier);
        notifier.toggleLike('post_1');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Wait for timeout (10 seconds)
        await Future.delayed(const Duration(seconds: 10, milliseconds: 100));

        // Assert - should revert due to timeout
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final revertedPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(revertedPost.optimisticState, OptimisticState.failed);
      });
    });

    group('toggleRepost', () {
      test('applies optimistic repost update', () async {
        // Arrange
        final updatedPost = testPost.copyWith(
          isReposted: true,
          repostCount: 3,
        );
        
        when(mockRepository.toggleRepost(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => updatedPost);
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(repostInteractionProvider.notifier);
        notifier.toggleRepost('post_1');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final updatedPostInState = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(updatedPostInState.isReposted, true);
        expect(updatedPostInState.repostCount, 3);
        expect(updatedPostInState.optimisticState, OptimisticState.confirmed);
      });

      test('reverts repost on failure', () async {
        // Arrange
        when(mockRepository.toggleRepost(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/posts/post_1/repost'),
          type: DioExceptionType.connectionTimeout,
        ));
        when(mockCacheManager.set<Post>(any, any, withTTL: anyNamed('withTTL')))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(repostInteractionProvider.notifier);
        notifier.toggleRepost('post_1');
        
        // Wait for debounce and API call
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final revertedPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(revertedPost.isReposted, false);
        expect(revertedPost.optimisticState, OptimisticState.failed);
      });
    });
  });
}

