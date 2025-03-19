import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/providers/consolidated_auth_provider.dart'
    as consolidated;
import 'package:smoke_log/providers/user_account_provider.dart';
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/services/credential_service.dart';
import 'package:smoke_log/services/user_account_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Create mocks
class MockAuthService extends Mock implements AuthService {}

class MockCredentialService extends Mock implements CredentialService {}

class MockUserAccountService extends Mock implements UserAccountService {}

class MockUser extends Mock implements firebase_auth.User {}

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockUserInfo extends Mock implements firebase_auth.UserInfo {
  @override
  final String providerId;
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? photoURL;
  @override
  final String? email;
  @override
  final String? phoneNumber;
  @override
  final bool isAnonymous;

  MockUserInfo({
    required this.providerId,
    required this.uid,
    this.displayName,
    this.photoURL,
    this.email,
    this.phoneNumber,
    required this.isAnonymous,
  });
}

void main() {
  late ProviderContainer container;
  late MockAuthService mockAuthService;
  late MockCredentialService mockCredentialService;
  late MockUserAccountService mockUserAccountService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockCredentialService = MockCredentialService();
    mockUserAccountService = MockUserAccountService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Set up default behavior
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

    // Stream for authStateChanges
    final controller = StreamController<MockUser>();
    controller.add(mockUser);
    when(() => mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => controller.stream);

    container = ProviderContainer(
      overrides: [
        consolidated.firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        consolidated.authServiceProvider.overrideWithValue(mockAuthService),
        consolidated.credentialServiceProvider
            .overrideWithValue(mockCredentialService),
        userAccountServiceProvider.overrideWithValue(mockUserAccountService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('authStateProvider returns current user', () async {
    final user = await container.read(consolidated.authStateProvider.future);
    expect(user, equals(mockUser));
    verify(() => mockFirebaseAuth.authStateChanges()).called(1);
  });

  test('authTypeProvider returns correct auth type for Google user', () {
    when(() => mockUser.providerData).thenReturn([
      MockUserInfo(
        providerId: 'google.com',
        uid: '123',
        displayName: null,
        photoURL: null,
        email: 'test@example.com',
        phoneNumber: null,
        isAnonymous: false,
      )
    ]);

    expect(
      container.read(consolidated.authTypeProvider),
      'google',
    );
  });

  test('authTypeProvider returns correct auth type for password user', () {
    when(() => mockUser.providerData).thenReturn([
      MockUserInfo(
        providerId: 'google.com',
        uid: '123',
        displayName: null,
        photoURL: null,
        email: 'test@example.com',
        phoneNumber: null,
        isAnonymous: false,
      )
    ]);

    expect(
      container.read(consolidated.authTypeProvider),
      'password',
    );
  });

  test('userAccountsProvider returns accounts from service', () async {
    final accounts = [
      {'userId': '1', 'email': 'user1@example.com'},
      {'userId': '2', 'email': 'user2@example.com'}
    ];

    when(() => mockCredentialService.getUserAccounts()).thenAnswer(
        (_) async => accounts.map((a) => Map<String, String>.from(a)).toList());

    final result =
        await container.read(consolidated.userAccountsProvider.future);

    expect(result.length, 2);
    expect(result[0]['email'], 'user1@example.com');
    expect(result[1]['email'], 'user2@example.com');
  });

  test('enrichedAccountsProvider enriches accounts with profile data',
      () async {
    // Base accounts
    final baseAccounts = [
      {'userId': '1', 'email': 'user1@example.com'},
      {'userId': '2', 'email': 'user2@example.com'}
    ];

    // Enriched accounts should include firstName and hasUniqueName
    final enrichedAccounts = [
      {
        'userId': '1',
        'email': 'user1@example.com',
        'firstName': 'John',
        'hasUniqueName': true
      },
      {
        'userId': '2',
        'email': 'user2@example.com',
        'firstName': 'Mike',
        'hasUniqueName': true
      }
    ];

    when(() => mockCredentialService.getUserAccounts()).thenAnswer((_) async =>
        baseAccounts.map((a) => Map<String, String>.from(a)).toList());

    when(() => mockUserAccountService.getEnrichedAccounts(any()))
        .thenAnswer((_) async => enrichedAccounts);

    final result =
        await container.read(consolidated.enrichedAccountsProvider.future);

    expect(result.length, 2);
    expect(result[0]['firstName'], 'John');
    expect(result[0]['hasUniqueName'], true);
    expect(result[1]['firstName'], 'Mike');

    // Verify the service calls
    verify(() => mockUserAccountService.getEnrichedAccounts(any())).called(1);
  });
}
