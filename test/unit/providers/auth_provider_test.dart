import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import '../../helpers/mock_providers.dart';

void main() {
  late TestProviderContainer testContainer;

  setUp(() {
    testContainer = TestProviderContainer();

    // Register fallbacks for when/verify methods
    registerFallbackValue(MockUser());
  });

  tearDown(() {
    testContainer.dispose();
  });

  group('authStateProvider', () {
    test('should emit null when not signed in', () async {
      // Arrange
      final authStateStream = Stream<User?>.value(null);
      when(() => testContainer.mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authStateStream);

      // Act
      final result = testContainer.container.read(authStateProvider);

      // Assert
      expect(result.value, null);
    });

    test('should emit User when signed in', () async {
      // Arrange
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test-uid');
      final authStateStream = Stream<User?>.value(mockUser);
      when(() => testContainer.mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authStateStream);

      // Act & Assert
      final states = <AsyncValue<User?>>[];
      final subscription = testContainer.container.listen(
        authStateProvider,
        (_, state) => states.add(state),
      );

      await Future.delayed(Duration(milliseconds: 50));
      subscription.close();

      // We might see loading state first, then data
      expect(states.last.value, mockUser);
    });
  });

  group('userAuthTypeProvider', () {
    test('should emit null when user is null', () async {
      // Arrange
      final authStateStream = Stream<User?>.value(null);
      when(() => testContainer.mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authStateStream);

      // Act
      final result = testContainer.container.read(userAuthTypeProvider);

      // Assert
      expect(result.value, null);
    });

    // Additional tests for Google and password auth types would go here
  });
}
