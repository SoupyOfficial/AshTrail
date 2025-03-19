import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/utils/auth_operations.dart';
import 'package:smoke_log/services/credential_service.dart';
import 'package:smoke_log/providers/consolidated_auth_provider.dart'
    as consolidated;

// Create mocks
class MockAuthService extends Mock implements AuthService {}

class MockCredentialService extends Mock implements CredentialService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late MockAuthService mockAuthService;
  late MockCredentialService mockCredentialService;
  late ProviderContainer container;
  late MockNavigatorObserver navigatorObserver;

  setUp(() {
    mockAuthService = MockAuthService();
    mockCredentialService = MockCredentialService();
    navigatorObserver = MockNavigatorObserver();

    // Override providers for testing
    container = ProviderContainer(
      overrides: [
        consolidated.authServiceProvider.overrideWithValue(mockAuthService),
        consolidated.credentialServiceProvider
            .overrideWithValue(mockCredentialService),
      ],
    );

    // Set up default behavior for mocks
    when(() => mockCredentialService.getUserAccounts())
        .thenAnswer((_) async => [
              {
                'userId': '1',
                'email': 'user1@example.com',
                'authType': 'password'
              },
              {
                'userId': '2',
                'email': 'user2@example.com',
                'authType': 'google'
              },
            ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthOperations.switchAccount', () {
    testWidgets('successfully switches user account',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthService.switchAccount('user2@example.com'))
          .thenAnswer((_) async {});

      // Build simple widget for testing
      await tester.pumpWidget(ProviderScope(
          parent: container,
          child: MaterialApp(
            home: ProviderScope(
              parent: container,
              child: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => AuthOperations.switchAccount(
                        context, ref, 'user2@example.com'),
                    child: const Text('Switch Account'),
                  );
                },
              ),
            ),
            navigatorObservers: [navigatorObserver],
          )));

      // Act
      await tester.tap(find.text('Switch Account'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockAuthService.switchAccount('user2@example.com'))
          .called(1);
    });
  });

  group('AuthOperations.logout', () {
    testWidgets('handles full sign out', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthService.signOut())
          .thenAnswer((_) async => SignOutResult.fullySignedOut);

      // Build simple widget for testing
      await tester.pumpWidget(ProviderScope(
          parent: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () async {
                  final result = await AuthOperations.logout(context, ref);
                  // Store result for verification
                  container.read(consolidated.authTypeProvider.notifier).state =
                      result == SignOutResult.fullySignedOut
                          ? 'full'
                          : 'switched';
                },
                child: const Text('Logout'),
              ),
            ),
          )));

      // Act
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockAuthService.signOut()).called(1);
      expect(container.read(consolidated.authTypeProvider), 'full');
    });

    testWidgets('handles switching to another account',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthService.signOut())
          .thenAnswer((_) async => SignOutResult.switchedToAnotherUser);

      // Build simple widget for testing
      await tester.pumpWidget(ProviderScope(
          parent: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () async {
                  final result = await AuthOperations.logout(context, ref);
                  // Store result for verification
                  container.read(consolidated.authTypeProvider.notifier).state =
                      result == SignOutResult.fullySignedOut
                          ? 'full'
                          : 'switched';
                },
                child: const Text('Logout'),
              ),
            ),
          )));

      // Act
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockAuthService.signOut()).called(1);
      expect(container.read(consolidated.authTypeProvider), 'switched');
    });
  });
}
