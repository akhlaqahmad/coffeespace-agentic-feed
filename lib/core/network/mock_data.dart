import 'dart:math';
import '../../features/feed/data/models/post.dart';
import '../../features/feed/data/models/reply.dart';
import '../../features/feed/data/models/author.dart';

/// Generates and manages mock data for the API client
class MockDataGenerator {
  final Random _random = Random();
  final Map<String, Post> _posts = {};
  final Map<String, List<Reply>> _replies = {};
  final List<Author> _authors = [];
  final List<String> _postIds = [];

  MockDataGenerator() {
    _initializeAuthors();
    _initializePosts();
  }

  void _initializeAuthors() {
    _authors.addAll([
      const Author(
        id: 'author_1',
        username: 'coffee_lover',
        displayName: 'Coffee Lover',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      const Author(
        id: 'author_2',
        username: 'barista_pro',
        displayName: 'Barista Pro',
        avatarUrl: 'https://i.pravatar.cc/150?img=2',
      ),
      const Author(
        id: 'author_3',
        username: 'espresso_master',
        displayName: 'Espresso Master',
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
      ),
      const Author(
        id: 'author_4',
        username: 'latte_artist',
        displayName: 'Latte Artist',
        avatarUrl: 'https://i.pravatar.cc/150?img=4',
      ),
      const Author(
        id: 'author_5',
        username: 'cold_brew_fan',
        displayName: 'Cold Brew Fan',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
      ),
      const Author(
        id: 'author_6',
        username: 'cappuccino_crazy',
        displayName: 'Cappuccino Crazy',
        avatarUrl: 'https://i.pravatar.cc/150?img=6',
      ),
      const Author(
        id: 'author_7',
        username: 'mocha_maven',
        displayName: 'Mocha Maven',
        avatarUrl: 'https://i.pravatar.cc/150?img=7',
      ),
      const Author(
        id: 'author_8',
        username: 'americano_addict',
        displayName: 'Americano Addict',
        avatarUrl: 'https://i.pravatar.cc/150?img=8',
      ),
    ]);
  }

  void _initializePosts() {
    final now = DateTime.now();
    final postContents = [
      'Just discovered the most amazing single-origin Ethiopian coffee! The fruity notes are incredible. ☕',
      'Morning ritual: Fresh ground beans, French press, and 5 minutes of peace. Nothing beats it.',
      'Tried a new cold brew recipe today. 24-hour steep with cinnamon sticks. Game changer!',
      'Coffee shop etiquette: If you\'re going to work remotely, buy more than one drink. Support local businesses!',
      'The difference between a good espresso and a great one? It\'s all in the grind consistency.',
      'Found a hidden gem coffee roaster in the city. Their dark roast is perfection.',
      'Anyone else notice how coffee tastes better when someone else makes it?',
      'Pro tip: Store your beans in an airtight container away from light. Freshness matters!',
      'Just learned about coffee cupping. It\'s like wine tasting but for coffee. Mind blown.',
      'My favorite coffee pairing: Dark roast with dark chocolate. The bitterness complements perfectly.',
      'Coffee and productivity: There\'s a sweet spot. Too much and you\'re jittery, too little and you\'re sluggish.',
      'Tried making latte art today. Let\'s just say my "heart" looked more like a blob. Practice makes perfect!',
      'The best part of waking up? That first sip of perfectly brewed coffee.',
      'Coffee culture is fascinating. Every country has its own traditions and methods.',
      'Just got a new grinder. The difference in flavor is night and day compared to pre-ground.',
      'Cold brew vs iced coffee: They\'re not the same! Cold brew is smoother, less acidic.',
      'Coffee and books: The perfect combination for a rainy Sunday afternoon.',
      'Anyone have recommendations for decaf that actually tastes good? Asking for a friend.',
      'The science behind coffee extraction is wild. Temperature, time, grind size - it all matters.',
      'Coffee shop vibes: The ambient noise, the smell, the cozy atmosphere. Nothing compares.',
      'Just tried Turkish coffee for the first time. The texture is unique and the flavor is intense!',
      'Coffee and coding: Name a more iconic duo. I\'ll wait.',
      'The ritual of making coffee is almost as enjoyable as drinking it. Almost.',
      'Found a coffee subscription service that sends beans from different roasters monthly. Highly recommend!',
      'Coffee and conversation: Some of the best talks happen over a cup of coffee.',
      'The perfect espresso shot: 25-30 seconds, golden crema, balanced flavor. It\'s an art form.',
      'Coffee and creativity: There\'s something about caffeine that unlocks new ideas.',
      'Tried a coffee flight at a local roaster. Tasting different origins side by side is eye-opening.',
      'Coffee and community: Local coffee shops bring people together in the best way.',
      'The history of coffee is fascinating. From Ethiopia to the world, it\'s been quite a journey.',
      'Coffee and mindfulness: Taking time to savor each sip is a form of meditation.',
      'Just learned about coffee processing methods. Washed vs natural vs honey - each has unique flavors.',
      'Coffee and travel: Trying local coffee is one of my favorite ways to experience a new place.',
      'The perfect cup is subjective. What matters is that you enjoy it.',
      'Coffee and morning routines: It\'s the anchor that starts my day right.',
      'Tried a new brewing method today: AeroPress. Quick, clean, and delicious!',
      'Coffee and weather: Hot coffee on cold days, iced coffee on hot days. Perfect balance.',
      'The coffee community is so welcoming. Always happy to share tips and recommendations.',
      'Coffee and music: The perfect soundtrack makes the coffee experience even better.',
      'Just discovered the world of specialty coffee. There\'s so much to learn and explore!',
      'Coffee and work: That afternoon cup that gets you through the rest of the day.',
      'The art of coffee roasting: Light, medium, dark - each brings out different flavors.',
      'Coffee and friendship: Some of my best memories involve coffee and good company.',
      'Tried making coffee at different temperatures. The flavor profile changes dramatically!',
      'Coffee and reading: A good book and a great cup of coffee. Pure bliss.',
      'The sustainability of coffee: Supporting fair trade and environmentally conscious roasters matters.',
      'Coffee and inspiration: Many great ideas have been born over a cup of coffee.',
      'Just tried a coffee cocktail. Espresso martini - who knew coffee could be so versatile?',
      'Coffee and reflection: Sometimes the best thinking happens with a warm cup in hand.',
      'The future of coffee: Sustainable farming, innovative brewing methods, and growing appreciation.',
      'Coffee and gratitude: Taking a moment to appreciate the simple pleasure of a good cup.',
    ];

    for (int i = 0; i < postContents.length; i++) {
      final postId = 'post_${i + 1}';
      final author = _authors[i % _authors.length];
      final createdAt = now.subtract(Duration(hours: i * 2));
      
      final likeCount = _random.nextInt(150);
      final repostCount = _random.nextInt(50);
      final replyCount = _random.nextInt(30);
      final isLiked = _random.nextBool();
      final isReposted = _random.nextBool();

      _posts[postId] = Post(
        id: postId,
        author: author,
        content: postContents[i],
        createdAt: createdAt,
        likeCount: likeCount,
        repostCount: repostCount,
        replyCount: replyCount,
        isLiked: isLiked,
        isReposted: isReposted,
      );
      _postIds.add(postId);
      _replies[postId] = [];
    }
  }

  List<Post> getFeedPosts({String? cursor, int limit = 20}) {
    final startIndex = cursor != null
        ? _postIds.indexWhere((id) => id == cursor)
        : 0;
    
    if (startIndex == -1) {
      return [];
    }

    final endIndex = (startIndex + limit).clamp(0, _postIds.length);
    final ids = _postIds.sublist(startIndex, endIndex);
    
    return ids.map((id) => _posts[id]!).toList();
  }

  Post? getPostById(String postId) {
    return _posts[postId];
  }

  Reply createReply({
    required String postId,
    required String content,
  }) {
    final post = _posts[postId];
    if (post == null) {
      throw Exception('Post not found: $postId');
    }

    final author = _authors[_random.nextInt(_authors.length)];
    final replyId = 'reply_${DateTime.now().millisecondsSinceEpoch}';
    
    final reply = Reply(
      id: replyId,
      postId: postId,
      author: author,
      content: content,
      createdAt: DateTime.now(),
    );

    _replies[postId] ??= [];
    _replies[postId]!.add(reply);
    
    return reply;
  }

  List<Reply> getRepliesByPostId(String postId) {
    return _replies[postId] ?? [];
  }

  void updatePostReplyCount(String postId, int delta) {
    final post = _posts[postId];
    if (post != null) {
      _posts[postId] = post.copyWith(
        replyCount: post.replyCount + delta,
      );
    }
  }
}

