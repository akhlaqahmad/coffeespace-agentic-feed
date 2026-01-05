import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coffeespace_agentic_feed/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Wait for initial load
    await tester.pumpAndSettle();

    // Check that the app loads (feed screen should be visible)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
