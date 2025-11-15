import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/credential_service.dart';
import '../../services/token_service.dart';
import '../../core/interfaces/firebase_auth_interface.dart';

/// Service responsible for managing authentication tokens
/// Single Responsibility: Token storage, retrieval, and custom token management
class TokenManagementService {
  final IFirebaseAuth _auth;
  final CredentialService _credentialService;
  final TokenService _tokenService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  TokenManagementService(
    this._auth,
    this._credentialService,
    this._tokenService,
  );

  /// Store Firebase ID token and timestamp
  Future<void> storeFirebaseToken(User user) async {
    try {
      final idToken = await user.getIdToken(true);
      await _secureStorage.write(
        key: 'firebase_id_token_${user.uid}',
        value: idToken,
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(
        key: 'firebase_token_timestamp_${user.uid}',
        value: timestamp,
      );
      debugPrint('Stored Firebase token for ${user.email}');
    } catch (e) {
      debugPrint('Error storing Firebase token: $e');
    }
  }

  /// Get stored Firebase token
  Future<String?> getStoredFirebaseToken(String userId) async {
    return await _secureStorage.read(key: 'firebase_id_token_$userId');
  }

  /// Get stored Firebase token timestamp
  Future<String?> getStoredFirebaseTokenTimestamp(String userId) async {
    return await _secureStorage.read(key: 'firebase_token_timestamp_$userId');
  }

  /// Check if stored Firebase token is still valid (not older than 45 minutes)
  Future<bool> isStoredTokenValid(String userId) async {
    final tokenTimestamp = await getStoredFirebaseTokenTimestamp(userId);
    if (tokenTimestamp == null) return false;

    try {
      final tokenAge = DateTime.now().millisecondsSinceEpoch -
          int.parse(tokenTimestamp);
      return tokenAge < 45 * 60 * 1000; // 45 minutes
    } catch (e) {
      debugPrint('Error checking token validity: $e');
      return false;
    }
  }

  /// Obtain and store custom token for a user
  Future<void> obtainAndStoreCustomToken(User user) async {
    try {
      debugPrint('Obtaining custom token for user ${user.uid}');
      final tokenData = await _tokenService.generateCustomToken(user.uid);
      final customToken = tokenData['customToken'] as String;

      // Store the custom token
      await _credentialService.storeCustomToken(user.uid, customToken);

      // Re-authenticate with the custom token for longer session
      await _auth.signInWithCustomToken(customToken);
      debugPrint('Successfully authenticated with custom token');
    } catch (e) {
      debugPrint('Error obtaining custom token: $e');
      // Continue without custom token - user is still logged in with normal auth
    }
  }

  /// Store OAuth token for a user
  Future<void> storeOAuthToken(String email, Map<String, dynamic> tokenData) async {
    await _credentialService.storeOAuthToken(email, tokenData);
  }

  /// Get stored OAuth token
  Future<Map<String, dynamic>?> getOAuthToken(String email) async {
    return await _credentialService.getOAuthToken(email);
  }

  /// Remove OAuth token
  Future<void> removeOAuthToken(String email) async {
    await _credentialService.removeOAuthToken(email);
  }
}

