# Metrics & Observability

## Overview

CoffeeSpace Agentic Feed implements a comprehensive metrics and observability system to track application performance, user behavior, and system health. The system is designed to be lightweight, non-intrusive, and easily extensible for third-party analytics integration.

## Metrics Philosophy

Our metrics system follows these principles:

1. **Lightweight**: Minimal performance overhead, in-memory aggregation
2. **Non-intrusive**: Metrics collection doesn't affect core functionality
3. **Actionable**: Metrics provide insights that drive improvements
4. **Privacy-conscious**: No PII collection, anonymized data
5. **Extensible**: Easy to integrate with third-party analytics tools

## Tracked Metrics

### 1. Performance Metrics

#### Cache Metrics
- **Cache Hits**: Number of successful cache retrievals
- **Cache Misses**: Number of cache misses requiring network requests
- **Hit Rate**: Percentage of cache hits vs total cache operations
- **Why**: Measures cache effectiveness, helps optimize caching strategy and reduce network load

#### API Metrics
- **Total API Calls**: Count of all API requests
- **Success Rate**: Percentage of successful API calls
- **Average Latency**: Mean response time per endpoint
- **Endpoint-specific Metrics**: Detailed metrics per API endpoint
- **Why**: Identifies slow endpoints, network issues, and API reliability problems

#### Optimistic Update Metrics
- **Total Actions**: Count of optimistic UI updates (likes, reposts)
- **Success Rate**: Percentage of optimistic actions that succeed
- **Action Breakdown**: Metrics per action type (like, repost, reply)
- **Why**: Measures the effectiveness of optimistic updates and identifies failure patterns

### 2. User Interaction Metrics

#### Screen Views
- **Screen Name**: Which screens users visit
- **View Duration**: Time spent on each screen
- **Navigation Flow**: Sequence of screen transitions
- **Why**: Understand user engagement, identify popular features, optimize navigation

#### User Actions
- **Post Interactions**: Likes, reposts, replies
- **Feed Interactions**: Scroll depth, pull-to-refresh usage
- **Error Interactions**: How users respond to errors
- **Why**: Measure feature adoption, identify friction points, optimize UX

### 3. System Health Metrics

#### App Lifecycle Events
- **App State Transitions**: Foreground/background/paused states
- **Session Duration**: Time app is active
- **Background Time**: Time app spends in background
- **Why**: Understand app usage patterns, optimize background behavior

#### Connectivity Metrics
- **Connection State Changes**: Online/offline transitions
- **Offline Duration**: Time spent offline
- **Network Type**: WiFi, cellular, none
- **Why**: Measure offline-first effectiveness, identify connectivity issues

#### Error Metrics
- **Error Count**: Total errors encountered
- **Error Types**: Network, server, optimistic failures
- **Error Rate**: Errors per user session
- **Error Recovery**: Success rate of error recovery
- **Why**: Identify systemic issues, measure error handling effectiveness

### 4. Business Metrics (Optional)

#### Engagement Metrics
- **Daily Active Users (DAU)**: Users who interact with the app daily
- **Posts Viewed**: Number of posts users view
- **Interaction Rate**: Percentage of posts that receive interactions
- **Session Length**: Average time per session

#### Content Metrics
- **Feed Load Time**: Time to first post display
- **Pagination Usage**: How often users load more content
- **Cache Effectiveness**: How often cached data is used

## Implementation

### Architecture

The metrics system is built on three layers:

1. **Collection Layer**: Lightweight instrumentation throughout the app
2. **Aggregation Layer**: In-memory metrics collector with efficient data structures
3. **Presentation Layer**: Debug UI for viewing metrics in development

### Core Components

#### MetricsCollector (`lib/core/metrics/metrics_collector.dart`)

Central metrics aggregator that tracks:
- Cache operations
- API calls with latency
- Optimistic actions
- User interactions
- App lifecycle events
- Connectivity changes
- Errors

#### MetricsDebugScreen (`lib/core/metrics/metrics_debug_screen.dart`)

Development-only UI for viewing real-time metrics:
- Cache performance
- API call statistics
- Optimistic action success rates
- User interaction patterns
- System health indicators

### Instrumentation Points

#### API Calls
```dart
// Automatically tracked in FeedRepository
_metricsCollector?.trackAPICall(endpoint, success, latencyMs);
```

#### Cache Operations
```dart
// Automatically tracked in CacheManager
_metricsCollector?.trackCacheHit(key);
_metricsCollector?.trackCacheMiss(key);
```

#### User Interactions
```dart
// Tracked in interaction providers
metricsCollector.trackOptimisticAction('like', success);
metricsCollector.trackUserInteraction('screen_view', {'screen': 'feed'});
```

#### App Lifecycle
```dart
// Tracked in AppLifecycleNotifier
metricsCollector.trackLifecycleEvent('app_foregrounded');
```

#### Connectivity
```dart
// Tracked in connectivity monitor
metricsCollector.trackConnectivityChange(isOnline);
```

#### Errors
```dart
// Tracked in error provider
metricsCollector.trackError(errorType, errorMessage);
```

## Third-Party Tooling

### Recommended Options

#### 1. Firebase Analytics (Recommended for Production)

**Why Firebase Analytics:**
- **Free tier**: Generous free tier for most apps
- **Real-time insights**: Live dashboard and reports
- **Event tracking**: Custom events and user properties
- **Crash reporting**: Integrated with Firebase Crashlytics
- **A/B testing**: Built-in experimentation framework
- **Privacy**: GDPR/CCPA compliant, data residency options

**Integration Approach:**
- Wrap Firebase Analytics calls in metrics collector
- Send aggregated metrics periodically
- Maintain local metrics for immediate debugging

**Implementation:**
```dart
class MetricsCollector {
  final FirebaseAnalytics? _analytics;
  
  void trackAPICall(String endpoint, bool success, double latencyMs) {
    // Local tracking
    _apiMetrics.calls.putIfAbsent(endpoint, () => []).add(...);
    
    // Firebase tracking
    _analytics?.logEvent(
      name: 'api_call',
      parameters: {
        'endpoint': endpoint,
        'success': success,
        'latency_ms': latencyMs,
      },
    );
  }
}
```

#### 2. Sentry (For Error Tracking)

**Why Sentry:**
- **Error tracking**: Comprehensive error and exception tracking
- **Performance monitoring**: APM with transaction tracing
- **Release tracking**: Track errors by app version
- **User context**: Anonymized user session tracking
- **Breadcrumbs**: Automatic event logging for debugging

**Use Case**: Production error tracking and performance monitoring

#### 3. Mixpanel (For Product Analytics)

**Why Mixpanel:**
- **Event tracking**: Detailed user event tracking
- **Funnels**: Conversion funnel analysis
- **Cohorts**: User segmentation and analysis
- **Retention**: User retention metrics

**Use Case**: Product analytics and user behavior analysis

#### 4. Custom Backend (For Full Control)

**Why Custom Backend:**
- **Full control**: Complete ownership of data
- **Custom metrics**: Define exactly what to track
- **Privacy**: Full control over data handling
- **Cost**: No per-event pricing

**Use Case**: Enterprise apps with strict data requirements

### Integration Strategy

We recommend a **hybrid approach**:

1. **Development**: Use local metrics collector for immediate debugging
2. **Staging**: Add Firebase Analytics for real-world testing
3. **Production**: Full integration with Firebase Analytics + Sentry for errors

### Privacy Considerations

- **No PII**: Never track personally identifiable information
- **Anonymization**: Hash or anonymize user identifiers
- **Opt-in**: Consider user consent for analytics (GDPR/CCPA)
- **Data retention**: Set appropriate retention policies
- **Transparency**: Document what is tracked in privacy policy

## Metrics Dashboard

### Development Metrics View

Access via debug menu (long-press on feed screen) → Metrics button.

**Sections:**
1. **Cache Metrics**: Hit rate, hits, misses
2. **API Metrics**: Success rate, latency, endpoint breakdown
3. **Optimistic Metrics**: Action success rates
4. **User Interactions**: Screen views, actions
5. **System Health**: Lifecycle events, connectivity
6. **Errors**: Error counts and types

### Production Metrics

For production, metrics should be:
- Sent to Firebase Analytics (or chosen provider)
- Aggregated in backend for historical analysis
- Visualized in dashboards (Firebase Console, custom dashboards)
- Alerted on anomalies (error spikes, performance degradation)

## Best Practices

### 1. Instrumentation Guidelines

- **Track meaningful events**: Don't over-instrument, focus on actionable metrics
- **Use consistent naming**: Follow naming conventions for events
- **Include context**: Add relevant parameters to events
- **Avoid sensitive data**: Never log passwords, tokens, or PII

### 2. Performance Considerations

- **Async tracking**: Don't block UI thread with metrics
- **Batch events**: Group related events when possible
- **Rate limiting**: Prevent metrics spam
- **Memory management**: Limit in-memory metric storage

### 3. Error Handling

- **Fail gracefully**: Metrics failures shouldn't break app
- **Retry logic**: Retry failed metric submissions
- **Offline support**: Queue metrics when offline, send when online

### 4. Testing

- **Mock metrics**: Use mock metrics collector in tests
- **Verify tracking**: Test that metrics are tracked correctly
- **Performance tests**: Ensure metrics don't impact performance

## Future Enhancements

### Planned Additions

1. **Performance Metrics**:
   - Frame rendering time (FPS)
   - Memory usage
   - Widget build times

2. **Advanced Analytics**:
   - User journey mapping
   - Feature usage heatmaps
   - A/B testing framework

3. **Real-time Monitoring**:
   - Live metrics dashboard
   - Alerting on anomalies
   - Performance regression detection

4. **Export Capabilities**:
   - Export metrics to CSV/JSON
   - Integration with BI tools
   - Custom reporting

## Conclusion

The metrics and observability system provides comprehensive insights into app performance, user behavior, and system health. The lightweight, extensible design allows for easy integration with third-party tools while maintaining privacy and performance standards.

For questions or contributions, see the main [ARCHITECTURE.md](./ARCHITECTURE.md) documentation.

