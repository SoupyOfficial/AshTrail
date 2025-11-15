import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/firebase_options.dart';
import 'package:smoke_log/presentation/providers/auth_providers.dart';
import '../helpers/firebase_test_helper.dart';
import '../mocks/auth_service_mock.dart';
import '../services/auth_service_test.dart';

void main() {
  late ProviderContainer container;
  late MockAuthService mockAuthService;

  setUp(() async {
    mockAuthService = MockAuthService();
    // Setup Firebase mocks before all tests
    await FirebaseTestHelper.setupFirebaseMocks();

    container = ProviderContainer(
      overrides: [
        // Override the auth service provider
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    mockAuthService.dispose();
  });

  group('Auth Providers', () {
    test('authStateProvider should emit user when logged in', () async {
      // Arrange - already setup with mockAuthService that has a logged-in user
      final mockFirebaseAuth = MockFirebaseAuth();
      final mockUser = MockUser();
      expect(
          container.read(authStateProvider),
          predicate<AsyncValue<User?>>(
              (value) => value is AsyncData && value.value != null));
      container.dispose(); // Dispose the container after the test
      final localContainer = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        ],
      );

      // Act & Assert
      expect(
          localContainer.read(authStateProvider),
          predicate<AsyncValue<User?>>(
              (value) => value is AsyncData && value.value != null));
    });

    test('userAuthTypeProvider should emit correct auth type', () async {
      // Assume the mock auth service is set up to return a password-based user

      // Act & Assert
      // Wait for the stream to emit a value
      await container.read(userAuthTypeProvider.stream).first;

      expect(
          container.read(userAuthTypeProvider),
          predicate<AsyncValue<String>>(
              (value) => value is AsyncData && value.value == 'password'));
    });

    test('userAccountsProvider should provide user accounts', () async {
      // Act
      final accountsAsync = container.read(userAccountsProvider);

      // Wait for the async value to resolve
      final accounts = accountsAsync.value;

      // Assert
      expect(accounts, isNotEmpty);
      expect(accounts?.first['email'], equals('test@example.com'));
    });
  });
}
