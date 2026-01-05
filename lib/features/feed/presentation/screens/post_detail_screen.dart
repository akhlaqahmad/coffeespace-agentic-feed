import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/replies_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/reply_item.dart';

/// Post detail screen with replies
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  int _previousReplyCount = 0;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(repliesProvider(widget.postId).notifier).loadReplies();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      await ref.read(repliesProvider(widget.postId).notifier).addReply(
            content,
            currentUser,
          );

      // Clear text field only after confirmed
      _replyController.clear();
      _focusNode.unfocus();

      // Scroll to bottom to show new reply
      _scrollToBottom();
    } catch (e) {
      // Error is handled by optimistic state in provider
      // Don't clear text field on error
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider).valueOrNull;
    final post = feedState?.posts.firstWhere(
      (p) => p.id == widget.postId,
      orElse: () => throw Exception('Post not found: ${widget.postId}'),
    );

    final repliesState = ref.watch(repliesProvider(widget.postId));

    // Watch for new replies and scroll to bottom
    final currentReplyCount = repliesState.replies.length;
    if (currentReplyCount > _previousReplyCount) {
      _previousReplyCount = currentReplyCount;
      _scrollToBottom();
    }

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
      body: Column(
        children: [
          // Full post at top
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Post content
                  SliverToBoxAdapter(
                    child: PostCard(post: post),
                  ),
                  // Replies header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Replies',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  // Replies list
                  if (repliesState.isLoading && repliesState.replies.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (repliesState.replies.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No replies yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reply = repliesState.replies[index];
                          return ReplyItem(
                            reply: reply,
                            postId: widget.postId,
                          );
                        },
                        childCount: repliesState.replies.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Reply input at bottom
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Write a reply...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitReply(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Submit button
                    if (_isSubmitting)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: _submitReply,
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

