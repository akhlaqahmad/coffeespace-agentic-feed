import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../debug/debug_menu.dart';
import 'api_client.dart';

/// Provider for ApiClient instance with configurable failure rate
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  
  // Listen to failure rate changes and update the client
  ref.listen<double>(
    mockApiFailureRateProvider,
    (previous, next) {
      client.setFailureRate(next);
    },
  );
  
  // Set initial failure rate
  client.setFailureRate(ref.read(mockApiFailureRateProvider));
  
  return client;
});

