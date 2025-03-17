import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smoke_log/providers/user_account_provider.dart';
import 'package:smoke_log/screens/settings/account_options_screen.dart';
import 'package:smoke_log/theme/theme_provider.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import 'package:smoke_log/providers/sync_provider.dart';
import 'package:smoke_log/services/sync_service.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/widget_test_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock ThemeProvider for testing
class MockThemeProvider extends Mock implements ThemeProvider {
  @override
  bool get isDarkMode => false;

  @override
  Color get accentColor => Colors.blue;
}

void main() {
  late AuthTestHelper authHelper;
  late ThemeProvider mockThemeProvider;

  setUp(() {
    authHelper = AuthTestHelper();
    mockThemeProvider = MockThemeProvider();
    registerFallbackValue(Uri());
  });

  tearDown(() {
    authHelper.dispose();
  });

  // Helper method to build the widget under test with comprehensive provider overrides
  Widget buildAccountOptionsScreen() {
    // Create a mock user for testing
    final mockUser = authHelper.createMockUser(
      uid: 'user-1',
      email: 'test1@example.com',
      firstName: 'Test User',
    );

    // Set the mock user as current user in Firebase Auth mock
    when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
        .thenReturn(mockUser);

    // Create a StreamController for authState updates
    final authStateController = StreamController<User?>.broadcast();
    authStateController.add(mockUser);
    when(() => authHelper.providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => authStateController.stream);

    // Create a mock sync service
    final mockSyncStatus = StreamController<SyncStatus>.broadcast();
    mockSyncStatus.add(SyncStatus.synced); // Default to synced state

    // Mock enriched accounts data that includes firstName and hasUniqueName
    final enrichedAccounts = [
      {
        'userId': 'user-1',
        'email': 'test1@example.com',
        'firstName': 'Test User',
        'lastName': 'User',
        'authType': 'password',
        'hasUniqueName': true
      },
      {
        'userId': 'user-2',
        'email': 'test2@example.com',
        'firstName': 'Other User',
        'lastName': 'User',
        'authType': 'password',
        'hasUniqueName': true
      }
    ];

    return ProviderScope(
      parent: authHelper.providerContainer.container,
      overrides: [
        // Override the basic user accounts provider
        userAccountsProvider.overrideWith((ref) async {
          final userAccounts = await authHelper.getUserAccounts();
          debugPrint('User accounts: ${userAccounts.first}');
          return userAccounts;
        }),

        // Override the enriched accounts provider with pre-enriched data
        enrichedAccountsProvider.overrideWith((ref) async {
          return enrichedAccounts;
        }),

        // Override authStateProvider by properly returning a stream
        authStateProvider.overrideWith(
          (ref) => Stream.value(mockUser),
        ),
        authServiceProvider.overrideWithValue(
          authHelper.providerContainer.mockAuthService,
        ),

        // If userAuthTypeProvider is also being used, override it too
        userAuthTypeProvider.overrideWith((ref) => Stream.value('password')),

        // Override sync status provider
        syncStatusProvider.overrideWith((ref) => mockSyncStatus.stream),
      ],
      child: provider.ChangeNotifierProvider<ThemeProvider>.value(
        value: mockThemeProvider,
        child: const MaterialApp(
          home: AccountOptionsScreen(),
        ),
      ),
    );
  }

  // Helper method to print all text and button widgets on screen
  void printUIState(WidgetTester tester, String label) {
    print('\n=== UI STATE: $label ===');

    // Print all text widgets
    print('Text elements:');
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final text in textWidgets) {
      print('- "${text.data}"');
    }

    // Print all buttons
    print('Button elements:');
    var textButtons = tester.widgetList<TextButton>(find.byType(TextButton));
    for (final button in textButtons) {
      final buttonChild = button.child;
      if (buttonChild is Text) {
        print('- TextButton: "${buttonChild.data}"');
      }
    }

    // Print all icon buttons
    print('Button elements:');
    textButtons = tester.widgetList<TextButton>(find.byType(TextButton));
    for (final button in textButtons) {
      final buttonChild = button.child;
      if (buttonChild is Text) {
        print('- TextButton: "${buttonChild.data}"');
      }
    }

    // Print all icon buttons
    final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
    for (final button in iconButtons) {
      print(
          '- IconButton: ${button.icon is Icon ? (button.icon as Icon).icon : "unknown"}');
    }

    // Print list items if any
    print('ListView items:');
    final listViews = find.byType(ListView);
    if (listViews.evaluate().isNotEmpty) {
      print(
          '- Found ${tester.widgetList(find.byType(ListTile)).length} list tiles');
    }

    print('==============================\n');
  }

  group('AccountOptionsScreen', () {
    testWidgets('should display user accounts', (WidgetTester tester) async {
      // Arrange - setup multiple user accounts
      await authHelper.setupUserAccounts();

      // Act - build the account options screen
      await tester.pumpWidget(buildAccountOptionsScreen());

      // Give time for async operations to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Assert - verify screen structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Verify account information is displayed
      expect(find.text('Your Accounts'), findsOneWidget);
      expect(
          find.text('Test User'), findsOneWidget); // Now looking for firstName
    });

    testWidgets('should handle logout', (WidgetTester tester) async {
      // Arrange - setup user accounts and signout
      await authHelper.setupUserAccounts();
      final mockUser = authHelper.createMockUser();
      when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
          .thenReturn(mockUser);
      authHelper.setupSignOut();

      // Act - build the account options screen
      await tester.pumpWidget(buildAccountOptionsScreen());
      await tester.pumpAndSettle();

      // Find and tap Logout button
      expect(find.text('Logout'), findsOneWidget);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify the dialog is displayed
      expect(find.text('Confirm Logout'), findsOneWidget);

      // Find and tap Confirm in dialog
      expect(find.text('Confirm Logout'), findsOneWidget);
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // Assert - verify logout was called
      verify(() => authHelper.providerContainer.mockAuthService.signOut())
          .called(1);
    });

    testWidgets('should sign out and switch to another account when available',
        (WidgetTester tester) async {
      // Arrange
      authHelper.setupSignOutAndSwitch();

      // Act - build the account options screen
      await tester.pumpWidget(
        ProviderScope(
          parent: authHelper.providerContainer.container,
          child: MaterialApp(
            home: const AccountOptionsScreen(),
          ),
        ),
      );

      // Find and tap the logout button
      await tester.tap(find.text('Logout'));
      await tester.pump();

      // Confirm in the dialog
      await tester.tap(find.text('Logout').last);
      await tester.pump();

      // Assert
      verify(() => authHelper.providerContainer.mockFirebaseAuth.signOut())
          .called(1);
      verify(() => authHelper.providerContainer.mockFirebaseAuth
              .signInWithEmailAndPassword(
            email: 'another@example.com',
            password: 'password123',
          )).called(1);
    });

    testWidgets('should handle logout and switch to another user',
        (WidgetTester tester) async {
      // Arrange - setup user accounts
      await authHelper.setupUserAccounts();

      // Set first user as active initially
      final initialUser = await authHelper.setActiveUser('test1@example.com');

      // Build the widget with the first user active
      await tester.pumpWidget(buildAccountOptionsScreen());
      await tester.pumpAndSettle();

      // Print initial UI state
      printUIState(tester, 'BEFORE LOGOUT');

      // Verify initial state - the first user should be displayed
      expect(find.text('Test User'), findsOneWidget,
          reason: 'Should find the first user initially');
      expect(find.text('Second User'), findsNothing,
          reason: 'Should not find the second user initially');

      // Set up what happens after logout
      // We want to simulate a complete logout, so no user should be active
      when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
          .thenReturn(null);

      when(() => authHelper.providerContainer.mockAuthService.signOut())
          .thenAnswer((_) async {
        print('*** signOut method called ***');
        // After logout, there should be no active user
        when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
            .thenReturn(null);

        // Auth state stream should emit null
        final controller = StreamController<User?>();
        when(() => authHelper.providerContainer.mockFirebaseAuth
            .authStateChanges()).thenAnswer((_) => controller.stream);
        controller.add(null);
      });

      // Logout process
      final logoutButton = find.text('Logout');
      expect(logoutButton, findsOneWidget,
          reason: 'Logout button should be present');
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Confirm logout in dialog
      final confirmDialog = find.text('Confirm Logout');
      expect(confirmDialog, findsOneWidget,
          reason: 'Confirm dialog should be shown');

      // Print UI state during dialog
      printUIState(tester, 'DURING LOGOUT DIALOG');

      // Tap the confirm button in dialog
      final confirmButton = find.text('Logout').last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Now the user should be logged out
      // Verify auth service signOut was called
      verify(() => authHelper.providerContainer.mockAuthService.signOut())
          .called(1);

      // Check current user is null
      expect(authHelper.providerContainer.mockFirebaseAuth.currentUser, isNull,
          reason: 'Current user should be null after logout');

      // Rebuild the widget with null user
      await tester.pumpWidget(buildAccountOptionsScreen());
      await tester.pumpAndSettle();

      // Print UI state after logout
      printUIState(tester, 'AFTER LOGOUT');

      // Here we should see a login screen or some indication that we're logged out
      // This depends on how your app handles no authenticated user
      expect(find.text('Test User'), findsNothing,
          reason: 'First user should not be found after logout');
    });
  });
}
