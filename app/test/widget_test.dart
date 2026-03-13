import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_companion_orb/app.dart';

void main() {
  testWidgets('App smoke test - app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrbApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrbApp()));
    await tester.pump();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'AI Companion Orb');
  });
}
