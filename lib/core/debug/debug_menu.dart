import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_providers.dart';
import '../metrics/metrics_debug_screen.dart';
import '../network/api_client_provider.dart';
import '../utils/connectivity_monitor.dart';

/// Provider for mock API failure rate (0.0 to 1.0)
final mockApiFailureRateProvider = StateProvider<double>((ref) => 0.2);

/// Provider for forced connectivity mode (null = auto, true = online, false = offline)
final forcedConnectivityProvider = StateProvider<bool?>((ref) => null);

/// Debug menu screen accessible via long-press on app bar
class DebugMenuScreen extends ConsumerWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failureRate = ref.watch(mockApiFailureRateProvider);
    final forcedConnectivity = ref.watch(forcedConnectivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mock API Failure Rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mock API Failure Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(failureRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: failureRate,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${(failureRate * 100).toStringAsFixed(0)}%',
                    onChanged: (value) {
                      ref.read(mockApiFailureRateProvider.notifier).state = value;
                      // Update API client immediately
                      ref.read(apiClientProvider).setFailureRate(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton(
                        context,
                        '0%',
                        () {
                          ref.read(mockApiFailureRateProvider.notifier).state = 0.0;
                          ref.read(apiClientProvider).setFailureRate(0.0);
                        },
                      ),
                      _buildQuickButton(
                        context,
                        '20%',
                        () {
                          ref.read(mockApiFailureRateProvider.notifier).state = 0.2;
                          ref.read(apiClientProvider).setFailureRate(0.2);
                        },
                      ),
                      _buildQuickButton(
                        context,
                        '50%',
                        () {
                          ref.read(mockApiFailureRateProvider.notifier).state = 0.5;
                          ref.read(apiClientProvider).setFailureRate(0.5);
                        },
                      ),
                      _buildQuickButton(
                        context,
                        '100%',
                        () {
                          ref.read(mockApiFailureRateProvider.notifier).state = 1.0;
                          ref.read(apiClientProvider).setFailureRate(1.0);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Force Connectivity Mode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Force Connectivity Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forcedConnectivity == null
                        ? 'Auto (using actual connectivity)'
                        : forcedConnectivity
                            ? 'Forced Online'
                            : 'Forced Offline',
                    style: TextStyle(
                      fontSize: 16,
                      color: forcedConnectivity == null
                          ? Colors.grey
                          : forcedConnectivity
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton(
                        context,
                        'Auto',
                        () => ref.read(forcedConnectivityProvider.notifier).state = null,
                      ),
                      _buildQuickButton(
                        context,
                        'Online',
                        () => ref.read(forcedConnectivityProvider.notifier).state = true,
                      ),
                      _buildQuickButton(
                        context,
                        'Offline',
                        () => ref.read(forcedConnectivityProvider.notifier).state = false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cache Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cache Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final cacheManager = ref.read(cacheManagerProvider);
                        await cacheManager.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All caches cleared'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear All Caches'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Dashboard
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metrics Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MetricsDebugScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics),
                      label: const Text('View Metrics Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(BuildContext context, String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

