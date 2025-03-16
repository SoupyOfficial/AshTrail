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

      // Mock the userAccountsProvider to return test accounts
      when(() => authHelper.providerContainer.container.read(any()))
          .thenAnswer((_) {
        return const AsyncValue.data([
          {'email': 'other@example.com', 'firstName': 'Other'},
          {'email': 'another@example.com', 'firstName': 'Another'}
        ]);
      });

      // Create a function to track selections
      String? selectedEmail;
      void onUserSelected(String email) {
        selectedEmail = email;
      }

      // Act - build the user account selector widget
      await tester.pumpWidget(
        ProviderScope(
          parent: authHelper.providerContainer.container,
          child: MaterialApp(
            home: Scaffold(
              body: UserAccountSelector(
                currentEmail: 'test@example.com',
                onUserSelected: onUserSelected,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - verify accounts are displayed
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Another'), findsOneWidget);

      // Tap on an account
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Verify selection was made
      expect(selectedEmail, 'other@example.com');
    });

    testWidgets('should show message when no other accounts available',
        (WidgetTester tester) async {
      // Arrange - setup with no other accounts
      when(() => authHelper.providerContainer.container.read(any()))
          .thenAnswer((_) {
        return AsyncValue.data([
          {'email': 'test@example.com', 'firstName': 'Current'},
        ]);
      });

      // Act - build the widget
      await tester.pumpWidget(
        ProviderScope(
          parent: authHelper.providerContainer.container,
          child: MaterialApp(
            home: Scaffold(
              body: UserAccountSelector(
                currentEmail: 'test@example.com',
                onUserSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - verify empty state message is shown
      expect(find.text('No other accounts available to transfer to'),
          findsOneWidget);
    });
  });
}
