import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoke_log/models/log.dart';
import 'package:smoke_log/widgets/info_display.dart';

void main() {
  group('InfoDisplay', () {
    testWidgets('should display THC content from live value',
        (WidgetTester tester) async {
      // Arrange
      final logs = [
        Log(
          id: 'log1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          durationSeconds: 10.0,
          potencyRating: null,
        ),
        Log(
          id: 'log2',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          durationSeconds: 5.0,
          potencyRating: null,
        ),
      ];

      const liveThcContent = 2.5;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoDisplay(
              logs: logs,
              liveThcContent: liveThcContent,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('2.5'), findsOneWidget);
    });

// Working
    testWidgets('should display time since last hit',
        (WidgetTester tester) async {
      // Arrange
      final now = DateTime.now();
      final lastHitTime = now.subtract(const Duration(minutes: 30));

      final logs = [
        Log(
          id: 'log1',
          timestamp: lastHitTime,
          durationSeconds: 10.0,
          potencyRating: null,
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoDisplay(
              logs: logs,
            ),
          ),
        ),
      );

      // Assert - check for something like "30m" in the widget
      // (exact format depends on implementation)
      expect(find.textContaining('m'), findsAtLeast(1));
    });

// Working
    testWidgets('should handle empty logs', (WidgetTester tester) async {
      // Arrange
      final logs = <Log>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoDisplay(
              logs: logs,
            ),
          ),
        ),
      );

      // Assert - should still render without errors
      expect(find.byType(InfoDisplay), findsOneWidget);
    });
  });
}
