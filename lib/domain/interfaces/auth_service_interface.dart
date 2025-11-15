import 'package:firebase_auth/firebase_auth.dart';

/// Interface defining authentication operations
abstract class IAuthService {
  /// Get the current authentication state stream
  Stream<User?> get authStateChanges;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle();

  /// Sign in with Apple
  Future<UserCredential> signInWithApple();

  /// Switch to another user account
  Future<void> switchAccount(String email);

  /// Sign out the current user
  Future<SignOutResult> signOut();

  /// Delete the current user account
  Future<void> deleteAccount(String userId);
}

/// Result of sign out operation
enum SignOutResult {
  switchedToAnotherUser,
  fullySignedOut,
}

