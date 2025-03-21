import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:smoke_log/services/interfaces/auth_service_interface.dart';
import 'package:smoke_log/services/auth_service.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-uid';

  @override
  String? get email => 'test@example.com';

  @override
  String? get displayName => 'Test User';
}

class MockAuthService extends Mock implements AuthService {
  final _authStateController = StreamController<User?>.broadcast();
  final MockUser? _currentUser;

  MockAuthService({MockUser? currentUser}) : _currentUser = currentUser {
    if (currentUser != null) {
      _authStateController.add(currentUser);
    }
  }

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    if (email == 'test@example.com' && password == 'password') {
      final mockUser = MockUser();
      _authStateController.add(mockUser);
      return MockUserCredential(mockUser);
    } else {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid',
      );
    }
  }

  @override
  Future<SignOutResult> signOut() async {
    _authStateController.add(null);
    return SignOutResult.fullySignedOut;
  }

  void dispose() {
    _authStateController.close();
  }

  // Implement other methods as needed...
}

class MockUserCredential extends Mock implements UserCredential {
  final User? _user;

  MockUserCredential(this._user);

  @override
  User? get user => _user;
}
