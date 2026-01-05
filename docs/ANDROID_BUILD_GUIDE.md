# Android Build Guide

Complete guide for building and deploying the CoffeeSpace Agentic Feed app for Android.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Build Configuration](#build-configuration)
4. [Building the App](#building-the-app)
5. [Common Issues and Solutions](#common-issues-and-solutions)
6. [Performance Optimization](#performance-optimization)
7. [Signing the App](#signing-the-app)
8. [Deployment](#deployment)

## Prerequisites

### Required Software

1. **Android Studio** (Latest stable version)
   - Download from [developer.android.com/studio](https://developer.android.com/studio)
   - Includes Android SDK, Emulator, and Build Tools
2. **Flutter SDK** (3.5.0 or later)
   - Verify installation: `flutter doctor -v`
3. **Java Development Kit (JDK)** (JDK 8 or later)
   - Android Studio includes JDK, or install separately
   - Verify: `java -version`
4. **Android SDK** (SDK 36+ and Build Tools 28.0.3+)
   - Installed via Android Studio SDK Manager
   - Verify: `flutter doctor -v`

### System Requirements

- **Operating System**: macOS, Linux, or Windows
- **Android SDK**: 36 or later
- **Android Build Tools**: 28.0.3 or later
- **Minimum SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: Latest stable (managed by Flutter)
- **NDK Version**: Managed by Flutter

### Verify Installation

```bash
# Check Flutter installation
flutter doctor -v

# Check Java version
java -version

# Check Android SDK
echo $ANDROID_HOME
# Or on macOS/Linux:
echo $ANDROID_SDK_ROOT

# List available Android devices/emulators
flutter devices
```

### Fix Android SDK Issues

If `flutter doctor` shows Android SDK issues:

```bash
# Accept Android licenses
flutter doctor --android-licenses

# Update Android SDK (via Android Studio)
# Tools > SDK Manager > SDK Tools
# Install: Android SDK Build-Tools, Android SDK Platform-Tools, Android Emulator
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

### 4. Configure Android SDK

Ensure Android SDK is properly configured:

```bash
# Set ANDROID_HOME (if not set)
# macOS/Linux:
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Windows:
# Set ANDROID_HOME in System Environment Variables
# C:\Users\<username>\AppData\Local\Android\Sdk
```

## Build Configuration

### Project Settings

The Android project is configured with the following settings:

- **Application ID**: `work.akhlaq.coffeespace`
- **Namespace**: `work.akhlaq.coffeespace`
- **Min SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: Latest stable (managed by Flutter)
- **Compile SDK**: Latest stable (managed by Flutter)
- **Java Version**: 1.8 (Java 8)
- **Kotlin Version**: Managed by Flutter

### Configuration Files

#### build.gradle (Project Level: `android/build.gradle`)

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

#### build.gradle (App Level: `android/app/build.gradle`)

Key configurations:
- **namespace**: `work.akhlaq.coffeespace`
- **compileSdk**: Managed by Flutter
- **minSdk**: 21
- **targetSdk**: Managed by Flutter
- **Java Compatibility**: 1.8

### Gradle Settings

#### settings.gradle (`android/settings.gradle`)

Uses Flutter's Gradle plugin for dependency management.

### AndroidManifest.xml

Located at `android/app/src/main/AndroidManifest.xml`:

- **Package**: `work.akhlaq.coffeespace`
- **Permissions**: Network access (for API calls)
- **Application Name**: CoffeeSpace

## Building the App

### Development Build (Emulator)

```bash
# List available emulators
flutter devices

# Start an emulator (if not running)
# Via Android Studio: Tools > Device Manager > Start

# Run on emulator
flutter run

# Or run on specific device
flutter run -d <device-id>
```

### Development Build (Physical Device)

1. **Enable Developer Options** on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"

2. **Connect Device**:
   ```bash
   # Connect via USB
   # Verify connection
   adb devices
   
   # Run on device
   flutter run
   ```

### Debug Build (APK)

```bash
# Build debug APK
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Profile Build (APK)

For performance testing:

```bash
flutter build apk --profile

# Output: build/app/outputs/flutter-apk/app-profile.apk
```

### Release Build (APK)

```bash
# Build release APK (unsigned)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Build split APKs (smaller size, one per ABI)
flutter build apk --split-per-abi

# Outputs:
# - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# - build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Release Build (App Bundle)

For Google Play Store:

```bash
# Build App Bundle (AAB)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build for Specific Configuration

```bash
# Debug build
flutter build apk --debug

# Profile build
flutter build apk --profile

# Release build
flutter build apk --release

# Release bundle
flutter build appbundle --release
```

## Common Issues and Solutions

### Issue 1: Android SDK Not Found

**Error**: `Android SDK not found` or `SDK location not found`

**Solution**:
```bash
# Set ANDROID_HOME environment variable
# macOS/Linux:
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Add to ~/.zshrc or ~/.bashrc for persistence
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Issue 2: Android Licenses Not Accepted

**Error**: `Some Android licenses not accepted`

**Solution**:
```bash
# Accept all licenses
flutter doctor --android-licenses

# Answer 'y' to all prompts
```

### Issue 3: Gradle Build Fails

**Error**: `Gradle build failed` or `Could not resolve dependencies`

**Solution**:
```bash
# Clean Gradle cache
cd android
./gradlew clean
cd ..

# Clean Flutter build
flutter clean

# Reinstall dependencies
flutter pub get
flutter build apk --debug
```

### Issue 4: SDK Version Mismatch

**Error**: `Flutter requires Android SDK 36 and the Android BuildTools 28.0.3`

**Solution**:
1. Open Android Studio
2. Go to **Tools > SDK Manager**
3. Install **Android SDK Platform 36**
4. Install **Android SDK Build-Tools 28.0.3**
5. Verify: `flutter doctor -v`

### Issue 5: Java Version Issues

**Error**: `Unsupported class file major version` or Java version errors

**Solution**:
```bash
# Check Java version
java -version

# Should be Java 8 or later
# If using Android Studio's JDK:
# File > Project Structure > SDK Location > JDK Location
# Should point to Android Studio's JDK
```

### Issue 6: Build Tools Version Mismatch

**Error**: `Build tools revision X.X.X is required`

**Solution**:
1. Open Android Studio
2. **Tools > SDK Manager > SDK Tools**
3. Check **Show Package Details**
4. Install required Build Tools version
5. Or update `android/app/build.gradle`:
   ```gradle
   android {
       buildToolsVersion "28.0.3"
   }
   ```

### Issue 7: Emulator Not Starting

**Error**: `No devices found` or emulator crashes

**Solution**:
```bash
# List available emulators
emulator -list-avds

# Start emulator from command line
emulator -avd <avd-name>

# Or use Android Studio:
# Tools > Device Manager > Start
```

### Issue 8: ADB Connection Issues

**Error**: `adb: device offline` or device not recognized

**Solution**:
```bash
# Restart ADB server
adb kill-server
adb start-server

# Check connected devices
adb devices

# If device shows "unauthorized":
# 1. Check device for "Allow USB debugging" prompt
# 2. Check "Always allow from this computer"
# 3. Tap "Allow"
```

### Issue 9: ProGuard/R8 Errors

**Error**: `R8: Missing classes` or ProGuard warnings

**Solution**:
Create or update `android/app/proguard-rules.pro`:
```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
```

### Issue 10: Multidex Issues

**Error**: `Cannot fit requested classes in a single dex file`

**Solution**:
In `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

## Performance Optimization

### Build Performance

1. **Gradle Daemon**:
   - Gradle daemon runs in background for faster builds
   - Enabled by default in `~/.gradle/gradle.properties`

2. **Build Cache**:
   ```bash
   # Flutter automatically caches builds
   # Clean only when necessary
   flutter clean  # Only when needed
   ```

3. **Parallel Builds**:
   - Gradle uses multiple cores by default
   - Configure in `android/gradle.properties`:
     ```properties
     org.gradle.parallel=true
     org.gradle.caching=true
     org.gradle.configureondemand=true
     ```

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

### APK Size Optimization

1. **Split APKs by ABI**:
   ```bash
   flutter build apk --split-per-abi
   ```
   - Reduces APK size by ~50%
   - One APK per architecture (arm64, arm32, x86_64)

2. **Enable ProGuard/R8**:
   - Code shrinking and obfuscation
   - Reduces APK size by ~20-30%

3. **Remove Unused Resources**:
   - R8 automatically removes unused resources in release builds

4. **Use App Bundle**:
   - Google Play generates optimized APKs per device
   - Smaller download size for users

## Signing the App

### Debug Signing

Debug builds are automatically signed with a debug keystore:
- Location: `~/.android/debug.keystore`
- Password: `android`
- Created automatically by Android SDK

### Release Signing

#### 1. Generate Keystore

```bash
# Generate a new keystore
keytool -genkey -v -keystore ~/coffeespace-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias coffeespace

# You'll be prompted for:
# - Keystore password
# - Key password
# - Name, Organization, etc.
```

**Important**: Keep the keystore file and passwords secure. You'll need them for all future releases.

#### 2. Configure Signing

Create `android/key.properties`:
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=coffeespace
storeFile=/path/to/coffeespace-release-key.jks
```

**Important**: Add `key.properties` to `.gitignore` (never commit keystore or passwords).

#### 3. Update build.gradle

In `android/app/build.gradle`, add before `android {`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Then update `android {` block:

```gradle
android {
    // ... existing code ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... other release config ...
        }
    }
}
```

#### 4. Build Signed Release

```bash
# Build signed release APK
flutter build apk --release

# Build signed release bundle
flutter build appbundle --release
```

## Deployment

### Google Play Store

#### 1. Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details (name, description, screenshots, etc.)

#### 2. Build App Bundle

```bash
flutter build appbundle --release
```

#### 3. Upload to Play Console

1. Go to **Release > Production** (or **Internal testing**)
2. Click **Create new release**
3. Upload `app-release.aab` from `build/app/outputs/bundle/release/`
4. Fill in release notes
5. Review and roll out

#### 4. App Signing

- Google Play can manage app signing for you (recommended)
- Or upload your own signing key

### Internal Testing

1. Build signed APK or AAB
2. Upload to Play Console > **Internal testing**
3. Add testers via email or Google Groups
4. Testers receive email with download link

### Beta Testing

1. Upload to **Closed testing** or **Open testing**
2. Set up testing tracks
3. Invite testers or make it public

### Direct APK Distribution

For distribution outside Google Play:

```bash
# Build signed release APK
flutter build apk --release

# Distribute app-release.apk
# Users need to enable "Install from unknown sources"
```

## Build Bottlenecks Analysis

### Identified Bottlenecks

1. **Gradle Dependency Resolution**: Downloading and resolving dependencies
   - **Impact**: First build or after dependency changes
   - **Mitigation**: Gradle cache, offline mode for CI/CD

2. **Code Generation**: Freezed and JSON serialization code generation
   - **Impact**: Initial build time
   - **Mitigation**: Incremental generation, only regenerates changed files

3. **Dart Compilation**: Compiling Dart code to native
   - **Impact**: Every build
   - **Mitigation**: Flutter's build cache, incremental compilation

4. **Gradle Build**: Compiling Java/Kotlin code and resources
   - **Impact**: Every build
   - **Mitigation**: Gradle daemon, parallel builds, build cache

5. **APK/AAB Packaging**: Creating final package
   - **Impact**: Every release build
   - **Mitigation**: Incremental packaging

### Optimization Recommendations

1. **Use Gradle Daemon**: Enabled by default, keeps Gradle running
2. **Enable Build Cache**: `org.gradle.caching=true` in `gradle.properties`
3. **Parallel Builds**: `org.gradle.parallel=true` in `gradle.properties`
4. **Incremental Builds**: Don't run `flutter clean` unnecessarily
5. **CI/CD Optimization**: Cache Gradle dependencies and Flutter build artifacts
6. **Code Generation**: Run `build_runner watch` during development

## Troubleshooting Checklist

- [ ] Flutter doctor shows no Android issues
- [ ] Android SDK is installed and configured
- [ ] ANDROID_HOME is set correctly
- [ ] Android licenses are accepted
- [ ] `flutter pub get` completed successfully
- [ ] Generated files exist (`*.freezed.dart`, `*.g.dart`)
- [ ] Gradle sync completed successfully
- [ ] Emulator or device is connected and recognized
- [ ] USB debugging is enabled (for physical devices)
- [ ] Java version is 8 or later
- [ ] Android SDK Build Tools are installed

## Additional Resources

- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Android Developer Documentation](https://developer.android.com/)
- [Gradle Build Tool](https://gradle.org/)
- [Google Play Console](https://play.google.com/console)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)

## Quick Reference

```bash
# Complete setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run on emulator/device
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build release bundle (for Play Store)
flutter build appbundle --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi --release

# Clean build
flutter clean
cd android && ./gradlew clean && cd ..
```

