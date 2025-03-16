import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smoke_log/services/auth_service.dart' as auth_service;
import 'package:smoke_log/services/credential_service.dart';
import 'package:smoke_log/providers/auth_provider.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockCredentialService extends Mock implements CredentialService {}

class MockAuthService extends Mock implements auth_service.AuthService {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockProviderRef<T> extends Mock implements Ref<T> {}

// Helper class to setup testing providers
class TestProviderContainer {
  late ProviderContainer container;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockCredentialService mockCredentialService;
  late MockAuthService mockAuthService;

  TestProviderContainer() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockCredentialService = MockCredentialService();
    mockAuthService = MockAuthService();

    // Override providers with mocks
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        credentialServiceProvider.overrideWithValue(mockCredentialService),
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  }

  void dispose() {
    container.dispose();
  }
}
