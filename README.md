# CoffeeSpace Agentic Feed

A new Flutter mobile application.

## Project Details

- **Project Name:** coffeespace_agentic_feed
- **Bundle ID/Application ID:** work.akhlaq.coffeespace
- **Platforms:** iOS and Android
- **Flutter SDK:** Latest stable (3.5.0+)
- **Dart:** Null safety enabled

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- iOS development: Xcode, CocoaPods
- Android development: Android Studio, Android SDK

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate code (Freezed, JSON serialization, etc.)
4. Run `flutter run` to start the app

### Running the App

```bash
# Get dependencies
flutter pub get

# Run on available device (shows list of available devices)
flutter run

# Run on specific platform
flutter run -d macos    # Run on macOS
flutter run -d chrome   # Run on Chrome (web)

# Run tests
flutter test

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## Project Structure

```
lib/
  main.dart           # Main application entry point
  features/           # Feature modules
    feed/             # Feed feature
      data/models/    # Data models (Post, Author, Reply)
  core/               # Core functionality
    network/          # Networking layer
      api_client.dart      # Mock API client for testing
      request_manager.dart  # Request cancellation manager
      mock_data.dart       # Mock data generator (50+ posts)
      models/             # Network models (FeedPage)
    cache/            # Caching layer
      cache_manager.dart   # Generic cache manager wrapping Hive
      cache_strategy.dart  # Cache strategy patterns
      cache_providers.dart # Cache manager providers
    utils/            # Utilities
      connectivity_monitor.dart  # Connectivity monitoring
      app_lifecycle.dart         # App lifecycle state monitoring
android/              # Android-specific code
ios/                  # iOS-specific code
test/                 # Widget and unit tests
docs/                 # Project documentation
  agents.md          # Agent system documentation
  ARCHITECTURE.md    # Architecture and patterns
  design.json        # Design system configuration
  DOCUMENTATION_WORKFLOW.md  # Documentation workflow guide
```

## Key Features

- **Mock API Client**: Realistic API simulation with network delays and failures for testing
- **Optimistic Updates**: Support for offline-first architecture with optimistic state management
- **Request Management**: Automatic request cancellation integrated with Riverpod providers
- **Connectivity Monitoring**: Real-time network status monitoring using connectivity_plus
- **Mock Data**: 50+ sample posts with pre-initialized comments and varied coffee-related content for testing
- **Caching Layer**: Hive-based caching with stale-while-revalidate strategy
- **Cache Strategies**: Multiple caching strategies (cache-first, network-first, stale-while-revalidate)
- **App Lifecycle Monitoring**: Riverpod provider for app lifecycle state management
- **Error Handling**: Comprehensive error handling with dismissible error banners
- **Offline Mode**: Full offline support with cached content indicators and offline banners

## Documentation

Project documentation is located in the `docs/` folder:

- **[Agents Documentation](docs/agents.md)** - Agent system architecture and implementation
- **[Architecture Documentation](docs/ARCHITECTURE.md)** - App architecture, patterns, and structure
- **[Design System](docs/design.json)** - Design tokens, colors, typography, and components
- **[iOS Build Guide](docs/IOS_BUILD_GUIDE.md)** - Complete guide for building and deploying iOS
- **[Android Build Guide](docs/ANDROID_BUILD_GUIDE.md)** - Complete guide for building and deploying Android
- **[Build Bottlenecks Analysis](docs/BUILD_BOTTLENECKS.md)** - Analysis of build-time and runtime bottlenecks
- **[iOS Build Troubleshooting](docs/IOS_BUILD_TROUBLESHOOTING.md)** - Common iOS build issues and solutions
- **[Documentation Workflow](docs/DOCUMENTATION_WORKFLOW.md)** - How documentation is automatically updated

For more details on how documentation is automatically maintained, see [Documentation Workflow](docs/DOCUMENTATION_WORKFLOW.md).