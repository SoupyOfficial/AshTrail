import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for user account operations
/// Follows Dependency Inversion Principle by requiring dependencies
class UserAccountService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Constructor requires dependencies - no default to direct instance access
  UserAccountService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  /// Get the current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Fetch enriched account information with names from Firestore
  Future<List<Map<String, dynamic>>> getEnrichedAccounts(
      List<Map<String, dynamic>> basicAccounts) async {
    final enrichedAccounts = <Map<String, dynamic>>[];
    final firstNameCount = <String, int>{};

    // First pass: collect all first names and their counts
    for (final account in basicAccounts) {
      final userId = account['userId'];
      final enrichedAccount = Map<String, dynamic>.from(account);

      if (userId != null) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists) {
            final firstName = userDoc.data()?['firstName'];
            if (firstName != null && firstName.toString().isNotEmpty) {
              enrichedAccount['firstName'] = firstName;
              // Count occurrences of each firstName for uniqueness check
              firstNameCount[firstName.toString()] =
                  (firstNameCount[firstName.toString()] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Error fetching user document: $e');
        }
      }

      enrichedAccounts.add(enrichedAccount);
    }

    // Second pass: add hasUniqueName property
    for (final account in enrichedAccounts) {
      final firstName = account['firstName'];
      if (firstName != null) {
        account['hasUniqueName'] = firstNameCount[firstName] == 1;
      }
    }

    return enrichedAccounts;
  }

  /// Switch to another user account
  Future<void> switchAccount(String email) async {
    // This is a placeholder - the actual implementation will be in AuthService
    throw UnimplementedError(
        'This method should be called from AuthService instead');
  }
}
