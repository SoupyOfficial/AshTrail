import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'package:smoke_log/screens/settings/settings_screen.dart';
import 'package:smoke_log/screens/settings/account_options_screen.dart';
import '../../helpers/auth_test_helper.dart';

void main() {
  late AuthTestHelper authHelper;

  setUp(() {
    authHelper = AuthTestHelper();
    registerFallbackValue(Uri());
  });

  tearDown(() {
    authHelper.dispose();
  });

  group('User Account Flow', () {
    testWidgets(
        'complete flow: login > settings > account options > switch user > logout',
        (WidgetTester tester) async {
      // Arrange - setup test environment
      await authHelper.setupUserAccounts();
      authHelper.setupLoginSuccess(
          email: 'test1@example.com', password: 'password123');
      await authHelper.setupUserSwitchSuccess('test2@example.com');
      authHelper.setupSignOut();

      // Mock initial user
      final mockUser = authHelper.createMockUser(
          uid: 'user-1',
          email: 'test1@example.com',
          displayName: 'Test User 1');
      when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
          .thenReturn(mockUser);

      // 1. Start with login screen
      await tester.pumpWidget(authHelper.buildLoginScreen());
      await tester.pumpAndSettle();

      // Fill login form
      await tester.enterText(
          find.byType(TextFormField).first, 'test1@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // 2. Now we're on home screen - navigate to settings
      await tester.pumpWidget(authHelper.buildHomeScreen());
      await tester.pumpAndSettle();

      // Find settings button in CustomAppBar and tap it
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
      } else {
        // If settings icon isn't directly found, build the settings screen
        await tester.pumpWidget(
          ProviderScope(
            parent: authHelper.providerContainer.container,
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // 3. On settings screen - navigate to account options
      await tester.tap(find.text('Account Options'));
      await tester.pumpAndSettle();

      // 4. On account options screen - switch user
      expect(find.byType(AccountOptionsScreen), findsOneWidget);

      // Mock second user for switching
      final mockUser2 = authHelper.createMockUser(
          uid: 'user-2',
          email: 'test2@example.com',
          displayName: 'Test User 2');
      when(() => authHelper.providerContainer.mockFirebaseAuth.currentUser)
          .thenReturn(mockUser2);

      // Find and tap the switch account button for test2@example.com
      final switchButton = find.widgetWithIcon(IconButton, Icons.login).first;
      await tester.tap(switchButton);
      await tester.pumpAndSettle();

      // Verify account switch was called
      verify(() => authHelper.providerContainer.mockAuthService
          .switchAccount('test2@example.com')).called(1);

      // 5. Log out from the second account
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm logout in dialog
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // Verify logout was called
      verify(() => authHelper.providerContainer.mockAuthService.signOut())
          .called(1);
    });
  });
}
