import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_theme_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  Color _accentColor = Colors.blue;
  bool _isInitialized = false;

  final UserThemeService _themeService;
  final FirebaseAuth _auth;
  User? _currentUser;

  ThemeProvider({
    UserThemeService? themeService,
    FirebaseAuth? auth,
  })  : _themeService = themeService ?? UserThemeService(),
        _auth = auth ?? FirebaseAuth.instance {
    _initializeTheme();

    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      final bool userChanged = (_currentUser?.uid != user?.uid);
      _currentUser = user;

      if (userChanged) {
        // User changed, reload preferences
        _loadThemePreference();
      }
    });

    // Listen for theme changes from background sync
    _themeService.onThemeChanged.listen((_) {
      _loadThemePreference();
    });
  }

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isInitialized => _isInitialized;

  /// Initialize theme synchronously as much as possible
  void _initializeTheme() async {
    // Set a default immediately to avoid flickering
    _isDarkMode = false;
    _accentColor = Colors.blue;

    // Then load preferences as soon as possible
    await _loadThemePreference();
    _isInitialized = true;
  }

  /// Explicitly reload theme preferences from storage
  /// This is useful after user account switches
  Future<void> reloadPreferences() async {
    await _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final themeSettings = await _themeService.loadThemeSettings();

    final newIsDarkMode = themeSettings['isDarkMode'] ?? false;
    final newAccentColor = themeSettings['accentColor'] ?? Colors.blue;

    // Only notify if theme actually changed
    if (newIsDarkMode != _isDarkMode || newAccentColor != _accentColor) {
      _isDarkMode = newIsDarkMode;
      _accentColor = newAccentColor;
      notifyListeners();
    }
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
