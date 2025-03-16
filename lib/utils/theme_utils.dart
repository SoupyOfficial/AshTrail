import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

/// Reload theme preferences for the given context
/// Call this after user account switching
Future<void> reloadThemePreferences(BuildContext context) async {
  try {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.reloadPreferences();
  } catch (e) {
    debugPrint('Error reloading theme preferences: $e');
  }
}
