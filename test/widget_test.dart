import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coffeespace_agentic_feed/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to CoffeeSpace'), findsOneWidget);
    expect(find.text('CoffeeSpace Agentic Feed'), findsOneWidget);
  });
}
