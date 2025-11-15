import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smoke_log/main.dart'; // Import to check if Firebase is initialized
import 'theme_preference_service.dart';

/// Service to handle cloud storage and synchronization of user theme settings
/// Follows Dependency Inversion Principle by requiring dependencies
class UserThemeService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final ThemePreferenceService _localPreferenceService;
  bool _isSyncingFromCloud = false;

  /// Constructor requires dependencies
  /// firestore and auth are optional to support screenshot mode and testing
  UserThemeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ThemePreferenceService? localPreferenceService,
  }) : _firestore = firestore,
        _auth = auth,
        _localPreferenceService = localPreferenceService ?? ThemePreferenceService();

  /// The current logged in user
  User? get currentUser => _auth?.currentUser;

  /// Load theme settings, always returning local preferences first for speed,
  /// then updating from cloud in the background if a user is logged in
  Future<Map<String, dynamic>> loadThemeSettings() async {
    // Always load from local preferences first for immediate UI rendering
    bool isDarkMode = await _localPreferenceService.loadDarkModePreference();
    Color accentColor = await _localPreferenceService.loadAccentColor();

    // If Firebase services aren't available, just return local settings
    if (_firestore == null || _auth == null) {
      return {
        'isDarkMode': isDarkMode,
        'accentColor': accentColor,
      };
    }

    // Store current user as the last user
    if (currentUser != null) {
      await _localPreferenceService.saveLastUserId(currentUser!.uid);
    }

    // If user is logged in, try to load from cloud in the background
    if (currentUser != null && !_isSyncingFromCloud) {
      _isSyncingFromCloud = true;

      _loadFromCloud().then((cloudSettings) {
        if (cloudSettings != null) {
          // If cloud settings were successfully loaded and are different,
          // update local preferences and notify listeners
          final cloudIsDarkMode = cloudSettings['isDarkMode'] ?? false;
          final cloudAccentColor = cloudSettings['accentColor'] as Color?;

          bool settingsChanged = false;

          if (cloudIsDarkMode != isDarkMode) {
            _localPreferenceService.saveDarkModePreference(cloudIsDarkMode);
            settingsChanged = true;
          }

          if (cloudAccentColor != null && cloudAccentColor != accentColor) {
            _localPreferenceService.saveAccentColor(cloudAccentColor);
            settingsChanged = true;
          }

          // The parent ThemeProvider will need to listen for these changes
          if (settingsChanged) {
            _themeChangedController.add(null);
          }
        }
        _isSyncingFromCloud = false;
      }).catchError((e) {
        print('Error loading cloud theme settings: $e');
        _isSyncingFromCloud = false;
      });
    }

    return {
      'isDarkMode': isDarkMode,
      'accentColor': accentColor,
    };
  }

  /// Private method to load settings from cloud
  Future<Map<String, dynamic>?> _loadFromCloud() async {
    if (_firestore == null || currentUser == null) {
      return null;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('settings')
          .doc('theme')
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final isDarkMode = data['isDarkMode'] ?? false;

        Color accentColor = Colors.blue;
        if (data['accentColorValue'] != null) {
          accentColor = Color(data['accentColorValue']);
        }

        return {
          'isDarkMode': isDarkMode,
          'accentColor': accentColor,
        };
      }
    } catch (e) {
      print('Error loading cloud theme settings: $e');
    }
    return null;
  }

  /// Save theme settings to cloud if user is logged in
  Future<void> saveThemeSettings(bool isDarkMode, Color accentColor) async {
    // Always save to local preferences
    await _localPreferenceService.saveDarkModePreference(isDarkMode);
    await _localPreferenceService.saveAccentColor(accentColor);

    // If Firebase services aren't available, just return after saving locally
    if (_firestore == null || _auth == null) {
      return;
    }

    // Save last user ID
    if (currentUser != null) {
      await _localPreferenceService.saveLastUserId(currentUser!.uid);
    }

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

  /// Add a stream controller to notify about theme changes
  final _themeChangedController = StreamController<void>.broadcast();
  Stream<void> get onThemeChanged => _themeChangedController.stream;

  void dispose() {
    _themeChangedController.close();
  }
}
