# iOS Build Guide

Complete guide for building and deploying the CoffeeSpace Agentic Feed app for iOS.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Build Configuration](#build-configuration)
4. [Building the App](#building-the-app)
5. [Common Issues and Solutions](#common-issues-and-solutions)
6. [Performance Optimization](#performance-optimization)
7. [Code Signing](#code-signing)
8. [Deployment](#deployment)

## Prerequisites

### Required Software

1. **macOS** (macOS 12.0 or later)
2. **Xcode** (Latest stable version, currently 26.2+)
   - Install from Mac App Store or [Apple Developer](https://developer.apple.com/xcode/)
   - Includes iOS SDK, Simulator, and Command Line Tools
3. **Flutter SDK** (3.5.0 or later)
   - Verify installation: `flutter doctor -v`
4. **CocoaPods** (1.16.2 or later)
   - Install: `sudo gem install cocoapods`
   - Verify: `pod --version`
5. **Xcode Command Line Tools**
   - Install: `xcode-select --install`

### System Requirements

- **macOS**: 12.0 (Monterey) or later
- **Xcode**: Latest stable version
- **iOS Deployment Target**: iOS 13.0 or later
- **Swift Version**: 5.0
- **Architecture**: arm64 (Apple Silicon) or x86_64 (Intel)

### Verify Installation

```bash
# Check Flutter installation
flutter doctor -v

# Check CocoaPods
pod --version

# Check Xcode
xcodebuild -version

# Check iOS simulators
xcrun simctl list devices
```

## Initial Setup

### 1. Clone and Navigate to Project

```bash
cd /path/to/coffeespace-agentic-feed
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Generate Code (Freezed, JSON Serialization)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

**Important**: Always use `Runner.xcworkspace`, not `Runner.xcodeproj` when opening in Xcode.

## Build Configuration

### Project Settings

The iOS project is configured with the following settings:

- **Bundle Identifier**: `work.akhlaq.coffeespace`
- **iOS Deployment Target**: `13.0`
- **Swift Version**: `5.0`
- **Minimum iOS Version**: iOS 13.0
- **Supported Devices**: iPhone and iPad

### Configuration Files

#### Podfile (`ios/Podfile`)

```ruby
platform :ios, '13.0'
# CocoaPods analytics disabled for faster builds
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
```

#### Info.plist (`ios/Runner/Info.plist`)

Key configurations:
- **CFBundleDisplayName**: CoffeeSpace
- **CFBundleIdentifier**: work.akhlaq.coffeespace
- **LSRequiresIPhoneOS**: true
- **UISupportedInterfaceOrientations**: Portrait, Landscape Left/Right

### Build Settings

The project uses Flutter's default build settings with the following customizations:

- **ENABLE_BITCODE**: NO (required for Flutter)
- **SWIFT_VERSION**: 5.0
- **IPHONEOS_DEPLOYMENT_TARGET**: 13.0
- **CODE_SIGN_IDENTITY**: iPhone Developer (for development)

## Building the App

### Development Build (Simulator)

```bash
# List available simulators
flutter devices

# Run on specific simulator
flutter run -d <simulator-id>

# Or run on any available iOS device
flutter run
```

### Development Build (Physical Device)

```bash
# Connect your iPhone via USB or WiFi
# Enable Developer Mode on your iPhone (Settings > Privacy & Security > Developer Mode)

# Run on connected device
flutter run -d <device-id>
```

### Release Build (No Code Signing)

For testing builds without code signing:

```bash
flutter build ios --no-codesign
```

The output will be in `build/ios/iphoneos/Runner.app`

### Release Build (With Code Signing)

For App Store or TestFlight distribution:

```bash
flutter build ios --release
```

### Build for Specific Configuration

```bash
# Debug build
flutter build ios --debug

# Profile build (for performance testing)
flutter build ios --profile

# Release build
flutter build ios --release
```

### Build IPA File

To create an IPA file for distribution:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Product > Archive**
3. Once archived, select **Distribute App**
4. Choose distribution method (App Store, Ad Hoc, Enterprise, or Development)

Or use command line:

```bash
# Build and archive
flutter build ipa

# Or specify export options
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```

## Common Issues and Solutions

### Issue 1: Import Path Errors

**Error**: `Error when reading 'lib/core/features/feed/data/models/post.dart': No such file or directory`

**Solution**: Use package imports instead of relative imports in network models:

```dart
// ❌ Wrong
import '../../features/feed/data/models/post.dart';

// ✅ Correct
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';
```

### Issue 2: CocoaPods Installation Fails

**Error**: `[!] CocoaPods could not find compatible versions`

**Solution**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
cd ..
```

### Issue 3: Flutter Build Script Errors

**Error**: `PhaseScriptExecution failed with a nonzero exit code`

**Solution**:
```bash
# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstall
flutter pub get
cd ios && pod install && cd ..

# Verify Generated.xcconfig exists
ls -la ios/Flutter/Generated.xcconfig
```

### Issue 4: Code Signing Errors

**Error**: `No profiles for 'work.akhlaq.coffeespace' were found`

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **Signing & Capabilities**
4. Select your **Development Team**
5. Enable **Automatically manage signing**
6. Xcode will create provisioning profiles automatically

**For Simulator Only** (no signing needed):
```bash
flutter run -d <simulator-id>
```

### Issue 5: Swift Version Conflicts

**Error**: `Swift version mismatch`

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project
3. Go to **Build Settings**
4. Search for **Swift Language Version**
5. Set to **Swift 5.0** for all targets

### Issue 6: Pod Installation Hangs

**Solution**:
```bash
# Disable CocoaPods stats (already in Podfile)
export COCOAPODS_DISABLE_STATS=true

# Use verbose mode to see what's happening
cd ios
pod install --verbose
```

### Issue 7: Architecture Mismatch

**Error**: `Building for iOS Simulator, but the linked framework was built for iOS`

**Solution**:
```bash
# Clean and rebuild
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter build ios --simulator
```

### Issue 8: Missing Generated Files

**Error**: `feed_page.freezed.dart` or `feed_page.g.dart` not found

**Solution**:
```bash
# Regenerate code
flutter pub run build_runner build --delete-conflicting-outputs

# If that fails, clean first
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue 9: Missing App Icon

**Error**: `The stickers icon set, app icon set, or icon stack named "AppIcon" did not have any applicable content`

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Navigate to `Runner/Assets.xcassets/AppIcon.appiconset`
3. Add app icon images (required sizes: 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5, 1024x1024)
4. Or use an app icon generator tool
5. Rebuild the app

**Quick Fix** (for development only):
- The app will build without icons, but App Store submission requires proper icons
- For testing, you can temporarily use placeholder images

## Performance Optimization

### Build Performance

1. **Disable CocoaPods Analytics** (already configured):
   ```ruby
   ENV['COCOAPODS_DISABLE_STATS'] = 'true'
   ```

2. **Use Build Cache**:
   ```bash
   # Flutter automatically caches builds
   # Clean only when necessary
   flutter clean  # Only when needed
   ```

3. **Parallel Builds**:
   - Xcode automatically uses multiple cores
   - Ensure **Build Settings > Build Options > Parallelize Build** is enabled

4. **Incremental Builds**:
   - Flutter supports incremental builds
   - Only changed files are rebuilt

### Runtime Performance

The app includes several performance optimizations:

1. **Image Caching**: `CachedNetworkImage` with memory and disk limits
2. **Lazy Loading**: `ListView.builder` with `cacheExtent: 1000`
3. **Selective Rebuilds**: Riverpod providers for minimal rebuilds
4. **RepaintBoundary**: Isolated repaints for post cards
5. **Const Constructors**: Compile-time optimizations

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed performance optimizations.

## Code Signing

### Development Signing

1. **Automatic Signing** (Recommended):
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select **Runner** target
   - Go to **Signing & Capabilities**
   - Enable **Automatically manage signing**
   - Select your **Team**

2. **Manual Signing**:
   - Disable automatic signing
   - Select provisioning profile
   - Select signing certificate

### Distribution Signing

For App Store or TestFlight:

1. **App Store Connect**:
   - Create App ID in [Apple Developer Portal](https://developer.apple.com/account/)
   - Create Distribution Certificate
   - Create App Store Provisioning Profile

2. **Xcode**:
   - Archive the app (Product > Archive)
   - Distribute to App Store Connect
   - Upload for TestFlight or App Store review

### Export Options

Create `ios/ExportOptions.plist` for automated builds:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

## Deployment

### TestFlight

1. Build and archive in Xcode
2. Upload to App Store Connect
3. Process in App Store Connect (can take 10-30 minutes)
4. Add to TestFlight group
5. Invite testers

### App Store

1. Complete App Store Connect listing
2. Upload build via Xcode or Transporter
3. Submit for review
4. Wait for approval (typically 1-3 days)

### Ad Hoc Distribution

For internal testing without TestFlight:

```bash
# Build IPA with ad-hoc provisioning
flutter build ipa --export-method ad-hoc
```

### Enterprise Distribution

For enterprise apps:

```bash
flutter build ipa --export-method enterprise
```

## Build Bottlenecks Analysis

### Identified Bottlenecks

1. **Code Generation**: Freezed and JSON serialization code generation
   - **Impact**: Initial build time
   - **Mitigation**: Incremental generation, only regenerates changed files

2. **CocoaPods Installation**: Pod dependency resolution
   - **Impact**: First build or after dependency changes
   - **Mitigation**: Pod caching, `COCOAPODS_DISABLE_STATS=true`

3. **Xcode Build**: Compilation of Swift/Objective-C code
   - **Impact**: Every build
   - **Mitigation**: Incremental builds, parallel compilation

4. **Flutter Build**: Dart compilation and asset bundling
   - **Impact**: Every build
   - **Mitigation**: Flutter's build cache, incremental compilation

### Optimization Recommendations

1. **Use Build Cache**: Don't run `flutter clean` unnecessarily
2. **Incremental Builds**: Only rebuild what changed
3. **Parallel Builds**: Xcode uses multiple cores automatically
4. **CI/CD**: Use cached dependencies in CI pipelines
5. **Code Generation**: Run `build_runner watch` during development

## Troubleshooting Checklist

- [ ] Flutter doctor shows no issues
- [ ] CocoaPods is installed and up to date
- [ ] Xcode Command Line Tools are installed
- [ ] `flutter pub get` completed successfully
- [ ] `pod install` completed successfully
- [ ] Generated files exist (`*.freezed.dart`, `*.g.dart`)
- [ ] Code signing is configured (for device builds)
- [ ] Development team is selected in Xcode
- [ ] iOS deployment target matches Podfile (13.0)
- [ ] Swift version is 5.0
- [ ] Using `Runner.xcworkspace`, not `Runner.xcodeproj`

## Additional Resources

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [CocoaPods Guide](https://guides.cocoapods.org/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [iOS Build Troubleshooting](IOS_BUILD_TROUBLESHOOTING.md)

## Quick Reference

```bash
# Complete setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
cd ios && pod install && cd ..

# Run on simulator
flutter run

# Build for release
flutter build ios --release

# Clean build
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

