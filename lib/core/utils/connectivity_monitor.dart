import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
@riverpod
Future<bool> isOnline(IsOnlineRef ref) async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  return result != ConnectivityResult.none;
}

/// Provider that streams online/offline status as a boolean
@riverpod
Stream<bool> onlineStatus(OnlineStatusRef ref) {
  return ref.watch(connectivityStreamProvider).map((result) {
    return result != ConnectivityResult.none;
  });
}

