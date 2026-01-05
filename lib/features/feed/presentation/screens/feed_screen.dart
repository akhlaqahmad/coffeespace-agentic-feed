import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/debug/debug_menu.dart';
import '../../../../core/metrics/metrics_debug_screen.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../../../../shared/widgets/offline_indicator.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

/// Feed screen with optimized performance
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _paginationDebounceTimer;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _paginationDebounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Cancel existing debounce timer
    _paginationDebounceTimer?.cancel();

    // Check if we're at 80% of scroll
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final scrollPercentage = currentScroll / maxScroll;

    if (scrollPercentage >= 0.8 && !_isLoadingMore) {
      // Debounce pagination trigger by 300ms
      _paginationDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        final feedState = ref.read(feedProvider).valueOrNull;
        if (feedState != null && feedState.hasMore && !feedState.isLoadingMore) {
          setState(() {
            _isLoadingMore = true;
          });
          ref.read(feedProvider.notifier).loadMore().then((_) {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
          });
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(feedProvider.notifier).refresh();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);

    return GestureDetector(
      onLongPress: kDebugMode
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DebugMenuScreen(),
                ),
              );
            }
          : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Feed'),
          actions: kDebugMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.analytics),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MetricsDebugScreen(),
                        ),
                      );
                    },
                    tooltip: 'View Metrics',
                  ),
                ]
              : null,
        ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: feedAsync.when(
        data: (feedState) {
          if (feedState.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feed_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              cacheExtent: 1000, // Preload off-screen items
              itemCount: feedState.posts.length + 
                  (feedState.isLoadingMore ? 1 : 0) +
                  (feedState.isFromCache ? 1 : 0) +
                  (!feedState.hasMore && feedState.posts.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Show cache indicator at the top if showing cached content
                if (feedState.isFromCache && index == 0) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cached,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feedState.cacheTimestamp != null
                                ? 'Viewing cached content from ${_formatTimestamp(feedState.cacheTimestamp!)}'
                                : 'Viewing cached content',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Adjust index if cache indicator is shown
                final postIndex = feedState.isFromCache ? index - 1 : index;

                // Show end-of-feed indicator
                if (!feedState.hasMore && 
                    feedState.posts.isNotEmpty && 
                    postIndex == feedState.posts.length) {
                  return Container(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You're all caught up!",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No more posts to load',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show loading indicator at the bottom
                if (feedState.isLoadingMore && postIndex == feedState.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final post = feedState.posts[postIndex];
                return PostCard(
                  key: ValueKey(post.id), // Prevents unnecessary rebuilds
                  post: post,
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const FeedPostShimmer(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading feed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(feedProvider.notifier).loadInitial();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for compose action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compose feature coming soon')),
          );
        },
        child: const Icon(Icons.edit),
      ),
      ),
    );
  }
}

