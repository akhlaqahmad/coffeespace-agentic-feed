// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_monitor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStreamHash() =>
    r'9f132ab78e7f25276d70f04b97e84bd8de0a5de2';

/// Provider that streams connectivity status changes
///
/// Copied from [connectivityStream].
@ProviderFor(connectivityStream)
final connectivityStreamProvider =
    AutoDisposeStreamProvider<ConnectivityResult>.internal(
  connectivityStream,
  name: r'connectivityStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectivityStreamRef
    = AutoDisposeStreamProviderRef<ConnectivityResult>;
String _$connectivityStatusHash() =>
    r'1283042109a8bfb4dc3553ca52c64fd1d42de2e6';

/// Provider that provides the current connectivity result
///
/// Copied from [connectivityStatus].
@ProviderFor(connectivityStatus)
final connectivityStatusProvider =
    AutoDisposeFutureProvider<ConnectivityResult>.internal(
  connectivityStatus,
  name: r'connectivityStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectivityStatusRef
    = AutoDisposeFutureProviderRef<ConnectivityResult>;
String _$isOnlineHash() => r'e80a453235a33422d617b46e83636eb85a9111bc';

/// Provider that provides a simple boolean indicating online status
///
/// Copied from [isOnline].
@ProviderFor(isOnline)
final isOnlineProvider = AutoDisposeFutureProvider<bool>.internal(
  isOnline,
  name: r'isOnlineProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isOnlineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnlineRef = AutoDisposeFutureProviderRef<bool>;
String _$onlineStatusHash() => r'56d89a94edde659c60c8592fc5f6ed25526619a3';

/// Provider that streams online/offline status as a boolean
///
/// Copied from [onlineStatus].
@ProviderFor(onlineStatus)
final onlineStatusProvider = AutoDisposeStreamProvider<bool>.internal(
  onlineStatus,
  name: r'onlineStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$onlineStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnlineStatusRef = AutoDisposeStreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
