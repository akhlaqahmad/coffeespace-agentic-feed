# Architecture Documentation

## Overview

CoffeeSpace Agentic Feed is a Flutter mobile application built with a clean architecture approach, emphasizing separation of concerns, testability, and maintainability. The app leverages Riverpod for state management, Hive for local storage, and an agentic system for intelligent feed curation.

## Architecture Principles

- **Clean Architecture**: Separation into distinct layers (Presentation, Domain, Data)
- **Feature-Based Organization**: Features are self-contained modules
- **Reactive State Management**: Using Riverpod for predictable state updates
- **Offline-First**: Optimistic updates with local caching
- **Type Safety**: Leveraging Dart's strong typing and Freezed for immutable models
- **Testability**: Architecture supports unit, widget, and integration tests

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── features/
│   └── feed/
│       ├── data/
│       │   ├── models/                # Data models (Post, Author, Reply)
│       │   └── repositories/          # Data repository implementations
│       │       └── feed_repository.dart # Feed repository with caching
│       ├── presentation/
│       │   └── providers/             # Riverpod providers
│       │       └── feed_provider.dart # Feed state management with pagination
│       ├── domain/
│       │   ├── entities/              # Domain entities
│       │   ├── repositories/          # Repository interfaces
│       │   └── usecases/              # Business logic use cases
│       ├── presentation/
│       │   ├── providers/             # Riverpod providers
│       │   ├── screens/               # Screen widgets
│       │   ├── widgets/               # Reusable UI components
│       │   └── agents/                # Agent implementations
│       └── core/                      # Feature-specific utilities
├── core/
│   ├── network/                       # Networking layer
│   │   ├── api_client.dart            # Mock API client
│   │   ├── request_manager.dart       # Request cancellation manager
│   │   ├── mock_data.dart             # Mock data generator
│   │   └── models/                    # Network models (FeedPage)
│   ├── cache/                         # Caching layer
│   │   ├── cache_manager.dart         # Generic cache manager wrapping Hive
│   │   ├── cache_strategy.dart        # Cache strategy patterns
│   │   └── cache_providers.dart       # Cache manager providers
│   ├── theme/                         # Design system & theming
│   ├── utils/                         # Shared utilities
│   │   ├── connectivity_monitor.dart  # Connectivity monitoring
│   │   └── app_lifecycle.dart         # App lifecycle state monitoring
│   ├── constants/                     # App-wide constants
│   └── error/                         # Error handling
└── shared/
    ├── widgets/                       # Shared UI components
    └── providers/                     # Shared providers
```

## Architecture Layers

### 1. Presentation Layer

**Responsibility**: UI rendering, user interactions, and visual state management

**Components**:
- **Screens**: Full-page UI components
- **Widgets**: Reusable UI components
- **Providers**: Riverpod providers that connect UI to business logic
- **Agents**: Agent implementations that interact with the UI layer

**Key Patterns**:
- Widget composition
- Provider-based state management
- Responsive design following `docs/design.json` specifications

**Example**:
```dart
// Feature screen using providers
class FeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    // Render UI based on state
  }
}
```

---

### 2. Domain Layer

**Responsibility**: Business logic, use cases, and domain entities

**Components**:
- **Entities**: Core business objects (Post, Author, Reply)
- **Repositories (Interfaces)**: Contracts for data operations
- **Use Cases**: Single-responsibility business logic operations

**Key Patterns**:
- Dependency inversion (interfaces, not implementations)
- Pure business logic (no framework dependencies)
- Use case pattern for business operations

**Example**:
```dart
// Use case
class GetFeedUseCase {
  final FeedRepository repository;
  
  GetFeedUseCase(this.repository);
  
  Future<Either<Failure, List<Post>>> execute() {
    return repository.getFeed();
  }
}
```

---

### 3. Data Layer

**Responsibility**: Data retrieval, caching, and transformation

**Components**:
- **Models**: Data transfer objects with JSON serialization
- **Repositories (Implementations)**: Concrete repository implementations
- **Data Sources**: 
  - Remote: API calls via Dio
  - Local: Hive database for caching
- **Mappers**: Transform between models and entities

**Key Patterns**:
- Repository pattern
- Data source abstraction
- Optimistic updates via OptimisticState
- Local-first data strategy

**Example**:
```dart
// Repository implementation
class FeedRepository {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  
  Future<FeedPage> getFeed({String? cursor, CancelToken? cancelToken}) async {
    // Uses staleWhileRevalidate: shows cache immediately, fetches fresh in background
    final cachedFeed = _cacheManager.get<Map<String, dynamic>>('feed');
    if (cachedFeed != null) {
      // Return cached data immediately
      // Fetch fresh data in background
    }
    // Fetch from network if no cache
  }
}
```

---

## State Management

### Riverpod Architecture

Riverpod is used throughout the app for state management:

**Provider Types**:
- **StateProvider**: Simple state values
- **FutureProvider**: Async operations
- **StreamProvider**: Real-time data streams
- **StateNotifierProvider**: Complex state with business logic
- **Provider**: Dependency injection

**State Flow**:
```
User Action → Provider Method → Repository → Data Source
                                          ↓
UI Update ← Provider Update ← State Change ← Response
```

**Feed Provider** (`lib/features/feed/presentation/providers/feed_provider.dart`):
- `FeedNotifier`: Manages feed state with pagination support
- `FeedState`: Contains posts list, nextCursor, loading states
- Methods:
  - `loadInitial()`: Loads first page, shows cached data immediately
  - `loadMore()`: Loads next page using cursor-based pagination
  - `refresh()`: Clears cache and fetches fresh data
  - `toggleLike()`: Optimistic like toggle with rollback on error
  - `toggleRepost()`: Optimistic repost toggle with rollback on error
- Request cancellation: Automatically cancels requests on dispose and when app backgrounds
- App lifecycle integration: Listens to `appLifecycleProvider` and cancels requests when backgrounded

### Optimistic Updates

The app uses `OptimisticState` enum to track optimistic updates:

```dart
enum OptimisticState {
  pending,    // Action sent, waiting for server response
  failed,     // Server rejected, needs rollback
  confirmed,  // Server confirmed, update is final
}
```

**Flow**:
1. User performs action (like, reply)
2. UI updates immediately with `optimisticState: pending`
3. Request sent to server
4. On success: `optimisticState: confirmed`
5. On failure: `optimisticState: failed`, UI rolls back

---

## Data Models

### Core Models

**Post Model**:
```dart
@freezed
class Post {
  String id;
  Author author;
  String content;
  DateTime createdAt;
  int likeCount;
  int repostCount;
  int replyCount;
  bool isLiked;
  bool isReposted;
  OptimisticState? optimisticState;
}
```

**Author Model**:
```dart
@freezed
class Author {
  String id;
  String username;
  String? displayName;
  String? avatarUrl;
}
```

**Reply Model**:
```dart
@freezed
class Reply {
  String id;
  String postId;
  Author author;
  String content;
  DateTime createdAt;
  OptimisticState? optimisticState;
}
```

All models use:
- Freezed for immutability and union types
- JSON Serializable for API communication
- Value equality for efficient state comparisons

---

## Networking

### API Client

**Mock API Client** (`lib/core/network/api_client.dart`):
- Simulated API using Dio for testing optimistic updates and offline scenarios
- Realistic behaviors:
  - 300-800ms random delay per request
  - 20% chance of network failure
  - Support for CancelToken from Dio
  - Returns mock data with generated IDs

**Dio Configuration**:
- Base URL configuration
- Interceptors for auth, logging, error handling
- Timeout settings (5 seconds connect/receive)
- Retry logic for failed requests

**API Endpoints**:
```
GET    /feed?cursor={cursor}&limit=20     # Get feed posts with pagination
POST   /posts/{id}/like                   # Toggle like, returns updated post
POST   /posts/{id}/repost                 # Toggle repost, returns updated post
POST   /posts/{id}/replies                # Create reply, returns new reply
GET    /posts/{id}/replies                # Get list of replies for a post
```

**Mock Data** (`lib/core/network/mock_data.dart`):
- Generates 50+ sample posts with varied coffee-related content
- Manages in-memory state for posts, replies, and authors
- Supports pagination via cursor-based navigation
- Tracks like/repost/reply counts and user interactions

**FeedPage Model** (`lib/core/network/models/feed_page.dart`):
- Paginated response structure with posts list and nextCursor
- Uses Freezed for immutability
- Custom JSON converters for List<Post> serialization

**Feed Repository** (`lib/features/feed/data/repositories/feed_repository.dart`):
- Implements feed data operations with caching
- Methods:
  - `getFeed(cursor, cancelToken)`: Fetches feed with staleWhileRevalidate strategy
  - `getCachedFeed()`: Returns cached feed without network request
  - `toggleLike(postId, cancelToken)`: Toggles like status via API
  - `toggleRepost(postId, cancelToken)`: Toggles repost status via API
  - `getReplies(postId, cancelToken)`: Fetches replies for a post
  - `addReply(postId, content, cancelToken)`: Creates a new reply
  - `clearCache()`: Clears all feed-related cache
- Cache Strategy: Uses staleWhileRevalidate - shows cached data immediately while fetching fresh data in background
- Cache Keys: Uses `feed` for initial page, `feed_{cursor}` for paginated pages

### Request Management

**Request Manager** (`lib/core/network/request_manager.dart`):
- Manages request cancellation for Riverpod providers
- Integrates with Riverpod's `ref.onDispose` for automatic cleanup
- Provides CancelToken for Dio requests
- Ensures pending requests are cancelled when providers are disposed

**Usage**:
```dart
final requestManager = ref.createRequestManager();
final feedPage = await apiClient.getFeed(
  cancelToken: requestManager.cancelToken,
);
```

### Connectivity Monitoring

**Connectivity Monitor** (`lib/core/utils/connectivity_monitor.dart`):
- Uses `connectivity_plus` package to monitor network status
- Provides Riverpod providers for connectivity state:
  - `connectivityStreamProvider`: Streams connectivity changes
  - `connectivityStatusProvider`: Current connectivity result
  - `isOnlineProvider`: Simple boolean indicating online status
  - `onlineStatusProvider`: Streams online/offline status as boolean

**Usage**:
```dart
// Check if online
final isOnline = await ref.read(isOnlineProvider.future);

// Watch online status
final onlineStatus = ref.watch(onlineStatusProvider);
```

---

## Local Storage

### Hive Integration

**Usage**:
- Caching feed data for offline access
- Storing user preferences
- Persisting agent configurations
- Optimistic update queue

**Cache Manager** (`lib/core/cache/cache_manager.dart`):
- Generic `CacheManager` class wrapping Hive for typed caching operations
- Methods: `get<T>`, `set<T>`, `delete`, `clear`, `getWithTTL`
- TTL (Time To Live) support with default 5-minute expiration
- Automatic timestamp tracking for cache freshness
- Support for typed Hive boxes with registered adapters

**Hive Type Adapters**:
- `PostAdapter` (typeId: 0): Manual adapter for Post model
- `ReplyAdapter` (typeId: 1): Manual adapter for Reply model
- `AuthorAdapter` (typeId: 2): Manual adapter for Author model
- `OptimisticStateAdapter` (typeId: 3): Manual adapter for OptimisticState enum

**Cache Strategies** (`lib/core/cache/cache_strategy.dart`):
- `CacheStrategy.cacheFirst`: Return cache if exists, else fetch from network
- `CacheStrategy.networkFirst`: Fetch from network, fallback to cache on error
- `CacheStrategy.staleWhileRevalidate`: Return cache immediately, fetch in background and update

**Usage Example**:
```dart
// Using cache manager
final cacheManager = ref.read(cacheManagerProvider);
await cacheManager.set('feed_key', feedData);
final cachedFeed = cacheManager.get<FeedPage>('feed_key');

// Using cache strategy
final result = await executeCacheStrategy<FeedPage>(
  strategy: CacheStrategy.staleWhileRevalidate,
  cacheManager: cacheManager,
  key: 'feed_key',
  fetchFn: () => apiClient.getFeed(),
);

// Using feed repository (implements staleWhileRevalidate internally)
final repository = ref.read(feedRepositoryProvider);
final feedPage = await repository.getFeed(); // Shows cache immediately, fetches fresh in background
final cachedFeed = repository.getCachedFeed(); // Get cache without network call
```

**Boxes**:
- `cache`: Default cache box managed by CacheManager
- Custom boxes can be created for specific use cases

**App Lifecycle Monitoring** (`lib/core/utils/app_lifecycle.dart`):
- Riverpod provider (`appLifecycleProvider`) monitoring `AppLifecycleState`
- Exposes current lifecycle state for request cancellation logic
- Extension methods for checking backgrounded/foregrounded states
- Useful for cancelling network requests when app goes to background

**Usage Example**:
```dart
// Watch app lifecycle state
final lifecycleState = ref.watch(appLifecycleProvider);

// Check if app is backgrounded
if (lifecycleState.isBackgrounded) {
  // Cancel ongoing requests
}

// Feed provider automatically listens to lifecycle and cancels requests
final feedNotifier = ref.read(feedProvider.notifier);
// Requests are automatically cancelled when app backgrounds
```

---

## Design System Integration

### Theme Configuration

The app uses `docs/design.json` for consistent styling:

**Colors**:
- Background, Surface, Primary colors
- Text colors (Primary, Secondary, Muted)
- Semantic colors (Success, Warning)

**Typography**:
- Title, Section Title, Body, Caption, Badge styles

**Components**:
- Cards, Buttons, Badges, Avatars
- Chat Bubbles (for replies/conversations)
- Empty States

**Implementation**:
```dart
// Theme provider using docs/design.json
@riverpod
ThemeData appTheme(AppThemeRef ref) {
  final design = ref.watch(designConfigProvider);
  return ThemeData(
    colorScheme: ColorScheme(
      background: Color(design.colors.background),
      primary: Color(design.colors.primary),
      // ... more colors
    ),
    // ... typography, component themes
  );
}
```

---

## Error Handling

### Error Types

```dart
abstract class Failure {
  String get message;
}

class NetworkFailure extends Failure { }
class ServerFailure extends Failure { }
class CacheFailure extends Failure { }
class ValidationFailure extends Failure { }
```

### Error Handling Strategy

1. **Try Remote First**: Attempt remote data fetch
2. **Fallback to Cache**: Use cached data if remote fails
3. **Show User Feedback**: Display appropriate error messages
4. **Log Errors**: Track errors for debugging

---

## Testing Strategy

### Unit Tests
- **Domain Layer**: Test use cases and business logic
- **Data Layer**: Test repositories, mappers, data sources
- **Agents**: Test agent logic and decision-making

### Widget Tests
- **Presentation Layer**: Test UI components in isolation
- **Provider Integration**: Test provider state changes
- **User Interactions**: Test user flows

### Integration Tests
- **End-to-End Flows**: Test complete user journeys
- **API Integration**: Test with real or mocked APIs
- **Offline Scenarios**: Test offline functionality

---

## Performance Optimization

### Strategies

1. **Image Caching**: Using `cached_network_image` for efficient image loading
2. **Lazy Loading**: Load feed content progressively
3. **Debouncing**: Debounce user input (search, filters)
4. **Memoization**: Cache expensive computations
5. **List Optimization**: Use ListView.builder for large lists
6. **Network Optimization**: Batch requests, minimize payloads

---

## Security

### Practices

1. **Secure Storage**: Use secure storage for sensitive data
2. **API Authentication**: Implement token-based auth
3. **Input Validation**: Validate all user inputs
4. **HTTPS Only**: All network requests over HTTPS
5. **Certificate Pinning**: For production environments

---

## Dependency Injection

### Riverpod as DI Container

Providers serve as dependency injection:

```dart
// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Repository provider
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    apiClient: ref.watch(apiClientProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
});

// Feed state provider
final feedProvider = StateNotifierProvider<FeedNotifier, AsyncValue<FeedState>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repository, ref);
});
```

---

## Future Architecture Considerations

1. **Modular Architecture**: Break into feature packages
2. **GraphQL Integration**: More efficient data fetching
3. **WebSocket Support**: Real-time updates
4. **Offline Sync**: Sophisticated conflict resolution
5. **Analytics Integration**: Track user behavior and app performance
6. **A/B Testing Framework**: Test feature variations

---

## Code Generation

### Generated Files

The project uses code generation for:
- **Freezed**: Immutable models and unions (`*.freezed.dart`)
- **JSON Serialization**: JSON encoding/decoding (`*.g.dart`)
- **Riverpod**: Provider code generation
- **Hive**: Type adapters (manual adapters used for Freezed classes)

**Commands**:
```bash
# Generate all code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch
```

**Note**: Hive type adapters for Post, Reply, Author, and OptimisticState are implemented manually since Freezed classes don't work directly with `hive_generator`. The adapters serialize/deserialize using JSON conversion methods.

---

## Development Workflow

1. **Create Model**: Define Freezed model
2. **Generate Code**: Run build_runner
3. **Create Repository**: Implement data layer
4. **Create Use Case**: Implement business logic
5. **Create Provider**: Wire up state management
6. **Create UI**: Build presentation layer
7. **Add Tests**: Write comprehensive tests
8. **Integrate Agent**: Add agent logic if needed

---

## References

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

