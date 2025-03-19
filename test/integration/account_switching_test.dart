import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/screens/settings/account_options_screen.dart';
import 'package:smoke_log/providers/consolidated_auth_provider.dart'
    as consolidated;
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/utils/auth_operations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Create mocks
class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements firebase_auth.User {}

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

void main() {
  late MockAuthService mockAuthService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockCurrentUser;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockCurrentUser = MockUser();

    // Configure default mock behavior
    when(() => mockCurrentUser.email).thenReturn('current@example.com');
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockCurrentUser);

    when(() => mockAuthService.switchAccount(any())).thenAnswer((_) async {});
    when(() => mockAuthService.signOut())
        .thenAnswer((_) async => SignOutResult.fullySignedOut);

    // Override providers for testing
    container = ProviderContainer(
      overrides: [
        consolidated.authServiceProvider.overrideWithValue(mockAuthService),
        consolidated.firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        consolidated.enrichedAccountsProvider.overrideWith(
          (ref) async => [
            {
              'userId': '1',
              'email': 'current@example.com',
              'firstName': 'Current',
              'authType': 'password',
              'hasUniqueName': true,
            },
            {
              'userId': '2',
              'email': 'other@example.com',
              'firstName': 'Other',
              'authType': 'google',
              'hasUniqueName': true,
            },
          ],
        ),
        consolidated.authStateProvider.overrideWith(
          (ref) => Stream.value(mockCurrentUser),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  testWidgets('AccountOptionsScreen displays accounts and allows switching',
      (WidgetTester tester) async {
    // Build the AccountOptionsScreen with overridden providers
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: const MaterialApp(
          home: AccountOptionsScreen(),
        ),
      ),
    );

    // Verify accounts are displayed
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Current Account'), findsOneWidget);

    // Tap on the other account to switch
    await tester.tap(find.byIcon(Icons.login).first);
    await tester.pumpAndSettle();

    // Verify the switch account method was called
    verify(() => mockAuthService.switchAccount('other@example.com')).called(1);
  });

  testWidgets('AccountOptionsScreen handles logout correctly',
      (WidgetTester tester) async {
    // Build the AccountOptionsScreen with overridden providers
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: const MaterialApp(
          home: AccountOptionsScreen(),
        ),
      ),
    );

    // Find and tap the logout button
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    // Verify the confirmation dialog appears
    expect(find.text('Confirm Logout'), findsOneWidget);
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);

    // Tap the "Logout" button in the dialog
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    // Verify signOut was called
    verify(() => mockAuthService.signOut()).called(1);
  });
}
