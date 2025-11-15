import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for managing user documents in Firestore
/// Single Responsibility: User document CRUD operations
class UserDocumentService {
  final FirebaseFirestore _firestore;

  UserDocumentService(this._firestore);

  /// Ensure a user document exists in Firestore
  Future<void> ensureUserDocument(UserCredential credential) async {
    try {
      final userDoc = _firestore.collection('users').doc(credential.user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        debugPrint('Creating new user document for ${credential.user!.email}');
        await userDoc.set({
          'email': credential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'authType': credential.credential?.signInMethod ?? 'password',
        });
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
      // Don't throw here - we want authentication to succeed even if this fails
    }
  }

  /// Create or update Firestore user document with additional data
  Future<void> createOrUpdateUserDocument(
    String userId, {
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final data = <String, dynamic>{
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (email != null) data['email'] = email;
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;

      await userDoc.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating/updating user document: $e');
    }
  }

  /// Delete user document from Firestore
  Future<void> deleteUserDocument(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('Deleted user document for $userId');
    } catch (e) {
      debugPrint('Error deleting user document: $e');
      rethrow;
    }
  }
}

