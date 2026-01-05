import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../../../../core/utils/connectivity_monitor.dart';

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

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final onlineStatusAsync = ref.watch(onlineStatusProvider);
    final isOnline = onlineStatusAsync.valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          // Offline indicator
          if (!isOnline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: feedAsync.when(
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
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              cacheExtent: 1000, // Preload off-screen items
              itemCount: feedState.posts.length + (feedState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index == feedState.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final post = feedState.posts[index];
                return PostCard(
                  key: ValueKey(post.id), // Prevents unnecessary rebuilds
                  post: post,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for compose action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compose feature coming soon')),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}

