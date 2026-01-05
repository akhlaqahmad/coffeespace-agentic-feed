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
3. Run `flutter run` to start the app

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
android/              # Android-specific code
ios/                  # iOS-specific code
test/                 # Widget and unit tests
docs/                 # Project documentation
  agents.md          # Agent system documentation
  ARCHITECTURE.md    # Architecture and patterns
  design.json        # Design system configuration
  DOCUMENTATION_WORKFLOW.md  # Documentation workflow guide
```

## Documentation

Project documentation is located in the `docs/` folder:

- **[Agents Documentation](docs/agents.md)** - Agent system architecture and implementation
- **[Architecture Documentation](docs/ARCHITECTURE.md)** - App architecture, patterns, and structure
- **[Design System](docs/design.json)** - Design tokens, colors, typography, and components
- **[Documentation Workflow](docs/DOCUMENTATION_WORKFLOW.md)** - How documentation is automatically updated

For more details on how documentation is automatically maintained, see [Documentation Workflow](docs/DOCUMENTATION_WORKFLOW.md).