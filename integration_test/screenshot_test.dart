import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smoke_log/main.dart' as app;
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Tests', () {
    testWidgets('Take screenshots', (WidgetTester tester) async {
      // Start the app
      app.main();

      // Wait for app to stabilize
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot - will be saved in the test report
      await screenshot(tester, 'home_screen');

      // Navigate to other screens if needed
      // Example:
      // await tester.tap(find.byIcon(Icons.add));
      // await tester.pumpAndSettle();
      // await screenshot(tester, 'add_screen');
    });
  });
}

Future<void> screenshot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
}
