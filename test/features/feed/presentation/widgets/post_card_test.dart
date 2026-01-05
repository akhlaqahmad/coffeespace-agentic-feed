import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/author.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/optimistic_state.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/providers/feed_provider.dart';
import 'package:coffeespace_agentic_feed/features/feed/presentation/widgets/post_card.dart';

void main() {
  final testAuthor = const Author(
    id: 'test_author',
    username: 'test_user',
    displayName: 'Test User',
  );

  final basePost = Post(
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

  Widget createTestWidget(Post post, FeedState feedState) {
    return ProviderScope(
      overrides: [
        feedProvider.overrideWith(
          (ref) {
            final notifier = FeedNotifier(
              MockFeedRepository(),
              ref,
            );
            notifier.state = AsyncValue.data(feedState);
            return notifier;
          },
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PostCard(post: post),
        ),
      ),
    );
  }

  group('PostCard Widget Tests', () {
    testWidgets('renders post content correctly', (WidgetTester tester) async {
      // Arrange
      final post = basePost;
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test post content'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@test_user'), findsOneWidget);
    });

    testWidgets('renders interaction buttons', (WidgetTester tester) async {
      // Arrange
      final post = basePost;
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.repeat_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('shows like count', (WidgetTester tester) async {
      // Arrange
      final post = basePost.copyWith(likeCount: 10);
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows active like state when post is liked', (WidgetTester tester) async {
      // Arrange
      final post = basePost.copyWith(isLiked: true);
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('shows active repost state when post is reposted', (WidgetTester tester) async {
      // Arrange
      final post = basePost.copyWith(isReposted: true);
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.repeat), findsOneWidget);
      expect(find.byIcon(Icons.repeat_outlined), findsNothing);
    });

    testWidgets('shows pending optimistic state', (WidgetTester tester) async {
      // Arrange
      final post = basePost.copyWith(
        optimisticState: OptimisticState.pending,
        isLiked: true,
      );
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      // Pending state applies opacity - we can check that the widget exists
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows failed optimistic state', (WidgetTester tester) async {
      // Arrange
      final post = basePost.copyWith(
        optimisticState: OptimisticState.failed,
        isLiked: true,
      );
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      // Failed state shows error indicator - check for error icon
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('displays post with correct interaction counts', (WidgetTester tester) async {
      // Arrange
      final post = basePost.copyWith(
        likeCount: 10,
        repostCount: 5,
        replyCount: 3,
      );
      final feedState = FeedState(
        posts: [post],
        nextCursor: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(post, feedState));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}

// Simple mock repository for testing
class MockFeedRepository extends FeedRepository {
  MockFeedRepository()
      : super(
          apiClient: MockApiClient(),
          cacheManager: MockCacheManager(),
        );
}

class MockApiClient extends ApiClient {
  MockApiClient() : super();
}

class MockCacheManager extends CacheManager {
  MockCacheManager() : super();
}
