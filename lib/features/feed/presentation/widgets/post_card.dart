import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post.dart';
import '../../data/models/optimistic_state.dart';
import 'interaction_buttons.dart';
import '../screens/post_detail_screen.dart';

/// Post card widget with selective rebuilds for optimal performance
class PostCard extends ConsumerWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only the post from feed provider (not interaction state)
    // This ensures content doesn't rebuild unnecessarily
    final feedState = ref.watch(feedProvider).valueOrNull;
    final currentPost = feedState?.posts.firstWhere(
          (p) => p.id == post.id,
          orElse: () => post,
        ) ??
        post;

    return RepaintBoundary(
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: currentPost.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info with avatar
              Row(
                children: [
                  // Avatar with memory cache
                  ClipOval(
                    child: currentPost.author.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: currentPost.author.avatarUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.person),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.person),
                            ),
                            memCacheWidth: 96, // Optimize memory usage (2x display size)
                            memCacheHeight: 96, // Optimize memory usage (2x display size)
                            maxWidthDiskCache: 200, // Limit disk cache size
                            maxHeightDiskCache: 200, // Limit disk cache size
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPost.author.displayName ?? currentPost.author.username,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '@${currentPost.author.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(currentPost.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Post content
              Text(
                currentPost.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              // Interaction buttons with selective rebuilds
              InteractionButtons(postId: currentPost.id),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

