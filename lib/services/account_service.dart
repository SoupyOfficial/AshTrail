import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import './interfaces/auth_service_interface.dart';
import './interfaces/account_service_interface.dart';
import './credential_service.dart';

/// Implementation of IAccountService
class AccountService implements IAccountService {
  final IAuthService _authService;
  final CredentialService _credentialService;

  AccountService(this._authService, this._credentialService);

  @override
  Future<List<Map<String, dynamic>>> getUserAccounts() async {
    final accounts = await _credentialService.getUserAccounts();

    // Convert to consistent format
    return accounts
        .map((account) => Map<String, dynamic>.from(account))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getActiveAccount() async {
    final activeUserId = await _credentialService.getActiveUserId();
    if (activeUserId == null) return null;

    final accounts = await getUserAccounts();
    return accounts.firstWhere(
      (account) => account['userId'] == activeUserId,
      orElse: () => <String, dynamic>{},
    );
  }

  @override
  Future<void> switchToAccount(String userId) async {
    // Get account details
    final accounts = await getUserAccounts();
    final targetAccount = accounts.firstWhere(
      (account) => account['userId'] == userId,
      orElse: () => <String, dynamic>{},
    );

    if (targetAccount.isEmpty) {
      throw Exception('Account not found');
    }

    final email = targetAccount['email'];
    if (email == null || email.isEmpty) {
      throw Exception('Account has no email');
    }

    // Use auth service to perform the switch
    await _authService.switchAccount(email as String);
  }

  @override
  Future<bool> signOutAndSwitchIfAvailable() async {
    // Get accounts before signing out
    final accounts = await getUserAccounts();
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email;

    // Sign out the current user
    await _authService.signOut();

    // If no other accounts, we're done
    if (accounts.isEmpty || accounts.length == 1) {
      return false;
    }

    // Try to find another account to switch to
    final nextAccount = accounts.firstWhere(
      (account) => account['email'] != currentEmail,
      orElse: () => <String, dynamic>{},
    );

    if (nextAccount.isEmpty) {
      return false;
    }

    try {
      // Attempt to switch to the next account
      final email = nextAccount['email'] as String?;
      if (email != null && email.isNotEmpty) {
        await _authService.switchAccount(email);
        return true;
      }
    } catch (e) {
      debugPrint('Error switching account: $e');
    }

    return false;
  }

  @override
  Future<void> addAccount(Map<String, dynamic> accountData) async {
    final email = accountData['email'] as String?;
    final password = accountData['password'] as String?;
    final authType = accountData['authType'] as String? ?? 'password';

    if (email == null || email.isEmpty) {
      throw Exception('Email is required');
    }

    await _credentialService.addUserAccount(email, password, authType);
  }

  @override
  Future<void> removeAccount(String userId) async {
    await _credentialService.removeUserAccount(userId);
  }
}
