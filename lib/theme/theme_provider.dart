import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_theme_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  Color _accentColor = Colors.blue;

  final UserThemeService _themeService;
  final FirebaseAuth _auth;
  User? _currentUser;

  ThemeProvider({
    UserThemeService? themeService,
    FirebaseAuth? auth,
  })  : _themeService = themeService ?? UserThemeService(),
        _auth = auth ?? FirebaseAuth.instance {
    _loadThemePreference();

    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      final bool userChanged = (_currentUser?.uid != user?.uid);
      _currentUser = user;

      if (userChanged) {
        // User changed, reload preferences
        _loadThemePreference();
      }
    });
  }

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Explicitly reload theme preferences from storage
  /// This is useful after user account switches
  Future<void> reloadPreferences() async {
    await _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final themeSettings = await _themeService.loadThemeSettings();

    _isDarkMode = themeSettings['isDarkMode'] ?? false;
    _accentColor = themeSettings['accentColor'] ?? Colors.blue;

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _themeService.saveThemeSettings(_isDarkMode, _accentColor);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _themeService.saveThemeSettings(_isDarkMode, _accentColor);
    notifyListeners();
  }
}
