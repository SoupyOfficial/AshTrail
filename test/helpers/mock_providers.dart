import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smoke_log/services/auth_service.dart' as auth_service;
import 'package:smoke_log/services/credential_service.dart';
import 'package:smoke_log/providers/auth_provider.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockCredentialService extends Mock implements CredentialService {}

class MockAuthService extends Mock implements auth_service.AuthService {}

// Updated to properly extend User instead of being a Map
class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockProviderRef<T> extends Mock implements Ref<T> {}

// Add Firestore mock classes
class MockFirestore extends Mock implements FirebaseFirestore {}

class MockDocumentReference<T extends Object?> extends Mock
    implements DocumentReference<T> {}

class MockDocumentSnapshot<T extends Object?> extends Mock
    implements DocumentSnapshot<T> {}

class MockCollectionReference<T extends Object?> extends Mock
    implements CollectionReference<T> {}

class MockQuerySnapshot<T extends Object?> extends Mock
    implements QuerySnapshot<T> {}

class MockQuery<T extends Object?> extends Mock implements Query<T> {}

// Helper class to setup testing providers
class TestProviderContainer {
  late ProviderContainer container;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockCredentialService mockCredentialService;
  late MockAuthService mockAuthService;
  late MockFirestore mockFirestore;

  TestProviderContainer() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockCredentialService = MockCredentialService();
    mockAuthService = MockAuthService();
    mockFirestore = MockFirestore();

    // Override providers with mocks
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        credentialServiceProvider.overrideWithValue(mockCredentialService),
        authServiceProvider.overrideWithValue(mockAuthService),
        // Add Firestore provider if needed
      ],
    );
  }

  void dispose() {
    container.dispose();
  }
}
