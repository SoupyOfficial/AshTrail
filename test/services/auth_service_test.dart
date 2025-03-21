import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/services/credential_service.dart';
import '../mocks/auth_service_mock.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockCredentialService extends Mock implements CredentialService {}

class MockProviderRef extends Mock implements ProviderRef<dynamic> {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockCredentialService mockCredentialService;
  late MockProviderRef mockProviderRef;
  late ProviderContainer container;
  late AuthService authService;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockCredentialService = MockCredentialService();
    mockProviderRef = MockProviderRef();
    container = ProviderContainer();

    authService = AuthService(
      mockFirebaseAuth,
      mockGoogleSignIn,
      mockCredentialService,
      mockProviderRef,
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthService', () {
    test('should stream auth state changes', () async {
      // Arrange
      final mockUser = MockUser();
      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));

      // Act & Assert
      expect(authService.authStateChanges, emits(isA<User>()));
    });

    test('should sign in with email and password', () async {
      // Arrange
      final mockUserCredential = MockUserCredential(MockUser());
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      )).thenAnswer((_) => Future.value(mockUserCredential));

      // Act
      final result = await authService.signInWithEmailAndPassword(
        'test@example.com',
        'password',
      );

      // Assert
      expect(result, equals(mockUserCredential));
      verify(mockCredentialService.saveUserAccount(
        result.user!,
        password: 'password',
        authType: 'password',
      )).called(1);
    });

    test('should throw exception for invalid credentials', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrong',
      )).thenThrow(FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid',
      ));

      // Act & Assert
      expect(
        () =>
            authService.signInWithEmailAndPassword('test@example.com', 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    // Additional tests for Google/Apple sign-in, switch account, etc.
  });
}
