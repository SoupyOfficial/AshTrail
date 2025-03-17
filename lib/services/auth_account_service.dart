import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smoke_log/services/credential_service.dart';

/// Service responsible for handling authentication account operations
class AuthAccountService {
  final FirebaseAuth _auth;
  final CredentialService _credentialService;

  AuthAccountService({
    FirebaseAuth? auth,
    CredentialService? credentialService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _credentialService = credentialService ?? CredentialService();

  /// Sign out the current user and optionally switch to another account
  /// Returns true if switched to another account, false if completely signed out
  Future<bool> signOutAndSwitchIfAvailable() async {
    // Get all accounts before signing out
    final accounts = await _credentialService.getUserAccounts();
    final currentEmail = _auth.currentUser?.email;

    // Sign out the current user
    await _auth.signOut();

    // If there are no other accounts, return false (completely signed out)
    if (accounts.isEmpty) {
      return false;
    }

    // Find another account to switch to (not the current one)
    final nextAccount = accounts.firstWhere(
      (account) => account['email'] != currentEmail,
      orElse: () => accounts.isNotEmpty ? accounts.first : const {},
    );

    // If we found a valid account, switch to it
    if (nextAccount.isNotEmpty && nextAccount['email'] != null) {
      try {
        final email = nextAccount['email']!;
        final userId = nextAccount['userId'];

        if (userId != null && userId.isNotEmpty) {
          await _credentialService.setActiveUser(userId);

          // Try to sign in with the account details
          final accountDetails =
              await _credentialService.getAccountDetails(email);
          if (accountDetails != null &&
              accountDetails['authType'] == 'password') {
            final password = accountDetails['password'];
            if (password != null && password.isNotEmpty) {
              await _auth.signInWithEmailAndPassword(
                  email: email, password: password);
              debugPrint('Switched to account: $email');
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error switching account: $e');
      }
    }

    return false;
  }

  /// Delete the current user account
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is signed in');

    // Re-authenticate the user before deletion
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    await user.delete();

    // Clean up any stored credentials for this user
    await _credentialService.removeUserAccount(user.email!);

    // Handle automatic switching to another account if available
    await signOutAndSwitchIfAvailable();
  }

  /// Find the currently signed in user's email
  String? get currentUserEmail => _auth.currentUser?.email;
}
