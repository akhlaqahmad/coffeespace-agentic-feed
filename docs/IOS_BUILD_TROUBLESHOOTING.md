# iOS Build Troubleshooting Guide

## Common Error: "Command PhaseScriptExecution failed with a nonzero exit code"

This error typically occurs during iOS builds in Xcode or Flutter. Here are the most common causes and solutions.

## Quick Fix Steps (Try These First)

### 1. Clean and Rebuild
```bash
# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Reinstall CocoaPods
cd ios
pod deintegrate
pod install
cd ..

# Try building again
flutter build ios --no-codesign
```

### 2. Check Flutter Configuration
```bash
# Verify Flutter is properly configured
flutter doctor -v

# Ensure Flutter can find your project
flutter pub get
```

### 3. Verify CocoaPods Installation
```bash
# Check CocoaPods version
pod --version

# Update CocoaPods if needed
sudo gem install cocoapods

# Clean and reinstall pods
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

## Common Causes and Solutions

### Issue 1: CocoaPods Manifest Lock Mismatch

**Symptoms:**
- Error mentions "Podfile.lock" or "Manifest.lock"
- Build fails at "[CP] Check Pods Manifest.lock" phase

**Solution:**
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
```

### Issue 2: Flutter Build Script Issues

**Symptoms:**
- Error at "Run Script" phase
- FLUTTER_ROOT not found

**Solution:**
```bash
# Verify Flutter is in PATH
which flutter

# Clean and regenerate Flutter files
flutter clean
flutter pub get

# Verify Generated.xcconfig exists
ls -la ios/Flutter/Generated.xcconfig
```

### Issue 3: Code Signing Issues

**Symptoms:**
- Error about provisioning profiles or development teams
- Build fails during code signing phase

**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project → Runner target
3. Go to "Signing & Capabilities"
4. Select your Development Team
5. Let Xcode automatically manage signing

**For Simulator (No Signing Required):**
```bash
flutter run -d <simulator-id>
```

### Issue 4: Xcode Build Settings

**Symptoms:**
- Build fails with architecture errors
- "No such module" errors

**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Runner target
3. Build Settings → Search for "User Script Sandboxing"
4. Set "User Script Sandboxing" to **NO** (if enabled)

### Issue 5: Derived Data Issues

**Symptoms:**
- Intermittent build failures
- Strange caching issues

**Solution:**
```bash
# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean Flutter build
flutter clean

# Rebuild
flutter pub get
cd ios && pod install && cd ..
```

## Advanced Troubleshooting

### Check Build Logs

In Xcode:
1. Open the Report Navigator (⌘9)
2. Select the failed build
3. Expand the failed phase
4. Look for the actual error message

### Verify Script Permissions

```bash
# Ensure Flutter scripts are executable
chmod +x /Users/akhlaqahmad/development/flutter/packages/flutter_tools/bin/xcode_backend.sh
```

### Check Environment Variables

The build scripts rely on these environment variables:
- `FLUTTER_ROOT` - Path to Flutter SDK
- `FLUTTER_APPLICATION_PATH` - Path to your project

Verify in `ios/Flutter/Generated.xcconfig`:
```bash
cat ios/Flutter/Generated.xcconfig
```

### Podfile Issues

If you've modified the Podfile, ensure:
1. Platform version matches: `platform :ios, '13.0'`
2. `use_frameworks!` is present
3. No syntax errors in Podfile

## Prevention

1. **Always use `flutter pub get`** before building
2. **Run `pod install`** after adding new Flutter plugins
3. **Use `flutter clean`** when experiencing strange build issues
4. **Keep CocoaPods updated**: `sudo gem install cocoapods`
5. **Use the workspace file**: Always open `Runner.xcworkspace`, not `Runner.xcodeproj`

## Still Having Issues?

1. Check the full build log in Xcode (Report Navigator)
2. Verify all dependencies are compatible
3. Try building on a different machine/environment
4. Check Flutter GitHub issues for known problems
5. Ensure Xcode Command Line Tools are installed: `xcode-select --install`

## Related Documentation

- [Flutter iOS Setup](https://docs.flutter.dev/deployment/ios)
- [CocoaPods Troubleshooting](https://guides.cocoapods.org/using/troubleshooting.html)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode/build-settings-reference)

