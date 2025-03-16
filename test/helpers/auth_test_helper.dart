import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import 'package:smoke_log/services/credential_service.dart';
import 'package:smoke_log/screens/login_screen.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'mock_providers.dart';

class AuthTestHelper {
  late TestProviderContainer providerContainer;

  // Mock user accounts for testing
  final List<Map<String, String>> _testAccounts = [
    {
      'userId': 'user-1',
      'email': 'test1@example.com',
      'displayName': 'Test User 1',
      'firstName': 'Test',
      'authType': 'password',
      'password': 'password123'
    },
    {
      'userId': 'user-2',
      'email': 'test2@example.com',
      'displayName': 'Test User 2',
      'firstName': 'User2',
      'authType': 'password',
      'password': 'password123'
    },
    {
      'userId': 'user-3',
      'email': 'test3@example.com',
      'displayName': 'Google User',
      'firstName': 'Google',
      'authType': 'google',
      'password': ''
    }
  ];

  Future<List<Map<String, String>>> getUserAccounts() async => _testAccounts;

  AuthTestHelper() {
    providerContainer = TestProviderContainer();
  }

  // Create a test user
  MockUser createMockUser({
    String uid = 'user-1',
    String email = 'test@example.com',
    String displayName = 'Test User',
  }) {
    final mockUser = MockUser();
    when(() => mockUser.uid).thenReturn(uid);
    when(() => mockUser.email).thenReturn(email);
    when(() => mockUser.displayName).thenReturn(displayName);

    // Always set up the auth state stream when creating a mock user
    final controller = StreamController<User?>.broadcast();
    controller.add(mockUser);
    when(() => providerContainer.mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);

    return mockUser;
  }

  // Setup user accounts for testing
  Future<void> setupUserAccounts() async {
    // Convert test accounts to the format expected by CredentialService
    final accounts = _testAccounts
        .map((account) => {
              'userId': account['userId'],
              'email': account['email'],
              'displayName': account['displayName'],
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
      displayName: targetAccount['displayName'] as String,
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
