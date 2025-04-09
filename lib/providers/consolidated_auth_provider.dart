import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smoke_log/providers/user_account_provider.dart';
import 'package:smoke_log/services/account_service.dart';
import '../services/auth_service.dart';
import '../services/credential_service.dart';
import '../services/user_account_service.dart';
import '../services/auth_account_service.dart';
import '../services/interfaces/auth_service_interface.dart';
import '../services/interfaces/account_service_interface.dart';
import '../services/token_service.dart';

/// Core Firebase Auth provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for secure credential storage
final credentialServiceProvider = Provider<CredentialService>((ref) {
  return CredentialService();
});

/// Provider for Google Sign In
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

/// Provider for authentication service
final authServiceProvider = Provider<IAuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  final credentialService = ref.watch(credentialServiceProvider);
  return AuthService(firebaseAuth, googleSignIn, credentialService, ref);
});

/// Provider for account management
final accountServiceProvider = Provider<IAccountService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final credentialService = ref.watch(credentialServiceProvider);
  return AccountService(authService, credentialService);
});

/// Provider for custom token generation service
final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

/// Stream provider for current authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Provider for current authentication type
final authTypeProvider = StateProvider<String?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return 'none';

      if (user.providerData.any((p) => p.providerId == 'google.com')) {
        return 'google';
      } else if (user.providerData.any((p) => p.providerId == 'apple.com')) {
        return 'apple';
      }

      return 'password';
    },
    loading: () => null,
    error: (_, __) => 'error',
  );
});

/// Provider for user accounts with auto-refresh capability
final userAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to refresh when it changes
  final _ = ref.watch(authStateProvider);
  return ref.watch(accountServiceProvider).getUserAccounts();
});

/// Provider for currently active user account
final activeAccountProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch auth state to refresh when it changes
  final _ = ref.watch(authStateProvider);
  return ref.watch(accountServiceProvider).getActiveAccount();
});

/// Provider for enriched user accounts with profile data
final enrichedAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final accounts = await ref.watch(userAccountsProvider.future);
  final userAccountService = ref.watch(userAccountServiceProvider);
  return userAccountService.getEnrichedAccounts(accounts);
});

/// Provider for the operation of logging out and optionally switching accounts
final logoutOperationProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(accountServiceProvider).signOutAndSwitchIfAvailable();
});
