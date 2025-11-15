import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/di/dependency_injection.dart';
import '../../data/services/authentication_service.dart';
import '../../data/services/token_management_service.dart';
import '../../data/services/user_document_service.dart';
import '../../domain/interfaces/auth_service_interface.dart';
import '../../domain/interfaces/account_service_interface.dart';
import '../../services/account_service.dart';

/// Stream provider for current authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provider for authentication service (using interface)
final authServiceProvider = Provider<IAuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  final credentialService = ref.watch(credentialServiceProvider);
  final tokenService = ref.watch(tokenServiceProvider);
  
  // Create focused services
  final tokenManagementService = TokenManagementService(
    auth,
    credentialService,
    tokenService,
  );
  
  final firestore = ref.watch(firebaseFirestoreInstanceDirectProvider);
  final userDocumentService = UserDocumentService(firestore);
  
  return AuthenticationService(
    auth,
    googleSignIn,
    credentialService,
    tokenManagementService,
    userDocumentService,
  );
});

/// Provider for account management service (using interface)
final accountServiceProvider = Provider<IAccountService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final credentialService = ref.watch(credentialServiceProvider);
  return AccountService(authService, credentialService);
});

/// Provider for current authentication type
final userAuthTypeProvider = StreamProvider<String>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges().map((user) {
    if (user == null) return 'none';

    final isGoogleUser = user.providerData
        .any((provider) => provider.providerId == 'google.com');
    if (isGoogleUser) return 'google';

    final isAppleUser = user.providerData
        .any((provider) => provider.providerId == 'apple.com');
    if (isAppleUser) return 'apple';

    return 'password';
  });
});

/// Provider for user accounts with auto-refresh capability
final userAccountsProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  ref.watch(authStateProvider);
  final credentialService = ref.watch(credentialServiceProvider);

  await credentialService.cleanupDuplicateAccounts();

  final authState = ref.watch(authStateProvider);
  if (authState.value != null) {
    await credentialService.saveUserAccount(authState.value!);
  }

  final accounts = await credentialService.getUserAccounts();
  return accounts
      .map((account) => account.map((key, value) => MapEntry(key, value)))
      .toList();
});

/// Provider for currently active user account
final activeAccountProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authStateProvider);
  final accountService = ref.watch(accountServiceProvider);
  return accountService.getActiveAccount();
});

