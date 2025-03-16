import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smoke_log/screens/settings/account_options_screen.dart';
import 'package:smoke_log/theme/theme_provider.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import 'package:smoke_log/providers/sync_provider.dart'; // Add this import
import 'package:smoke_log/services/sync_service.dart'; // Add this import
import '../helpers/auth_test_helper.dart';
import '../helpers/widget_test_helper.dart';

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
      displayName: 'Test User 1',
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

    return ProviderScope(
      parent: authHelper.providerContainer.container,
      overrides: [
        // Override the user accounts provider with test data
        userAccountsProvider.overrideWith((ref) async {
          return await authHelper.getUserAccounts();
        }),

        // Override authStateProvider by properly returning a stream
        authStateProvider.overrideWith(
          (ref) => Stream.value(mockUser),
        ),

        // If userAuthTypeProvider is also being used, override it too
        userAuthTypeProvider.overrideWith((ref) => Stream.value('password')),

        // Override sync status provider
        syncStatusProvider.overrideWith((ref) => mockSyncStatus.stream),

        // Any other providers that might be used
      ],
      child: provider.ChangeNotifierProvider<ThemeProvider>.value(
        value: mockThemeProvider,
        child: const MaterialApp(
          home: AccountOptionsScreen(),
        ),
      ),
    );
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
      expect(find.textContaining('test'), findsWidgets);
    });

    testWidgets('should allow switching between accounts',
        (WidgetTester tester) async {
      // Arrange - setup multiple user accounts and user switching
      await authHelper.setupUserAccounts();
      final mockUser = authHelper.createMockUser(
        uid: 'user-1',
        email: 'test1@example.com',
        displayName: 'Test User 1',
      );
      when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
          .thenReturn(mockUser);

      await authHelper.setupUserSwitchSuccess('test2@example.com');

      // Act - build the account options screen
      await tester.pumpWidget(buildAccountOptionsScreen());
      await tester.pumpAndSettle();

      // Find User2's switch button (should have login icon)
      final switchButton = find.widgetWithIcon(IconButton, Icons.login).first;
      await tester.tap(switchButton);
      await tester.pumpAndSettle();

      // Assert - verify account was switched
      verify(() => authHelper.providerContainer.mockAuthService
          .switchAccount('test2@example.com')).called(1);
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

      // Find and tap Confirm in dialog
      expect(find.text('Confirm Logout'), findsOneWidget);
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // Assert - verify logout was called
      verify(() => authHelper.providerContainer.mockAuthService.signOut())
          .called(1);
    });
  });
}
