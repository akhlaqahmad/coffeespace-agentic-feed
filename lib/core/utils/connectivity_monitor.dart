import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../debug/debug_menu.dart';

part 'connectivity_monitor.g.dart';

/// Provider that streams connectivity status changes
@riverpod
Stream<ConnectivityResult> connectivityStream(ConnectivityStreamRef ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
}

/// Provider that provides the current connectivity result
@riverpod
Future<ConnectivityResult> connectivityStatus(ConnectivityStatusRef ref) async {
  final connectivity = Connectivity();
  return await connectivity.checkConnectivity();
}

/// Provider that provides a simple boolean indicating online status
/// Respects forced connectivity mode from debug menu
@riverpod
Future<bool> isOnline(IsOnlineRef ref) async {
  final forced = ref.watch(forcedConnectivityProvider);
  if (forced != null) {
    return forced;
  }
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  return result != ConnectivityResult.none;
}

/// Provider that streams online/offline status as a boolean
/// Respects forced connectivity mode from debug menu
@riverpod
Stream<bool> onlineStatus(OnlineStatusRef ref) {
  final forced = ref.watch(forcedConnectivityProvider);
  if (forced != null) {
    return Stream.value(forced);
  }
  return ref.watch(connectivityStreamProvider).map((result) {
    return result != ConnectivityResult.none;
  });
}

