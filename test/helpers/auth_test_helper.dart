import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/providers/auth_provider.dart' as authProvider;
import 'package:smoke_log/providers/consolidated_auth_provider.dart'
    as consolidated;
import 'package:smoke_log/providers/user_account_provider.dart';
import 'package:smoke_log/screens/login_screen.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/services/credential_service.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockAuthCredential extends Mock implements AuthCredential {}

class MockAuthService extends Mock implements AuthService {
  Future<UserCredential> login(
      {required String email, required String password}) async {
    // Mock implementation for login
    throw UnimplementedError();
  }
}

class MockCredentialService extends Mock implements CredentialService {}

// Container to hold all provider mocks and containers
class ProviderMocksContainer {
  final MockFirebaseAuth mockFirebaseAuth;
  final MockAuthService mockAuthService;
  final MockCredentialService mockCredentialService;
  final ProviderContainer container;

  ProviderMocksContainer({
    required this.mockFirebaseAuth,
    required this.mockAuthService,
    required this.mockCredentialService,
    required this.container,
  });
}

class AuthTestHelper {
  late ProviderMocksContainer providerContainer;
  final List<StreamController> _controllers = [];

  AuthTestHelper() {
    final mockFirebaseAuth = MockFirebaseAuth();
    final mockAuthService = MockAuthService();
    final mockCredentialService = MockCredentialService();

    // Setup default when() for common methods
    when(() => mockCredentialService.getUserAccounts())
        .thenAnswer((_) async => []);

    final container = ProviderContainer(
      overrides: [
        // Legacy
        authProvider.firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        authProvider.authServiceProvider.overrideWithValue(mockAuthService),
        authProvider.credentialServiceProvider
            .overrideWithValue(mockCredentialService),

        // Consolidated
        consolidated.firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        consolidated.authServiceProvider.overrideWithValue(mockAuthService),
        consolidated.credentialServiceProvider
            .overrideWithValue(mockCredentialService),
      ],
    );

    providerContainer = ProviderMocksContainer(
      mockFirebaseAuth: mockFirebaseAuth,
      mockAuthService: mockAuthService,
      mockCredentialService: mockCredentialService,
      container: container,
    );
  }

  // Helper to create a mock user with specific attributes
  MockUser createMockUser({
    String uid = 'test-uid',
    String email = 'test@example.com',
    String? firstName,
  }) {
    final mockUser = MockUser();
    when(() => mockUser.uid).thenReturn(uid);
    when(() => mockUser.email).thenReturn(email);

    // Setup displayName if firstName provided
    if (firstName != null) {
      when(() => mockUser.displayName).thenReturn('$firstName User');
    }

    // Setup empty provider data by default
    when(() => mockUser.providerData).thenReturn([]);

    return mockUser;
  }

  // Setup user accounts for testing
  Future<List<Map<String, String>>> setupUserAccounts() async {
    final userAccounts = [
      {
        'userId': 'user-1',
        'email': 'test1@example.com',
        'authType': 'password'
      },
      {'userId': 'user-2', 'email': 'test2@example.com', 'authType': 'password'}
    ];

    when(() => providerContainer.mockCredentialService.getUserAccounts())
        .thenAnswer((_) async => userAccounts
            .map((account) => Map<String, String>.from(account))
            .toList());

    return userAccounts
        .map((account) => Map<String, String>.from(account))
        .toList();
  }

  // Set active user for testing
  Future<MockUser> setActiveUser(String email) async {
    final mockUser = createMockUser(email: email);

    // Set as current Firebase user
    when(() => providerContainer.mockFirebaseAuth.currentUser)
        .thenReturn(mockUser);

    // Create auth state stream
    final controller = StreamController<User?>.broadcast();
    controller.add(mockUser);
    _controllers.add(controller);

    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);

    return mockUser;
  }

  // Setup login success for testing
  void setupLoginSuccess(
      {String email = 'test@example.com', String password = 'password123'}) {
    final mockUser = createMockUser(email: email);
    final mockCredential = MockUserCredential();

    when(() => mockCredential.user).thenReturn(mockUser);

    when(() => providerContainer.mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

    when(() => providerContainer.mockAuthService.login(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);
  }

  // Setup login failure for testing
  void setupLoginFailure() {
    when(() => providerContainer.mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Wrong password'));

    when(() => providerContainer.mockAuthService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Wrong password'));
  }

  // Setup sign out for testing
  void setupSignOut() {
    when(() => providerContainer.mockFirebaseAuth.signOut())
        .thenAnswer((_) async => {});

    when(() => providerContainer.mockAuthService.signOut())
        .thenAnswer((_) async => SignOutResult.fullySignedOut);
  }

  // Setup sign out and switch to another user
  void setupSignOutAndSwitch() {
    when(() => providerContainer.mockFirebaseAuth.signOut())
        .thenAnswer((_) async => {});

    // New SignOutResult enum return type
    when(() => providerContainer.mockAuthService.signOut())
        .thenAnswer((_) async => SignOutResult.switchedToAnotherUser);

    // Setup subsequent sign in
    final mockUser = createMockUser(email: 'another@example.com');
    final mockCredential = MockUserCredential();
    when(() => mockCredential.user).thenReturn(mockUser);

    when(() => providerContainer.mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'another@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockCredential);
  }

  // Setup user switching success for testing with updated return type
  Future<void> setupUserSwitchSuccess(String email) async {
    when(() => providerContainer.mockAuthService.switchAccount(email))
        .thenAnswer((_) async => {});
  }

  // Get user accounts from mock
  Future<List<Map<String, String>>> getUserAccounts() {
    return providerContainer.mockCredentialService.getUserAccounts();
  }

  // Build login screen for testing
  Widget buildLoginScreen() {
    return ProviderScope(
      parent: providerContainer.container,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  // Build home screen for testing
  Widget buildHomeScreen() {
    return ProviderScope(
      parent: providerContainer.container,
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  // Clean up resources
  void dispose() {
    for (final controller in _controllers) {
      controller.close();
    }
    _controllers.clear();
    providerContainer.container.dispose();
  }
}
