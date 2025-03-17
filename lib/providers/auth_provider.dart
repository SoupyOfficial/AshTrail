import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/credential_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    clientId:
        '660497517730-an04u70e9dfg71meco3ev6gvcri684hk.apps.googleusercontent.com',
  );
});

final credentialServiceProvider = Provider<CredentialService>((ref) {
  return CredentialService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(credentialServiceProvider),
    ref, // Passing the provider reference required by AuthService
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userAuthTypeProvider = StreamProvider<String>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges().map((user) {
    if (user == null) return 'none';

    // Check if the user's providers list contains Google or Apple
    final isGoogleUser = user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
    if (isGoogleUser) return 'google';

    final isAppleUser = user.providerData.any(
      (provider) => provider.providerId == 'apple.com',
    );
    if (isAppleUser) return 'apple';

    return 'password';
  });
});

// Update to include auto-refresh and de-duplication when auth state changes
final userAccountsProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  // Watch the auth state to refresh when the user changes
  final authState = ref.watch(authStateProvider);
  final credentialService = ref.read(credentialServiceProvider);

  // Clean up any duplicate accounts
  await credentialService.cleanupDuplicateAccounts();

  // If we have a user, make sure they're saved
  if (authState.value != null) {
    // Save the current user to ensure they're in the account list
    await credentialService.saveUserAccount(authState.value!);
  }

  return (await credentialService.getUserAccounts())
      .map((account) => account.map((key, value) => MapEntry(key, value ?? '')))
      .toList();
});
