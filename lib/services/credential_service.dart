import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CredentialService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _userAccountsKey = 'user_accounts';
  static const String _activeUserKey = 'active_user';
  static const String _tokenPrefix = 'auth_token_';
  static const String _oauthTokenPrefix = 'oauth_token_';

  // Consolidated method for storing user passwords
  Future<void> _savePassword(String email, String password) async {
    try {
      await _secureStorage.write(
          key: 'password_${email.toLowerCase()}', value: password);
      debugPrint('Stored password for $email');
    } catch (e) {
      debugPrint('Error storing password: $e');
    }
  }

  // Consolidated method for retrieving user passwords
  Future<String?> _getPassword(String email) async {
    try {
      return await _secureStorage.read(key: 'password_${email.toLowerCase()}');
    } catch (e) {
      debugPrint('Error retrieving password: $e');
      return null;
    }
  }

  // Create a key for storing OAuth tokens
  String _getOAuthTokenKey(String email) =>
      '$_oauthTokenPrefix${email.toLowerCase()}';

  // Store OAuth tokens specifically for third-party providers
  Future<void> storeOAuthToken(
      String email, Map<String, dynamic> tokenData) async {
    try {
      final tokenJson = jsonEncode(tokenData);
      await _secureStorage.write(
        key: _getOAuthTokenKey(email),
        value: tokenJson,
      );
      debugPrint('Stored OAuth token for $email');
    } catch (e) {
      debugPrint('Error storing OAuth token: $e');
    }
  }

  // Retrieve OAuth tokens
  Future<Map<String, dynamic>?> getOAuthToken(String email) async {
    try {
      final tokenJson =
          await _secureStorage.read(key: _getOAuthTokenKey(email));
      if (tokenJson == null) return null;

      final tokenData = jsonDecode(tokenJson) as Map<String, dynamic>;

      // Ensure all token values are strings (fix for the "int is not a subtype of String?" error)
      return tokenData.map((key, value) =>
          MapEntry(key, value is int ? value.toString() : value));
    } catch (e) {
      debugPrint('Error retrieving OAuth token: $e');
      return null;
    }
  }

  // Remove OAuth token
  Future<void> removeOAuthToken(String email) async {
    await _secureStorage.delete(key: _getOAuthTokenKey(email));
  }

  // Get currently active user ID
  Future<String?> getActiveUserId() async {
    return await _secureStorage.read(key: _activeUserKey);
  }

  // Set the active user
  Future<void> setActiveUser(String userId) async {
    await _secureStorage.write(key: _activeUserKey, value: userId);
  }

  /// Retrieves the password for a given email address
  // Future<String?> getPassword(String email) async { //DEPRECATED
  //   try {
  //     const storage = FlutterSecureStorage();
  //     // Assuming passwords are stored with a key format like 'password_email'
  //     return await storage.read(key: 'password_${email.toLowerCase()}');
  //   } catch (e) {
  //     debugPrint('Error retrieving password: $e');
  //     return null;
  //   }
  // }

  // Save a user account without removing existing ones
  Future<void> saveUserAccount(User user,
      {String? password, String? authType}) async {
    // Get existing accounts
    final accounts = await getUserAccounts();

    // Find existing account
    final existingIndexById =
        accounts.indexWhere((account) => account['userId'] == user.uid);
    final existingIndexByEmail =
        accounts.indexWhere((account) => account['email'] == user.email);

    // Determine if we have an existing account and which index to use
    final hasExistingAccount =
        existingIndexById >= 0 || existingIndexByEmail >= 0;
    final indexToUpdate =
        existingIndexById >= 0 ? existingIndexById : existingIndexByEmail;

    final Map<String, String> accountData = {
      'userId': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'authType': authType ?? _determineAuthType(user),
    };

    // Important: Preserve existing password if none provided
    if (password != null && password.isNotEmpty) {
      accountData['password'] = password;
      _savePassword(user.email!, password); // Save password to secure storage
    } else if (hasExistingAccount &&
        accounts[indexToUpdate].containsKey('password')) {
      final existingPassword = await _getPassword(user.email!);
      if (existingPassword != null) {
        accountData['password'] = existingPassword;
      }
    }

    if (hasExistingAccount) {
      // Remove any potential duplicate by email if we're updating by userId
      if (existingIndexById >= 0 &&
          existingIndexByEmail >= 0 &&
          existingIndexById != existingIndexByEmail) {
        // We have two entries - one by ID and one by email, remove the email one
        accounts.removeAt(existingIndexByEmail);
      }

      accounts[indexToUpdate] = accountData;
    } else {
      // Add as new account
      accounts.add(accountData);
    }

    // Save back to secure storage
    await _secureStorage.write(
        key: _userAccountsKey, value: jsonEncode(accounts));

    // Save the auth tokens if available
    await _saveUserToken(user);

    // Set as active user
    await setActiveUser(user.uid);
  }

  // Helper to determine auth type from user object
  String _determineAuthType(User user) {
    if (user.providerData
        .any((provider) => provider.providerId == 'google.com')) {
      return 'google';
    } else if (user.providerData
        .any((provider) => provider.providerId == 'apple.com')) {
      return 'apple';
    } else {
      return 'password';
    }
  }

  // Store auth token for a user
  Future<void> _saveUserToken(User user) async {
    try {
      final token = await user.getIdToken(true);
      await _secureStorage.write(key: _tokenPrefix + user.uid, value: token);
    } catch (e) {
      print('Failed to save user token: $e');
    }
  }

  // Get token for a user
  Future<String?> getUserToken(String userId) async {
    return await _secureStorage.read(key: _tokenPrefix + userId);
  }

  // Get all saved user accounts
  Future<List<Map<String, String>>> getUserAccounts() async {
    final accountsJson = await _secureStorage.read(key: _userAccountsKey);
    if (accountsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      final result = decoded
          .map((account) => {
                'userId': (account['userId'] ?? '').toString(),
                'email': (account['email'] ?? '').toString(),
                'displayName': (account['displayName'] ?? '').toString(),
                'authType': (account['authType'] ?? 'password').toString(),
                // Include password if it exists
                //if (account['password'] != null) //REDUNDANT
                //  'password': account['password'].toString(),
                // Extract firstName from displayName if available
                if ((account['displayName'] ?? '').toString().isNotEmpty)
                  'firstName': (account['displayName'] ?? '')
                      .toString()
                      .split(' ')
                      .first,
              })
          .toList();

      // debugPrint(
      //     'CredentialService.getUserAccounts: found ${result.length} accounts');
      // debugPrint(
      //     'CredentialService.getUserAccounts: account details: ${result.map((a) => "${a['email']}: displayName=${a['displayName']}, firstName=${a['firstName']}").join(', ')}');

      return result;
    } catch (e) {
      debugPrint('Error parsing user accounts: $e');
      return [];
    }
  }

  // Remove a specific user account
  Future<void> removeUserAccount(String userId) async {
    // Remove from accounts list
    final accounts = await getUserAccounts();
    final updatedAccounts =
        accounts.where((account) => account['userId'] != userId).toList();

    await _secureStorage.write(
        key: _userAccountsKey, value: jsonEncode(updatedAccounts));

    // Remove stored token
    await _secureStorage.delete(key: _tokenPrefix + userId);

    // If we removed the active user, set a new active user if available
    final currentActiveId = await getActiveUserId();
    if (currentActiveId == userId && updatedAccounts.isNotEmpty) {
      await setActiveUser(updatedAccounts[0]['userId']!);
    }
  }

  Future<void> addUserAccount(
      String email, String? password, String authType) async {
    final accounts = await getUserAccounts();

    // Check if account exists by email
    final existingIndex =
        accounts.indexWhere((account) => account['email'] == email);

    // Check if account exists by userId (for accounts where email might have changed)
    final userId = await getUserIdForEmail(email);
    final existingIndexById = userId != null
        ? accounts.indexWhere((account) => account['userId'] == userId)
        : -1;

    // Determine if we have an existing account and which index to use
    final hasExistingAccount = existingIndex >= 0 || existingIndexById >= 0;
    final indexToUpdate =
        existingIndex >= 0 ? existingIndex : existingIndexById;

    final Map<String, String> accountData = {
      'email': email,
      'authType': authType,
    };

    // Only add password if provided and not empty
    if (password != null && password.isNotEmpty) {
      accountData['password'] = password;
      _savePassword(email, password);
    }

    if (hasExistingAccount) {
      // Keep the userId if it exists
      if (accounts[indexToUpdate].containsKey('userId')) {
        accountData['userId'] = accounts[indexToUpdate]['userId']!;
      }
      // Keep the displayName if it exists
      if (accounts[indexToUpdate].containsKey('displayName')) {
        accountData['displayName'] = accounts[indexToUpdate]['displayName']!;
      }

      // Remove any potential duplicate if we're updating by userId
      if (existingIndex >= 0 &&
          existingIndexById >= 0 &&
          existingIndex != existingIndexById) {
        // We have two entries - remove one of them
        accounts.removeAt(existingIndexById);
      }

      accounts[indexToUpdate] = accountData;
    } else {
      accounts.add(accountData);
    }

    await _secureStorage.write(
        key: _userAccountsKey, value: jsonEncode(accounts));
  }

  Future<Map<String, String>?> getAccountDetails(String email) async {
    final accounts = await getUserAccounts();
    final account = accounts.firstWhere(
      (account) => account['email'] == email,
      orElse: () => {},
    );
    if (account.isEmpty) return null;

    final password = await _getPassword(email);
    if (password != null) {
      account['password'] = password;
    }
    return account;
  }

  Future<String?> getUserIdForEmail(String email) async {
    final accounts = await getUserAccounts();
    final account = accounts.firstWhere(
      (account) => account['email'] == email,
      orElse: () => {},
    );
    return account['userId'];
  }

  Future<String?> getActiveUserEmail() async {
    final activeUserId = await getActiveUserId();
    if (activeUserId == null) return null;

    final accounts = await getUserAccounts();
    final account = accounts.firstWhere(
      (account) => account['userId'] == activeUserId,
      orElse: () => {},
    );
    return account['email'];
  }

  // Add a utility method to clean up duplicate accounts
  Future<void> cleanupDuplicateAccounts() async {
    final accounts = await getUserAccounts();
    final Set<String> emails = {};
    final Set<String> userIds = {};
    final List<Map<String, String>> uniqueAccounts = [];

    for (var account in accounts) {
      final email = account['email'];
      final userId = account['userId'];

      // Only add the account if we haven't seen this email or userId before
      if ((email != null && !emails.contains(email)) ||
          (userId != null && !userIds.contains(userId))) {
        // Remember we've seen this email and userId
        if (email != null) emails.add(email);
        if (userId != null) userIds.add(userId);

        uniqueAccounts.add(account);
      }
    }

    if (uniqueAccounts.length < accounts.length) {
      // We removed duplicates, save the cleaned list
      await _secureStorage.write(
          key: _userAccountsKey, value: jsonEncode(uniqueAccounts));

      print(
          'Removed ${accounts.length - uniqueAccounts.length} duplicate accounts');
    }
  }

  Future<void> clearActiveUser() async {
    final activeUserId = await getActiveUserId();
    final activeEmail = await getActiveUserEmail();
    if (activeUserId != null) {
      // Remove the active user's token
      await _secureStorage.delete(key: _tokenPrefix + activeUserId);
      // Clear the active user ID
      await setActiveUser("");
      debugPrint('Cleared active user: $activeEmail');
    }
  }
}
