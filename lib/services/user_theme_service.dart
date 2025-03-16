import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_preference_service.dart';

/// Service to handle cloud storage and synchronization of user theme settings
class UserThemeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ThemePreferenceService _localPreferenceService;

  UserThemeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ThemePreferenceService? localPreferenceService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localPreferenceService =
            localPreferenceService ?? ThemePreferenceService();

  /// The current logged in user
  User? get currentUser => _auth.currentUser;

  /// Load theme settings, prioritizing cloud if available
  Future<Map<String, dynamic>> loadThemeSettings() async {
    bool isDarkMode = false;
    Color accentColor = Colors.blue;

    // First try to load from cloud if user is logged in
    if (currentUser != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('settings')
            .doc('theme')
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          isDarkMode = data['isDarkMode'] ?? false;

          if (data['accentColorValue'] != null) {
            accentColor = Color(data['accentColorValue']);
          }

          // Update local preferences to match cloud
          await _localPreferenceService.saveDarkModePreference(isDarkMode);
          await _localPreferenceService.saveAccentColor(accentColor);

          return {
            'isDarkMode': isDarkMode,
            'accentColor': accentColor,
          };
        }
      } catch (e) {
        print('Error loading cloud theme settings: $e');
      }
    }

    // Fallback to local preferences
    isDarkMode = await _localPreferenceService.loadDarkModePreference();
    accentColor = await _localPreferenceService.loadAccentColor();

    // If user is logged in but no cloud settings existed, push to cloud
    if (currentUser != null) {
      await saveThemeSettings(isDarkMode, accentColor);
    }

    return {
      'isDarkMode': isDarkMode,
      'accentColor': accentColor,
    };
  }

  /// Save theme settings to cloud if user is logged in
  Future<void> saveThemeSettings(bool isDarkMode, Color accentColor) async {
    // Always save to local preferences
    await _localPreferenceService.saveDarkModePreference(isDarkMode);
    await _localPreferenceService.saveAccentColor(accentColor);

    // Save to cloud if user is logged in
    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('settings')
            .doc('theme')
            .set({
          'isDarkMode': isDarkMode,
          'accentColorValue': accentColor.value,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving theme settings to cloud: $e');
      }
    }
  }
}
