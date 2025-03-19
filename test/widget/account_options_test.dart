import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smoke_log/providers/log_providers.dart';
import 'package:smoke_log/providers/user_account_provider.dart';
import 'package:smoke_log/screens/settings/account_options_screen.dart';
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/theme/theme_provider.dart';
import 'package:smoke_log/utils/auth_operations.dart';
import 'package:smoke_log/providers/consolidated_auth_provider.dart'
    as consolidated;
import 'package:smoke_log/providers/sync_provider.dart';
import 'package:smoke_log/services/sync_service.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/widget_test_helper.dart';

// Mock ThemeProvider for testing
class MockThemeProvider extends Mock implements ThemeProvider {
  @override
  bool get isDarkMode => false;

  @override
  Color get accentColor => Colors.blue;
}

// Mock BuildContext for direct AuthOperations testing
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late AuthTestHelper authHelper;
  late ThemeProvider mockThemeProvider;

  setUp(() {
    authHelper = AuthTestHelper();
    mockThemeProvider = MockThemeProvider();
    registerFallbackValue(Uri());
    registerFallbackValue(MockBuildContext());
    registerFallbackValue(ProviderContainer());
  });

  tearDown(() {
    authHelper.dispose();

    // Ensure proper disposal of LogRepository and SyncService
    final logRepository =
        authHelper.providerContainer.container.read(logRepositoryProvider);
    logRepository.dispose();
    // Ensure any additional cleanup if necessary
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
        // Override both auth providers - consolidated and legacy
        consolidated.userAccountsProvider.overrideWith((ref) async {
          return [
            {
              'userId': 'user-1',
              'email': 'test1@example.com',
              'authType': 'password'
            },
            {
              'userId': 'user-2',
              'email': 'test2@example.com',
              'authType': 'password'
            }
          ];
        }),

        // Override the enriched accounts provider with pre-enriched data
        consolidated.enrichedAccountsProvider.overrideWith((ref) async {
          return enrichedAccounts;
        }),

        // Override authStateProvider by properly returning a stream
        consolidated.authStateProvider.overrideWith(
          (ref) => Stream.value(mockUser),
        ),

        // Legacy auth provider overrides for backward compatibility
        userAccountsProvider.overrideWith((ref) async {
          final userAccounts = await authHelper.getUserAccounts();
          return userAccounts;
        }),

        // Override sync service provider to ensure proper disposal
        syncServiceProvider.overrideWith((ref) {
          final mockSyncService = SyncService.empty();
          ref.onDispose(() {
            mockSyncService.stopPeriodicSync(); // Ensure the timer is stopped
            mockSyncService.dispose(); // Dispose of the SyncService
          });
          return mockSyncService;
        }),

        // Override sync status provider
        syncStatusProvider
            .overrideWith((ref) => ref.watch(syncServiceProvider).syncStatus),
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
      expect(find.text('Test User'), findsOneWidget); // Looking for firstName
    });

    testWidgets('should handle logout with AuthOperations',
        (WidgetTester tester) async {
      // Arrange - setup user accounts and signout
      await authHelper.setupUserAccounts();
      final mockUser = authHelper.createMockUser();

      // Configure mock result for signOut with the enum value
      when(() => authHelper.providerContainer.mockAuthService.signOut())
          .thenAnswer((_) async => SignOutResult.fullySignedOut);

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
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // Assert - verify logout was called
      verify(() => authHelper.providerContainer.mockAuthService.signOut())
          .called(1);
    });

    testWidgets(
        'should sign out and switch to another account using AuthOperations',
        (WidgetTester tester) async {
      // Arrange
      when(() => authHelper.providerContainer.mockAuthService.signOut())
          .thenAnswer((_) async => SignOutResult.switchedToAnotherUser);

      // Setup for switchAccount
      when(() =>
              authHelper.providerContainer.mockAuthService.switchAccount(any()))
          .thenAnswer((_) async => {});

      // Act - build the account options screen with our helper
      await tester.pumpWidget(buildAccountOptionsScreen());
      await tester.pumpAndSettle();

      // Find and tap on another account to switch
      final switchIcon = find.byIcon(Icons.login).first;
      expect(switchIcon, findsOneWidget,
          reason: "Switch account icon should be visible");
      await tester.tap(switchIcon);
      await tester.pumpAndSettle();

      // Verify switchAccount was called
      verify(() =>
              authHelper.providerContainer.mockAuthService.switchAccount(any()))
          .called(1);

      // Now try logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm in the dialog
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // Verify signOut was called
      verify(() => authHelper.providerContainer.mockAuthService.signOut())
          .called(1);
    });

    testWidgets('should handle switching to another user directly',
        (WidgetTester tester) async {
      // Arrange - setup user accounts
      await authHelper.setupUserAccounts();

      // Set first user as active initially with correct Auth operations return type
      when(() =>
              authHelper.providerContainer.mockAuthService.switchAccount(any()))
          .thenAnswer((_) async => {});

      // Build the widget with the first user active
      await tester.pumpWidget(buildAccountOptionsScreen());
      await tester.pumpAndSettle();

      // Verify initial state - the first user should be displayed
      expect(find.text('Test User'), findsOneWidget,
          reason: 'Should find the first user initially');

      // Find and tap the switch account button for the second user
      final switchIcon = find.byIcon(Icons.login).first;
      expect(switchIcon, findsOneWidget);
      await tester.tap(switchIcon);
      await tester.pumpAndSettle();

      // Verify switchAccount was called with the right email
      verify(() =>
              authHelper.providerContainer.mockAuthService.switchAccount(any()))
          .called(1);
    });
  });
}
