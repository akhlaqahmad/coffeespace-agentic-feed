import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/optimistic_state.dart';
import '../providers/feed_provider.dart';
import '../providers/post_interactions_provider.dart';
import '../screens/post_detail_screen.dart';

/// Provider that provides optimistic state for a specific post
/// This allows selective watching of only the interaction state, not the entire post
final postInteractionStateProvider = Provider.family<OptimisticState?, String>(
  (ref, postId) {
    final feedState = ref.watch(feedProvider).valueOrNull;
    if (feedState == null) return null;
    
    final post = feedState.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found: $postId'),
    );
    
    return post.optimisticState;
  },
);

/// Interaction buttons widget that watches only interaction state for optimal performance
class InteractionButtons extends ConsumerWidget {
  final String postId;

  const InteractionButtons({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only the interaction state for this specific post
    final optimisticState = ref.watch(postInteractionStateProvider(postId));
    
    // Read the current post from feed provider (don't watch to avoid rebuilds)
    final feedState = ref.read(feedProvider).valueOrNull;
    if (feedState == null) {
      return const SizedBox.shrink();
    }

    final post = feedState.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found: $postId'),
    );

    final isPending = optimisticState == OptimisticState.pending;
    final isFailed = optimisticState == OptimisticState.failed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Reply button
        _InteractionButton(
          icon: Icons.chat_bubble_outline,
          count: post.replyCount,
          onPressed: isPending
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  // Navigate to post detail for replies
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
          showFailedState: false, // Replies don't have optimistic state in this widget
        ),
        // Repost button
        _InteractionButton(
          icon: post.isReposted ? Icons.repeat : Icons.repeat_outlined,
          count: post.repostCount,
          isActive: post.isReposted,
          onPressed: isPending
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  ref.read(repostInteractionProvider.notifier).toggleRepost(postId);
                },
          showFailedState: isFailed,
          optimisticState: optimisticState,
        ),
        // Like button
        _InteractionButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          count: post.likeCount,
          isActive: post.isLiked,
          onPressed: isPending
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  ref.read(likeInteractionProvider.notifier).toggleLike(postId);
                },
          showFailedState: isFailed,
          optimisticState: optimisticState,
        ),
      ],
    );
  }
}

/// Individual interaction button with optimistic state visualization
class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback? onPressed;
  final bool showFailedState;
  final OptimisticState? optimisticState;

  const _InteractionButton({
    required this.icon,
    required this.count,
    this.isActive = false,
    this.onPressed,
    this.showFailedState = false,
    this.optimisticState,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = optimisticState == OptimisticState.pending;
    
    Widget button = IconButton(
      icon: Icon(icon),
      color: isActive ? Colors.red : Colors.grey.shade700,
      onPressed: onPressed,
      iconSize: 20,
    );

    // Apply optimistic state styling
    if (isPending) {
      // Pending: slight opacity (0.7)
      button = Opacity(
        opacity: 0.7,
        child: button,
      );
    } else if (showFailedState) {
      // Failed: red outline with retry icon
      button = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            button,
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

