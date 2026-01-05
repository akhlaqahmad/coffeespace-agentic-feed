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
    _initializeReplies();
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
      // replyCount will be set after initializing replies
      final isLiked = _random.nextBool();
      final isReposted = _random.nextBool();

      _posts[postId] = Post(
        id: postId,
        author: author,
        content: postContents[i],
        createdAt: createdAt,
        likeCount: likeCount,
        repostCount: repostCount,
        replyCount: 0, // Will be updated after replies are initialized
        isLiked: isLiked,
        isReposted: isReposted,
      );
      _postIds.add(postId);
      _replies[postId] = [];
    }
  }

  void _initializeReplies() {
    final now = DateTime.now();
    
    // Map of post-specific comments (index-based, where index 0 = post_1)
    final postSpecificComments = {
      0: [ // Ethiopian coffee post
        'Which region? I love Yirgacheffe!',
        'The blueberry notes in Ethiopian coffee are amazing!',
        'Have you tried it as a pour-over?',
      ],
      1: [ // Morning ritual post
        'Same! It\'s my favorite part of the day.',
        'French press is underrated. So smooth!',
        '5 minutes of peace is exactly what I need too.',
      ],
      2: [ // Cold brew recipe
        'Cinnamon sticks? That sounds interesting!',
        'I do 18 hours, but might try 24 now.',
        'What ratio of coffee to water do you use?',
      ],
      3: [ // Coffee shop etiquette
        'This! Support your local spots!',
        'Couldn\'t agree more. They work hard.',
        'I always buy at least two drinks when working.',
      ],
      4: [ // Espresso grind consistency
        'Burr grinder makes all the difference!',
        'I learned this the hard way. Consistency is key!',
        'What grinder do you use?',
      ],
      5: [ // Hidden gem roaster
        'Where is this? I need to check it out!',
        'Dark roast done right is perfection indeed.',
        'Local roasters always have the best stuff.',
      ],
      6: [ // Coffee tastes better when someone else makes it
        'So true! Especially in the morning.',
        'There\'s something magical about it.',
        'My partner makes the best coffee. No idea why!',
      ],
      7: [ // Storage tip
        'I use mason jars with one-way valves.',
        'This tip saved my beans!',
        'Also keep them away from heat sources.',
      ],
      8: [ // Coffee cupping
        'It\'s a whole new world!',
        'I did a cupping session last month. Mind-blowing!',
        'The tasting notes you can pick up are incredible.',
      ],
      9: [ // Coffee and chocolate pairing
        'Dark chocolate and espresso = perfection',
        'Try it with sea salt dark chocolate!',
        'This is my go-to dessert pairing.',
      ],
      10: [ // Coffee and productivity
        'The sweet spot is real. Too much = anxiety.',
        'I limit myself to 2 cups before noon.',
        'Balance is everything!',
      ],
      11: [ // Latte art
        'Keep practicing! It took me months.',
        'My hearts look like blobs too 😅',
        'YouTube tutorials helped me a lot!',
      ],
      12: [ // Best part of waking up
        'That first sip hits different!',
        'Nothing compares to it.',
        'It\'s the ritual that makes it special.',
      ],
      13: [ // Coffee culture
        'Italian espresso culture is fascinating!',
        'Have you tried Turkish coffee?',
        'Every country has its own way. Love it!',
      ],
      14: [ // New grinder
        'Which one did you get?',
        'The difference is night and day!',
        'Fresh ground is always better.',
      ],
      15: [ // Cold brew vs iced coffee
        'So many people don\'t know the difference!',
        'Cold brew is my summer go-to.',
        'Less acidic = easier on the stomach.',
      ],
      16: [ // Coffee and books
        'Perfect combination!',
        'Rainy Sunday + coffee + book = heaven',
        'What are you reading?',
      ],
      17: [ // Decaf recommendations
        'Swiss Water Process decaf is pretty good!',
        'I\'ve found some decent ones from specialty roasters.',
        'It\'s hard to find good decaf, but they exist!',
      ],
      18: [ // Coffee extraction science
        'Temperature is so crucial!',
        'The science is fascinating. So many variables!',
        'I love geeking out about extraction.',
      ],
      19: [ // Coffee shop vibes
        'The smell alone is therapeutic!',
        'Ambient noise is perfect for focus.',
        'Nothing beats that cozy atmosphere.',
      ],
      20: [ // Turkish coffee
        'The texture is unique!',
        'Have you tried it with cardamom?',
        'Turkish coffee is an experience!',
      ],
      21: [ // Coffee and coding
        'Name a better duo. I\'ll wait.',
        'Coffee + code = productivity',
        'The perfect pairing!',
      ],
      22: [ // Ritual of making coffee
        'The process is meditative!',
        'I love the ritual almost as much as drinking it.',
        'It\'s the little things that matter.',
      ],
      23: [ // Coffee subscription
        'Which service? I\'m looking for one!',
        'I love discovering new roasters this way.',
        'Subscriptions are great for variety.',
      ],
      24: [ // Coffee and conversation
        'Some of my best talks happen over coffee.',
        'Coffee brings people together.',
        'It\'s the perfect conversation starter.',
      ],
      25: [ // Perfect espresso shot
        '25-30 seconds is the sweet spot!',
        'The crema tells you everything.',
        'It really is an art form.',
      ],
      26: [ // Coffee and creativity
        'Caffeine unlocks something in the brain!',
        'My best ideas come after coffee.',
        'There\'s definitely a connection.',
      ],
      27: [ // Coffee flight
        'Tasting flights are amazing!',
        'Side-by-side comparison is eye-opening.',
        'I did one last week. So educational!',
      ],
      28: [ // Coffee and community
        'Local shops are community hubs!',
        'They bring neighborhoods together.',
        'Support local!',
      ],
      29: [ // History of coffee
        'The journey from Ethiopia is fascinating!',
        'Coffee has such a rich history.',
        'It\'s amazing how it spread worldwide.',
      ],
      30: [ // Coffee and mindfulness
        'Savoring each sip is meditation.',
        'Mindful coffee drinking is a practice.',
        'It\'s about being present.',
      ],
      31: [ // Coffee processing methods
        'Natural process has such fruity notes!',
        'Honey process is my favorite.',
        'Each method brings out different flavors.',
      ],
      32: [ // Coffee and travel
        'Trying local coffee is the best!',
        'It\'s how I experience new places.',
        'Coffee tells you about a culture.',
      ],
      33: [ // Perfect cup is subjective
        'Exactly! Enjoy what you enjoy.',
        'There\'s no right or wrong way.',
        'Personal preference matters most.',
      ],
      34: [ // Coffee and morning routines
        'It\'s my anchor too!',
        'Morning coffee sets the tone.',
        'Can\'t start the day without it.',
      ],
      35: [ // AeroPress
        'AeroPress is so versatile!',
        'Quick and clean. Love it!',
        'Which recipe do you use?',
      ],
      36: [ // Coffee and weather
        'Perfect balance indeed!',
        'Hot coffee on cold days hits different.',
        'Iced coffee in summer is essential.',
      ],
      37: [ // Coffee community
        'The community is so welcoming!',
        'Always happy to share and learn.',
        'Best part of being a coffee lover.',
      ],
      38: [ // Coffee and music
        'The right soundtrack elevates it!',
        'Jazz and coffee = perfection',
        'Music makes the experience complete.',
      ],
      39: [ // Specialty coffee
        'There\'s so much to explore!',
        'Welcome to the rabbit hole!',
        'Specialty coffee is a journey.',
      ],
      40: [ // Coffee and work
        'That afternoon cup is essential!',
        'Gets me through the rest of the day.',
        '3 PM coffee is a lifesaver.',
      ],
      41: [ // Coffee roasting
        'Light roast for fruity, dark for bold!',
        'Each roast level has its place.',
        'Roasting is an art!',
      ],
      42: [ // Coffee and friendship
        'Best memories involve coffee!',
        'Coffee and friends = perfect combo.',
        'Some of my best conversations over coffee.',
      ],
      43: [ // Coffee temperature
        'Temperature makes a huge difference!',
        'I experiment with different temps too.',
        'What temperature do you prefer?',
      ],
      44: [ // Coffee and reading
        'Pure bliss indeed!',
        'Perfect way to spend an afternoon.',
        'Coffee + book = happiness',
      ],
      45: [ // Coffee sustainability
        'Fair trade matters so much!',
        'Supporting ethical roasters is important.',
        'Sustainability is crucial for the future.',
      ],
      46: [ // Coffee and inspiration
        'Many great ideas over coffee!',
        'Coffee fuels creativity.',
        'It\'s where inspiration strikes.',
      ],
      47: [ // Coffee cocktail
        'Espresso martini is amazing!',
        'Coffee cocktails are underrated.',
        'Who knew coffee could be so versatile?',
      ],
      48: [ // Coffee and reflection
        'Best thinking happens with coffee.',
        'It\'s meditative.',
        'Coffee and contemplation go together.',
      ],
      49: [ // Future of coffee
        'Excited for the future!',
        'Sustainable farming is key.',
        'Innovation in coffee is exciting.',
      ],
      50: [ // Coffee and gratitude
        'Gratitude for the simple pleasures!',
        'Taking time to appreciate it matters.',
        'Coffee is a gift.',
      ],
    };

    // Generic comments that can be used for any post
    final genericComments = [
      'Great post! ☕',
      'Love this!',
      'Totally agree!',
      'Thanks for sharing!',
      'This is so true!',
      'I needed to hear this today.',
      'Same here!',
      'Couldn\'t agree more!',
      'This resonates with me.',
      'Well said!',
      'Preach!',
      'Facts!',
      'This is the way.',
      '100% this!',
      'So relatable!',
    ];

    // Initialize replies for each post
    for (int i = 0; i < _postIds.length; i++) {
      final postId = _postIds[i];
      final post = _posts[postId]!;
      final postCreatedAt = post.createdAt;
      
      // Determine how many comments this post should have (0-8 comments)
      final numComments = _random.nextInt(9);
      
      // Get post-specific comments if available
      final specificComments = postSpecificComments[i] ?? [];
      
      // Create comments
      final replies = <Reply>[];
      for (int j = 0; j < numComments; j++) {
        // Mix of specific and generic comments
        String commentContent;
        if (j < specificComments.length) {
          commentContent = specificComments[j];
        } else {
          commentContent = genericComments[_random.nextInt(genericComments.length)];
        }
        
        // Random author (different from post author)
        Author commentAuthor;
        do {
          commentAuthor = _authors[_random.nextInt(_authors.length)];
        } while (commentAuthor.id == post.author.id);
        
        // Comment time: between post creation and now, with some randomness
        final hoursSincePost = now.difference(postCreatedAt).inHours;
        final clampedHours = hoursSincePost.clamp(0, 48);
        // Ensure we have at least 1 hour to avoid nextInt(0) error
        final commentHoursAgo = clampedHours > 0 
            ? _random.nextInt(clampedHours) 
            : 0;
        final commentCreatedAt = now.subtract(Duration(hours: commentHoursAgo));
        
        final reply = Reply(
          id: 'reply_${postId}_${j + 1}',
          postId: postId,
          author: commentAuthor,
          content: commentContent,
          createdAt: commentCreatedAt,
        );
        
        replies.add(reply);
      }
      
      // Sort replies by creation time (oldest first)
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Store replies
      _replies[postId] = replies;
      
      // Update post reply count to match actual number of replies
      _posts[postId] = post.copyWith(replyCount: replies.length);
    }
  }

  List<Post> getFeedPosts({String? cursor, int limit = 20}) {
    int startIndex = 0;
    
    if (cursor != null) {
      // Find the index of the cursor post ID
      final cursorIndex = _postIds.indexWhere((id) => id == cursor);
      if (cursorIndex == -1) {
        // Cursor not found, return empty list
        return [];
      }
      // Start from the next post after the cursor
      startIndex = cursorIndex + 1;
    }
    
    // If we've reached the end, return empty list
    if (startIndex >= _postIds.length) {
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

