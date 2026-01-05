import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'metrics_collector.dart';

/// Debug screen to view performance metrics
class MetricsDebugScreen extends ConsumerWidget {
  const MetricsDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsCollectorProvider);
    final cacheMetrics = metrics.getCacheMetrics();
    final apiMetrics = metrics.getAPIMetrics();
    final optimisticMetrics = metrics.getOptimisticMetrics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              metrics.reset();
              // Trigger rebuild
              ref.refresh(metricsCollectorProvider);
            },
            tooltip: 'Reset Metrics',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cache Metrics
          _buildSection(
            title: 'Cache Metrics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricRow('Cache Hits', cacheMetrics.hits.toString()),
                _buildMetricRow('Cache Misses', cacheMetrics.misses.toString()),
                _buildMetricRow(
                  'Hit Rate',
                  '${(cacheMetrics.hitRate * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API Metrics
          _buildSection(
            title: 'API Metrics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricRow('Total Calls', apiMetrics.totalCalls.toString()),
                _buildMetricRow('Success Count', apiMetrics.successCount.toString()),
                _buildMetricRow('Failure Count', apiMetrics.failureCount.toString()),
                _buildMetricRow(
                  'Success Rate',
                  '${(apiMetrics.successRate * 100).toStringAsFixed(1)}%',
                ),
                _buildMetricRow(
                  'Avg Latency',
                  '${apiMetrics.getOverallAverageLatency().toStringAsFixed(0)}ms',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Endpoint Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...apiMetrics.calls.entries.map((entry) {
                  final endpoint = entry.key;
                  final calls = entry.value;
                  final successCount = calls.where((c) => c.success).length;
                  final avgLatency = apiMetrics.getAverageLatency(endpoint);
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endpoint,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '  Calls: ${calls.length} | '
                          'Success: ${successCount}/${calls.length} | '
                          'Avg Latency: ${avgLatency.toStringAsFixed(0)}ms',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Optimistic Metrics
          _buildSection(
            title: 'Optimistic Action Metrics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricRow(
                  'Total Actions',
                  optimisticMetrics.totalActions.toString(),
                ),
                _buildMetricRow(
                  'Success Count',
                  optimisticMetrics.successCount.toString(),
                ),
                _buildMetricRow(
                  'Failure Count',
                  optimisticMetrics.failureCount.toString(),
                ),
                _buildMetricRow(
                  'Success Rate',
                  '${(optimisticMetrics.successRate * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Action Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...optimisticMetrics.actions.entries.map((entry) {
                  final action = entry.key;
                  final actions = entry.value;
                  final successCount = actions.where((a) => a.success).length;
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '  Total: ${actions.length} | '
                          'Success: $successCount/${actions.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

