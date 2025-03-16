import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_providers.dart';

class WidgetTestHelper {
  late TestProviderContainer providerContainer;

  WidgetTestHelper() {
    providerContainer = TestProviderContainer();
  }

  Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  Widget wrapWithProviderScope(Widget child) {
    return ProviderScope(
      parent: providerContainer.container,
      child: wrapWithMaterialApp(child),
    );
  }

  // Helper for common finder expectations
  Future<void> expectFindsWidgetByText(
    WidgetTester tester,
    String text,
  ) async {
    expect(find.text(text), findsOneWidget);
  }

  // Helper for common tap actions
  Future<void> tapByKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  void dispose() {
    providerContainer.dispose();
  }
}
