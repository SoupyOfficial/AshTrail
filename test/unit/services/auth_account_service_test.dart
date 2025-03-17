import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/services/auth_account_service.dart';
import 'package:smoke_log/services/credential_service.dart';

// Define mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockCredentialService extends Mock implements CredentialService {}

class MockUser extends Mock implements User {}

class MockAuthCredential extends Mock implements AuthCredential {}

class MockUserCredential extends Mock implements UserCredential {
  final User? _user;
  MockUserCredential([this._user]);

  @override
  User? get user => _user;
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockCredentialService mockCredentialService;
  late AuthAccountService authAccountService;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockCredentialService = MockCredentialService();
    authAccountService = AuthAccountService(
      auth: mockAuth,
      credentialService: mockCredentialService,
    );
    mockUser = MockUser();

    // Default setup for the current user
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.email).thenReturn('test@example.com');

    // Register fallback values
    registerFallbackValue(MockAuthCredential());
    registerFallbackValue(MockUser());
  });

  group('signOutAndSwitchIfAvailable', () {
    test('should sign out completely when no other accounts are available',
        () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      when(() => mockCredentialService.getUserAccounts())
          .thenAnswer((_) async => []);

      // Act
      final result = await authAccountService.signOutAndSwitchIfAvailable();

      // Assert
      expect(result, false);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('should switch to another account when available', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      when(() => mockCredentialService.getUserAccounts())
          .thenAnswer((_) async => [
                {
                  'email': 'another@example.com',
                  'userId': 'user-2',
                  'authType': 'password',
                  'password': 'password123'
                }
              ]);

      when(() => mockCredentialService.setActiveUser('user-2'))
          .thenAnswer((_) async {});

      when(() => mockCredentialService.getAccountDetails('another@example.com'))
          .thenAnswer((_) async => {
                'email': 'another@example.com',
                'userId': 'user-2',
                'authType': 'password',
                'password': 'password123'
              });

      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'another@example.com',
            password: 'password123',
          )).thenAnswer((_) async => MockUserCredential());

      // Act
      final result = await authAccountService.signOutAndSwitchIfAvailable();

      // Assert
      expect(result, true);
      verify(() => mockAuth.signOut()).called(1);
      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'another@example.com',
            password: 'password123',
          )).called(1);
    });
  });

  group('deleteAccount', () {
    test('should delete the current user account', () async {
      // Arrange
      final credential = MockAuthCredential();
      when(() => EmailAuthProvider.credential(
            email: 'test@example.com',
            password: 'password123',
          )).thenReturn(credential);

      when(() => mockUser.reauthenticateWithCredential(credential))
          .thenAnswer((_) async => MockUserCredential());

      when(() => mockUser.delete()).thenAnswer((_) async {});

      when(() => mockCredentialService.removeUserAccount('test@example.com'))
          .thenAnswer((_) async {});

      // Mock the signOutAndSwitchIfAvailable method
      when(() => mockCredentialService.getUserAccounts())
          .thenAnswer((_) async => []);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      // Act
      await authAccountService.deleteAccount('password123');

      // Assert
      verify(() => mockUser.reauthenticateWithCredential(credential)).called(1);
      verify(() => mockUser.delete()).called(1);
      verify(() => mockCredentialService.removeUserAccount('test@example.com'))
          .called(1);
    });

    test('should throw exception when no user is signed in', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () => authAccountService.deleteAccount('password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No user is signed in'),
        )),
      );
    });
  });
}
