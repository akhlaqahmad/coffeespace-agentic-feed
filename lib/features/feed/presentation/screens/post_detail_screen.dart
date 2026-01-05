import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

/// Placeholder screen for post detail view
class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider).valueOrNull;
    final post = feedState?.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found: $postId'),
    );

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(
          child: Text('Post not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: SingleChildScrollView(
        child: PostCard(post: post),
      ),
    );
  }
}

