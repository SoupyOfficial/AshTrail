import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle local storage of theme preferences
class ThemePreferenceService {
  static const String _themePreferenceKey = 'is_dark_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _lastUserIdKey =
      'last_user_id'; // New key for tracking last user

  /// Load dark mode preference from local storage
  Future<bool> loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themePreferenceKey) ?? false;
  }

  /// Save dark mode preference to local storage
  Future<void> saveDarkModePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDarkMode);
  }

  /// Load accent color from local storage
  Future<Color> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_accentColorKey);
    return colorValue != null ? Color(colorValue) : Colors.blue;
  }

  /// Save accent color to local storage
  Future<void> saveAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
  }

  /// Save the ID of the last logged-in user
  Future<void> saveLastUserId(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString(_lastUserIdKey, userId);
    } else {
      await prefs.remove(_lastUserIdKey);
    }
  }

  /// Get the ID of the last logged-in user
  Future<String?> getLastUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUserIdKey);
  }
}
