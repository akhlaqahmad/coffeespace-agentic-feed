import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coffeespace_agentic_feed/core/cache/cache_manager.dart';
import 'package:coffeespace_agentic_feed/core/network/api_client.dart';
import 'package:coffeespace_agentic_feed/core/utils/connectivity_monitor.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/author.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/reply.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/optimistic_state.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/repositories/feed_repository.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/providers/feed_provider.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/providers/replies_provider.dart';
import 'package:coffeespace_agentic_feed/shared/providers/error_provider.dart';

import 'replies_provider_test.mocks.dart';

@GenerateMocks([
  FeedRepository,
  CacheManager,
  ApiClient,
])
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
    replyCount: 0,
    isLiked: false,
    isReposted: false,
  );

  final testReply = Reply(
    id: 'reply_1',
    postId: 'post_1',
    author: testAuthor,
    content: 'Test reply content',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockFeedRepository();
    when(mockRepository.getCachedFeed()).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepository),
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
        currentUserProvider.overrideWithValue(testAuthor),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RepliesNotifier', () {
    group('loadReplies', () {
      test('loads replies successfully', () async {
        // Arrange
        when(mockRepository.getReplies(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => [testReply]);

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.loadReplies();

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.length, 1);
        expect(state.replies[0].id, 'reply_1');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('handles network error when loading replies', () async {
        // Arrange
        when(mockRepository.getReplies(
          postId: 'post_1',
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/posts/post_1/replies'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.loadReplies();

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.isEmpty, true);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
        
        // Check error was added
        final errorState = container.read(errorProvider);
        expect(errorState.errors.length, greaterThan(0));
      });

      test('shows error when offline', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            feedRepositoryProvider.overrideWithValue(mockRepository),
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
            currentUserProvider.overrideWithValue(testAuthor),
          ],
        );

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.loadReplies();

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.error, isNotNull);
        expect(state.error, contains('No internet connection'));
        
        // Should not call API
        verifyNever(mockRepository.getReplies(
          postId: anyNamed('postId'),
          cancelToken: anyNamed('cancelToken'),
        ));
      });
    });

    group('addReply', () {
      test('adds reply with optimistic update', () async {
        // Arrange
        final confirmedReply = testReply.copyWith(id: 'reply_confirmed');
        
        when(mockRepository.addReply(
          postId: 'post_1',
          content: 'New reply',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => confirmedReply);

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.addReply('New reply', testAuthor);

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.length, 1);
        expect(state.replies[0].content, 'New reply');
        expect(state.replies[0].optimisticState, OptimisticState.confirmed);
        
        // Check parent post replyCount was updated
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final updatedPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(updatedPost.replyCount, 1);
      });

      test('shows pending state immediately', () async {
        // Arrange
        final confirmedReply = testReply.copyWith(id: 'reply_confirmed');
        
        when(mockRepository.addReply(
          postId: 'post_1',
          content: 'New reply',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return confirmedReply;
        });

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        final future = notifier.addReply('New reply', testAuthor);
        
        // Check immediately (before API completes)
        final stateBefore = container.read(repliesProvider('post_1'));
        expect(stateBefore.replies.length, 1);
        expect(stateBefore.replies[0].optimisticState, OptimisticState.pending);
        
        // Wait for API to complete
        await future;
        
        // Check after API completes
        final stateAfter = container.read(repliesProvider('post_1'));
        expect(stateAfter.replies[0].optimisticState, OptimisticState.confirmed);
      });

      test('reverts reply on network failure', () async {
        // Arrange
        when(mockRepository.addReply(
          postId: 'post_1',
          content: 'New reply',
          cancelToken: anyNamed('cancelToken'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/posts/post_1/replies'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.addReply('New reply', testAuthor);

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.length, 1);
        expect(state.replies[0].optimisticState, OptimisticState.failed);
        
        // Check parent post replyCount was reverted
        final feedState = container.read(feedProvider).valueOrNull;
        expect(feedState, isNotNull);
        final updatedPost = feedState!.posts.firstWhere((p) => p.id == 'post_1');
        expect(updatedPost.replyCount, 0); // Reverted
      });

      test('reverts reply when offline', () async {
        // Arrange
        when(mockRepository.getCachedFeed()).thenReturn(null);
        container = ProviderContainer(
          overrides: [
            feedRepositoryProvider.overrideWithValue(mockRepository),
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
            currentUserProvider.overrideWithValue(testAuthor),
          ],
        );

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.addReply('New reply', testAuthor);

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.length, 1);
        expect(state.replies[0].optimisticState, OptimisticState.failed);
        
        // Should not call API
        verifyNever(mockRepository.addReply(
          postId: anyNamed('postId'),
          content: anyNamed('content'),
          cancelToken: anyNamed('cancelToken'),
        ));
      });

      test('reverts reply after timeout', () async {
        // Arrange
        when(mockRepository.addReply(
          postId: 'post_1',
          content: 'New reply',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async {
          // Simulate slow response
          await Future.delayed(const Duration(seconds: 11));
          return testReply;
        });

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.addReply('New reply', testAuthor);
        
        // Wait for timeout (10 seconds)
        await Future.delayed(const Duration(seconds: 10, milliseconds: 100));

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.length, 1);
        expect(state.replies[0].optimisticState, OptimisticState.failed);
      });

      test('prevents duplicate replies', () async {
        // Arrange
        final confirmedReply = testReply.copyWith(id: 'reply_confirmed');
        
        when(mockRepository.addReply(
          postId: 'post_1',
          content: 'New reply',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => confirmedReply);

        // Act
        final notifier = container.read(repliesProvider('post_1').notifier);
        await notifier.addReply('New reply', testAuthor);
        await notifier.addReply('New reply', testAuthor);

        // Assert - should only have one reply (deduplicated)
        final state = container.read(repliesProvider('post_1'));
        final confirmedReplies = state.replies.where(
          (r) => r.optimisticState == OptimisticState.confirmed,
        ).toList();
        expect(confirmedReplies.length, lessThanOrEqualTo(1));
      });
    });

    group('retryReply', () {
      test('retries failed reply', () async {
        // Arrange
        final failedReply = Reply(
          id: 'temp_reply_1',
          postId: 'post_1',
          author: testAuthor,
          content: 'Failed reply',
          createdAt: DateTime.now(),
          optimisticState: OptimisticState.failed,
        );
        
        final confirmedReply = testReply.copyWith(
          id: 'reply_confirmed',
          content: 'Failed reply',
        );
        
        // Set up initial state with failed reply
        final notifier = container.read(repliesProvider('post_1').notifier);
        notifier.state = RepliesState(replies: [failedReply]);
        
        when(mockRepository.addReply(
          postId: 'post_1',
          content: 'Failed reply',
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => confirmedReply);

        // Act
        await notifier.retryReply('temp_reply_1');

        // Assert
        final state = container.read(repliesProvider('post_1'));
        expect(state.replies.length, 1);
        expect(state.replies[0].optimisticState, OptimisticState.confirmed);
        expect(state.replies[0].content, 'Failed reply');
      });

      test('does not retry non-failed reply', () async {
        // Arrange
        final confirmedReply = testReply.copyWith(
          optimisticState: OptimisticState.confirmed,
        );
        
        final notifier = container.read(repliesProvider('post_1').notifier);
        notifier.state = RepliesState(replies: [confirmedReply]);

        // Act
        await notifier.retryReply('reply_1');

        // Assert - should not call addReply
        verifyNever(mockRepository.addReply(
          postId: anyNamed('postId'),
          content: anyNamed('content'),
          cancelToken: anyNamed('cancelToken'),
        ));
      });
    });
  });
}

