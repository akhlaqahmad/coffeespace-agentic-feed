import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/utils/connectivity_tracker.dart';
import 'features/feed/data/models/post.dart';
import 'features/feed/data/models/reply.dart';
import 'features/feed/data/models/author.dart';
import 'features/feed/data/models/optimistic_state.dart';
import 'features/feed/presentation/screens/feed_screen.dart';
import 'shared/widgets/error_banner_overlay.dart';
import 'shared/widgets/offline_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive type adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PostAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ReplyAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AuthorAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(OptimisticStateAdapter());
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize connectivity tracking (runs in background)
    // This ensures connectivity changes are tracked even if no widget watches it
    ref.read(connectivityTrackerProvider);
    
    return MaterialApp(
      title: 'CoffeeSpace Agentic Feed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const ErrorBannerOverlay(
        child: FeedScreen(),
      ),
    );
  }
}

