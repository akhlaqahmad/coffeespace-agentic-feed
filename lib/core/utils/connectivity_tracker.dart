import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../metrics/metrics_collector.dart';

part 'connectivity_tracker.g.dart';

/// Provider that tracks connectivity changes in metrics
/// 
/// This provider listens to connectivity changes and automatically
/// tracks them in the metrics system.
@riverpod
class ConnectivityTracker extends _$ConnectivityTracker {
  @override
  void build() {
    // Listen to connectivity changes and track them
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      final networkType = _getNetworkType(result);
      
      try {
        final metricsCollector = ref.read(metricsCollectorProvider);
        metricsCollector.trackConnectivityChange(isOnline, networkType: networkType);
      } catch (e) {
        // Fail silently - metrics shouldn't break the app
      }
    });
  }

  String? _getNetworkType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'mobile';
      case ConnectivityResult.ethernet:
        return 'ethernet';
      case ConnectivityResult.none:
        return 'none';
      case ConnectivityResult.bluetooth:
        return 'bluetooth';
      case ConnectivityResult.vpn:
        return 'vpn';
      case ConnectivityResult.other:
        return 'other';
    }
  }
}

