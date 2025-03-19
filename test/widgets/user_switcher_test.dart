import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoke_log/widgets/user_switcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  group('UserSwitcher Widget', () {
    testWidgets('displays current user correctly', (WidgetTester tester) async {
      // Arrange
      final accounts = [
        {
          'email': 'user1@example.com',
          'firstName': 'John',
          'authType': 'password',
          'hasUniqueName': true,
        },
        {
          'email': 'user2@example.com',
          'firstName': 'Mike',
          'authType': 'google',
        },
      ];

      bool switchCalled = false;
      String? switchedToEmail;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserSwitcher(
              accounts: accounts,
              currentEmail: 'user1@example.com',
              onSwitchAccount: (email) {
                switchCalled = true;
                switchedToEmail = email;
              },
              authType: 'password',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('John'),
          findsOneWidget); // Shows the firstName for current user

      // Test dropdown interaction
      await tester.tap(find.byType(UserSwitcher));
      await tester.pumpAndSettle();

      // Menu items should appear
      expect(find.text('Mike'), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.google), findsOneWidget);
      expect(find.text('Add Account'), findsOneWidget);

      // Test switching account
      await tester.tap(find.text('Mike'));
      await tester.pumpAndSettle();

      expect(switchCalled, isTrue);
      expect(switchedToEmail, 'user2@example.com');
    });

    testWidgets('handles duplicate first names correctly',
        (WidgetTester tester) async {
      // Arrange
      final accounts = [
        {
          'email': 'john@example.com',
          'firstName': 'John',
          'authType': 'password',
        },
        {
          'email': 'john.doe@example.com',
          'firstName': 'John',
          'authType': 'google',
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserSwitcher(
              accounts: accounts,
              currentEmail: 'john@example.com',
              onSwitchAccount: (_) {},
              authType: 'password',
            ),
          ),
        ),
      );

      // Assert - should use email instead of firstName since there are duplicates
      expect(find.text('john@example.com'), findsOneWidget);

      // Open the dropdown
      await tester.tap(find.byType(UserSwitcher));
      await tester.pumpAndSettle();

      // Both emails should be displayed instead of first names
      expect(find.text('john@example.com'),
          findsNWidgets(2)); // One in dropdown button, one in menu
      expect(find.text('john.doe@example.com'), findsOneWidget);
    });

    testWidgets('adds current user if not in accounts list',
        (WidgetTester tester) async {
      // Arrange
      final accounts = [
        {
          'email': 'user1@example.com',
          'firstName': 'John',
          'authType': 'password',
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserSwitcher(
              accounts: accounts,
              currentEmail: 'current@example.com', // Not in the accounts list
              onSwitchAccount: (_) {},
              authType: 'google',
            ),
          ),
        ),
      );

      // Assert - should display the current email
      expect(find.text('current@example.com'), findsOneWidget);

      // Open the dropdown
      await tester.tap(find.byType(UserSwitcher));
      await tester.pumpAndSettle();

      // Both accounts should be visible
      expect(find.text('John'), findsOneWidget);
      expect(find.text('current@example.com'),
          findsNWidgets(2)); // One in dropdown button, one in menu
    });

    testWidgets('handles empty accounts list', (WidgetTester tester) async {
      // Arrange
      final accounts = <Map<String, dynamic>>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserSwitcher(
              accounts: accounts,
              currentEmail: 'current@example.com',
              onSwitchAccount: (_) {},
              authType: 'password',
            ),
          ),
        ),
      );

      // Assert - should be an empty SizedBox
      expect(find.byType(UserSwitcher), findsOneWidget);
      expect(find.byType(PopupMenuButton), findsNothing);
    });
  });
}
