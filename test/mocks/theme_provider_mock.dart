import 'package:flutter/material.dart';
import 'package:smoke_log/theme/theme_provider.dart';

class MockThemeProvider extends ThemeProvider {
  bool _isDarkMode;
  Color _accentColor;

  MockThemeProvider({
    bool isDarkMode = false,
    Color accentColor = Colors.blue,
  })  : _isDarkMode = isDarkMode,
        _accentColor = accentColor;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  Color get accentColor => _accentColor;

  @override
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  @override
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
  }
}
