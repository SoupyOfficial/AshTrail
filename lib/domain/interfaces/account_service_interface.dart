/// Interface defining account management operations
abstract class IAccountService {
  /// Get the current user's accounts
  Future<List<Map<String, dynamic>>> getUserAccounts();

  /// Get the currently active user
  Future<Map<String, dynamic>?> getActiveAccount();

  /// Switch to another user account
  Future<void> switchToAccount(String userId);

  /// Sign out and optionally switch to another account
  Future<bool> signOutAndSwitchIfAvailable();

  /// Add a new account
  Future<void> addAccount(Map<String, dynamic> accountData);

  /// Remove an account
  Future<void> removeAccount(String userId);
}

