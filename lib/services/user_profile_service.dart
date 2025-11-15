import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Service responsible for user profile operations
/// Follows Dependency Inversion Principle by requiring dependencies
class UserProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Constructor requires dependencies - no default to direct instance access
  UserProfileService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  Future<UserProfile?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // Create a default profile if none exists
      final defaultProfile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        firstName: user.displayName?.split(' ').first ?? 'User',
        lastName: user.displayName?.split(' ').skip(1).join(' '),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await updateUserProfile(defaultProfile);
      return defaultProfile;
    }

    return UserProfile.fromMap(user.uid, doc.data()!);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Update profile data in Firestore
    await _firestore.collection('users').doc(user.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );

    // Update display name in Firebase Auth if first or last name changed
    if (profile.firstName.isNotEmpty) {
      final lastName = profile.lastName != null && profile.lastName!.isNotEmpty
          ? ' ${profile.lastName}'
          : '';
      final displayName = profile.firstName + lastName;

      debugPrint(
          'Updating user displayName from "${user.displayName}" to "$displayName" as fallback');

      if (user.displayName != displayName) {
        // Update displayName as a fallback, but our app will primarily use firstName from Firestore
        await user.updateDisplayName(displayName);
        debugPrint('DisplayName updated successfully (used as fallback only)');
      } else {
        debugPrint('DisplayName already matches, no update needed');
      }
    }

    // Update email in Firebase Auth if email changed
    if (user.email != profile.email) {
      await user.updateEmail(profile.email);
    }
  }

  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    if (user.email == null) throw Exception('User has no email');

    // Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update the password
    await user.updatePassword(newPassword);
  }

  Future<void> disableAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Mark the account as inactive in Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'isActive': false,
    });
  }

  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    if (user.email == null) throw Exception('User has no email');

    // Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    // Delete user data from Firestore
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete all logs for this user
    await _deleteAllUserData(user.uid);

    // Delete the user account from Firebase Auth
    await user.delete();
  }

  Future<void> deleteAllUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _deleteAllUserData(user.uid);
  }

  Future<void> _deleteAllUserData(String userId) async {
    // Use the correct path to logs - ensure this matches your log repository
    final logPath = 'users/$userId/logs';
    final logsDocs = await _firestore.collection(logPath).get();

    final batch = _firestore.batch();

    for (final doc in logsDocs.docs) {
      batch.delete(doc.reference);
    }

    // Delete reason options and other user-specific data
    final reasonOptionsDoc = _firestore.collection('options').doc(userId);
    if ((await reasonOptionsDoc.get()).exists) {
      batch.delete(reasonOptionsDoc);
    }

    await batch.commit();
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Use the correct path to logs - ensure this matches your log repository
    final logPath = 'users/${user.uid}/logs';

    // Get log count - handle potential errors gracefully
    int logCount = 0;
    try {
      final countQuery = await _firestore.collection(logPath).count().get();
      logCount = countQuery.count ?? 0;
    } catch (e) {
      print('Error getting log count: $e');
    }

    // Get first log date
    DateTime? firstLogDate;
    try {
      final firstLogQuery = await _firestore
          .collection(logPath)
          .orderBy('timestamp', descending: false)
          .limit(1)
          .get();

      if (firstLogQuery.docs.isNotEmpty &&
          firstLogQuery.docs.first.data().containsKey('timestamp')) {
        // Safely convert to DateTime with fallback
        final timestampData = firstLogQuery.docs.first.data()['timestamp'];
        if (timestampData is Timestamp) {
          firstLogDate = timestampData.toDate();
        } else {
          // Try to parse as DateTime, or use default date
          try {
            firstLogDate = timestampData is DateTime
                ? timestampData
                : DateTime.parse(timestampData.toString());
          } catch (_) {
            // Use null - caller will handle formatting
          }
        }
      }
    } catch (e) {
      print('Error getting first log date: $e');
    }

    // Calculate total duration
    double totalDuration = 0;
    try {
      final logsQuery = await _firestore.collection(logPath).get();

      for (final doc in logsQuery.docs) {
        final data = doc.data();
        // Handle both potential field names for duration
        if (data.containsKey('durationSeconds')) {
          totalDuration += (data['durationSeconds'] as num).toDouble();
        } else if (data.containsKey('length')) {
          totalDuration += (data['length'] as num).toDouble();
        }
      }
    } catch (e) {
      print('Error calculating total duration: $e');
    }

    return {
      'logCount': logCount,
      'firstLogDate': firstLogDate,
      'totalDuration': totalDuration,
    };
  }

  Future<String> exportUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user profile
    final profile = await getUserProfile();

    // Use the correct path to logs - ensure this matches your log repository
    final logPath = 'users/${user.uid}/logs';

    // Get user logs
    final logsDocs = await _firestore.collection(logPath).get();
    final logs = logsDocs.docs.map((doc) => doc.data()).toList();

    // Format as JSON
    final exportData = {
      'profile': profile?.toMap(),
      'logs': logs,
      'exportDate': DateTime.now().toIso8601String(),
    };

    // Convert to JSON string
    return exportData.toString();
  }
}
