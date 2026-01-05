import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reply.dart';
import '../../data/models/optimistic_state.dart';
import '../providers/replies_provider.dart';

/// Reply item widget with optimistic state handling
class ReplyItem extends ConsumerWidget {
  final Reply reply;
  final String postId;

  const ReplyItem({
    super.key,
    required this.reply,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = reply.optimisticState == OptimisticState.pending;
    final isFailed = reply.optimisticState == OptimisticState.failed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isPending
          ? Colors.grey.shade50
          : isFailed
              ? Colors.red.shade50
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info with avatar
            Row(
              children: [
                // Avatar
                ClipOval(
                  child: reply.author.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: reply.author.avatarUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 20),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 20),
                          ),
                          memCacheWidth: 80,
                          memCacheHeight: 80,
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 20),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.displayName ?? reply.author.username,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '@${reply.author.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(reply.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Reply content
            Text(
              reply.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // Optimistic state indicators
            if (isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sending...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                ],
              ),
            ],
            if (isFailed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to send',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _retryReply(context, ref),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _retryReply(BuildContext context, WidgetRef ref) {
    // Retry the failed reply
    ref.read(repliesProvider(postId).notifier).retryReply(reply.id);
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

