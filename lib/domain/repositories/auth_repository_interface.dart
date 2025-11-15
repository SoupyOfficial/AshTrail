import 'package:firebase_auth/firebase_auth.dart';
import '../interfaces/auth_service_interface.dart';

/// Interface for authentication repository operations
/// This defines the contract for authentication data access
abstract class IAuthRepository {
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

