import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/widgets/user_account_selector.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/widget_test_helper.dart';

void main() {
  late AuthTestHelper authHelper;
  late WidgetTestHelper widgetHelper;

  setUp(() {
    authHelper = AuthTestHelper();
    widgetHelper = WidgetTestHelper();
    registerFallbackValue(Uri());
  });

  tearDown(() {
    authHelper.dispose();
    widgetHelper.dispose();
  });

  group('UserAccountSelector Widget', () {
    testWidgets('should display available accounts',
        (WidgetTester tester) async {
      // Arrange - setup user accounts
      await authHelper.setupUserAccounts();

      // Mock the userAccountsProvider to return test accounts with firstName
      when(() => authHelper.providerContainer.container.read(any()))
          .thenAnswer((_) {
        return const AsyncValue.data([
          {
            'email': 'other@example.com',
            'firstName': 'Other',
            'userId': 'user-2',
            'hasUniqueName': true
          }
        ]);
      });

      // Build the widget under test with a current email and callback
      await tester.pumpWidget(
        ProviderScope(
          parent: authHelper.providerContainer.container,
          child: MaterialApp(
            home: UserAccountSelector(
              currentEmail: 'test@example.com',
              onUserSelected: (email) {
                // This is a callback for testing
                expect(email, 'other@example.com');
              },
            ),
          ),
        ),
      );

      // Wait for widget to build
      await tester.pumpAndSettle();

      // Verify UI shows the account
      expect(find.text('Other'), findsOneWidget);

      // Tap on the user to select
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Verification happens in the callback above
    });
  });
}
