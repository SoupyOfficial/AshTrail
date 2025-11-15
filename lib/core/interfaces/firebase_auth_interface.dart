import 'package:firebase_auth/firebase_auth.dart';

/// Interface for Firebase Authentication operations
/// This abstraction allows for easier testing and potential future implementations
abstract class IFirebaseAuth {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserCredential> signInWithCredential(AuthCredential credential);
  Future<UserCredential> signInWithCustomToken(String token);
  Future<UserCredential> signInWithPopup(AuthProvider provider);
  Future<void> signOut();
  Future<void> deleteUser(User user);
}

/// Wrapper implementation for FirebaseAuth
class FirebaseAuthWrapper implements IFirebaseAuth {
  final FirebaseAuth _auth;

  FirebaseAuthWrapper(this._auth);

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      _auth.signInWithCredential(credential);

  @override
  Future<UserCredential> signInWithCustomToken(String token) =>
      _auth.signInWithCustomToken(token);

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) =>
      _auth.signInWithPopup(provider);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteUser(User user) => user.delete();
}

