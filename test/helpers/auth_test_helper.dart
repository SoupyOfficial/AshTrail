import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import 'package:smoke_log/services/credential_service.dart';
import 'package:smoke_log/screens/login_screen.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../unit/services/auth_account_service_test.dart' as auth_account;
import 'mock_providers.dart';

class AuthTestHelper {
  late TestProviderContainer providerContainer;
  late MockFirestore mockFirestore;

  // Mock user accounts for testing
  final List<Map<String, String>> _testAccounts = [
    {
      'userId': 'user-1',
      'email': 'test1@example.com',
      'firstName': 'Test',
      'lastName': 'User',
      'authType': 'password',
      'password': 'password123'
    },
    {
      'userId': 'user-2',
      'email': 'test2@example.com',
      'firstName': 'User2',
      'lastName': 'User2',
      'authType': 'password',
      'password': 'password123'
    },
    {
      'userId': 'user-3',
      'email': 'test3@example.com',
      'firstName': 'Google',
      'lastName': 'User',
      'authType': 'google',
      'password': ''
    }
  ];

  Future<List<Map<String, String>>> getUserAccounts() async => _testAccounts;

  Future<Map<String, String>> getFirstUser() async => _testAccounts.first;

  AuthTestHelper() {
    providerContainer = TestProviderContainer();
    mockFirestore = MockFirestore();
  }

  // Create a test user with both Auth data and Firestore data
  auth_account.MockUser createMockUser({
    String uid = 'user-1',
    String email = 'test@example.com',
    String firstName = 'Test User',
    String? lastName,
  }) {
    final mockUser = auth_account.MockUser();

    // Setup Firebase Auth user properties
    when(() => mockUser.uid).thenReturn(uid);
    when(() => mockUser.email).thenReturn(email);

    // Firebase Auth User might have displayName (but our app uses firstName from Firestore)
    final displayName =
        [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    when(() => mockUser.displayName).thenReturn(displayName);

    // Always set up the auth state stream when creating a mock user
    final controller = StreamController<User?>.broadcast();
    controller.add(mockUser);
    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);

    // Setup mock Firestore document for this user
    final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockUserDoc = MockDocumentReference<Map<String, dynamic>>();

    // Mock data that would be in the Firestore document
    final userData = {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': Timestamp.now(),
      'lastLoginAt': Timestamp.now(),
      'isActive': true,
    };

    when(() => mockDocSnapshot.data()).thenReturn(userData);
    when(() => mockDocSnapshot.exists).thenReturn(true);
    when(() => mockDocSnapshot.id).thenReturn(uid);

    when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
    when(() => mockFirestore.collection('users').doc(uid))
        .thenReturn(mockUserDoc);

    return mockUser;
  }

  // Setup user accounts for testing
  Future<void> setupUserAccounts() async {
    // Convert test accounts to the format expected by CredentialService
    final accounts = _testAccounts
        .map((account) => {
              'userId': account['userId'],
              'email': account['email'],
              'firstName': account['firstName'],
              'authType': account['authType'],
              if (account['password'] != null) 'password': account['password'],
            })
        .toList();

    // Mock credential service to return these accounts
    when(() => providerContainer.mockCredentialService.getUserAccounts())
        .thenAnswer((_) async => accounts.cast<Map<String, String>>());

    // Set first user as active
    when(() => providerContainer.mockCredentialService.getActiveUserId())
        .thenAnswer((_) async => accounts.first['userId']);

    // Setup mock Firestore documents for each account
    for (final account in _testAccounts) {
      final uid = account['userId']!;
      final email = account['email']!;
      final firstName = account['firstName']!;

      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockUserDoc = MockDocumentReference<Map<String, dynamic>>();

      final userData = {
        'email': email,
        'firstName': firstName,
        'createdAt': Timestamp.now(),
        'lastLoginAt': Timestamp.now(),
        'isActive': true,
      };

      when(() => mockDocSnapshot.data()).thenReturn(userData);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.id).thenReturn(uid);

      when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockFirestore.collection('users').doc(uid))
          .thenReturn(mockUserDoc);
    }
  }

  // Setup for login success
  void setupLoginSuccess(
      {String email = 'test@example.com', String password = 'password123'}) {
    final mockUser = createMockUser(email: email);
    final mockCredential = MockUserCredential();

    when(() => mockCredential.user).thenReturn(mockUser);
    when(() => providerContainer.mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

    when(() => providerContainer.mockAuthService.signInWithEmailAndPassword(
          email,
          password,
        )).thenAnswer((_) async => mockCredential);

    // Setup auth state changes
    final controller = StreamController<User?>();
    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);

    // Emit the user to simulate successful login
    controller.add(mockUser);
  }

  // Setup for login failure
  void setupLoginFailure(
      {String email = 'test@example.com', String password = 'wrongpassword'}) {
    when(() => providerContainer.mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    when(() => providerContainer.mockAuthService.signInWithEmailAndPassword(
          email,
          password,
        )).thenThrow(FirebaseAuthException(code: 'wrong-password'));
  }

  // Setup for successful user switching
  Future<void> setupUserSwitchSuccess(String targetEmail) async {
    // Find the target account
    final targetAccount = _testAccounts.firstWhere(
      (account) => account['email'] == targetEmail,
      orElse: () => _testAccounts.first,
    );

    // Create a mock user for the target
    final mockUser = createMockUser(
      uid: targetAccount['userId'] as String,
      email: targetEmail,
      firstName: targetAccount['firstName'] as String,
    );

    // Mock the switch account functionality
    when(() => providerContainer.mockAuthService.switchAccount(targetEmail))
        .thenAnswer((_) async {
      // Emit the new user to auth state
      final controller = StreamController<User?>();
      when(() => providerContainer.mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => controller.stream);
      controller.add(mockUser);

      // Update the active user ID
      when(() => providerContainer.mockCredentialService.getActiveUserId())
          .thenAnswer((_) async => targetAccount['userId']);

      // Update current user
      when(() => providerContainer.mockFirebaseAuth.currentUser)
          .thenReturn(mockUser);
    });
  }

  // Setup for user sign out
  void setupSignOut() {
    when(() => providerContainer.mockFirebaseAuth.signOut())
        .thenAnswer((_) async {});
    when(() => providerContainer.mockAuthService.signOut())
        .thenAnswer((_) async {});

    // Update auth state to emit null after sign out
    final controller = StreamController<User?>();
    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);
    controller.add(null);

    // Update current user to null
    when(() => providerContainer.mockFirebaseAuth.currentUser).thenReturn(null);
  }

  // Setup for user sign out and account switching
  void setupSignOutAndSwitch() {
    when(() => providerContainer.mockFirebaseAuth.signOut())
        .thenAnswer((_) async {});
    when(() => providerContainer.mockAuthService.signOut())
        .thenAnswer((_) async {});

    // Mock credential service behavior
    when(() => providerContainer.mockCredentialService.getUserAccounts())
        .thenAnswer((_) async => [
              {
                'email': 'another@example.com',
                'userId': 'user-3',
                'authType': 'password',
                'password': 'password123'
              },
              {
                'email': 'test@example.com',
                'userId': 'user-1',
                'authType': 'password',
                'password': 'password123'
              },
            ]);

    when(() => providerContainer.mockCredentialService.setActiveUser(any()))
        .thenAnswer((_) async => {});

    when(() => providerContainer.mockCredentialService.getAccountDetails(any()))
        .thenAnswer((invocation) async {
      final email = invocation.positionalArguments[0];
      if (email == 'another@example.com') {
        return {
          'email': 'another@example.com',
          'userId': 'user-3',
          'authType': 'password',
          'password': 'password123'
        };
      }
      return null;
    });

    // Create a mock user for the next account
    final mockNextUser = auth_account.MockUser();
    when(() => mockNextUser.email).thenReturn('another@example.com');
    when(() => mockNextUser.uid).thenReturn('user-3');

    // Mock the sign in process for the next account
    when(() => providerContainer.mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'another@example.com', password: 'password123'))
        .thenAnswer((_) async => auth_account.MockUserCredential(mockNextUser));

    // Update auth state to emit the next user after sign in
    final controller = StreamController<User?>();
    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);
    controller.add(mockNextUser);

    // Update current user to the next one
    when(() => providerContainer.mockFirebaseAuth.currentUser)
        .thenReturn(mockNextUser);
  }

  // Setup for account deletion
  void setupAccountDeletion() {
    // Create a mock user to delete
    final mockUser = auth_account.MockUser();
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.uid).thenReturn('user-1');

    // Mock current user
    when(() => providerContainer.mockFirebaseAuth.currentUser)
        .thenReturn(mockUser);

    // Mock reauthentication
    final credential = auth_account.MockAuthCredential();
    when(() => EmailAuthProvider.credential(
        email: 'test@example.com',
        password: 'password123')).thenReturn(credential);

    when(() => mockUser.reauthenticateWithCredential(credential))
        .thenAnswer((_) async => auth_account.MockUserCredential());

    // Mock deletion
    when(() => mockUser.delete()).thenAnswer((_) async {});

    // Mock credential service
    when(() => providerContainer.mockCredentialService
        .removeUserAccount('test@example.com')).thenAnswer((_) async {});
  }

  // Set a specific user as active based on email or userId
  Future<auth_account.MockUser> setActiveUser(String identifier) async {
    // Find the user in test accounts (by email or userId)
    final account = _testAccounts.firstWhere(
      (account) =>
          account['email'] == identifier || account['userId'] == identifier,
      orElse: () => throw Exception('User not found: $identifier'),
    );

    // Create a mock user for this account
    final mockUser = createMockUser(
      uid: account['userId']!,
      email: account['email']!,
      firstName: account['firstName']!,
      lastName: account['lastName'],
    );

    // Set as current user in Firebase Auth
    when(() => providerContainer.mockFirebaseAuth.currentUser)
        .thenReturn(mockUser);

    // Update the auth state stream
    final authStateController = StreamController<User?>.broadcast();
    authStateController.add(mockUser);
    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => authStateController.stream);

    // Set as active user in credential service
    when(() => providerContainer.mockCredentialService.getActiveUserId())
        .thenAnswer((_) async => account['userId']);

    return mockUser;
  }

  // Get user account by email or userId
  Map<String, String> getTestAccount(String identifier) {
    return _testAccounts.firstWhere(
      (account) =>
          account['email'] == identifier || account['userId'] == identifier,
      orElse: () => throw Exception('Test account not found: $identifier'),
    );
  }

  Widget buildLoginScreen() {
    return ProviderScope(
      parent: providerContainer.container,
      child: MaterialApp(
        home: const LoginScreen(),
      ),
    );
  }

  Widget buildHomeScreen() {
    return ProviderScope(
      parent: providerContainer.container,
      child: MaterialApp(
        home: const HomeScreen(),
      ),
    );
  }

  void dispose() {
    providerContainer.dispose();
  }
}

// Add these mock classes to support Firestore document mocking
class MockFirestore extends Mock implements FirebaseFirestore {}

class MockDocumentReference<T extends Object?> extends Mock
    implements DocumentReference<T> {}

class MockDocumentSnapshot<T extends Object?> extends Mock
    implements DocumentSnapshot<T> {}

class MockCollectionReference<T extends Object?> extends Mock
    implements CollectionReference<T> {}
