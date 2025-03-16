import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_preference_service.dart';
import '../services/user_theme_service.dart';

/// Provider for the theme preference service
final themePreferenceServiceProvider = Provider<ThemePreferenceService>((ref) {
  return ThemePreferenceService();
});

/// Provider for the user theme service
final userThemeServiceProvider = Provider<UserThemeService>((ref) {
  final preferenceService = ref.watch(themePreferenceServiceProvider);
  return UserThemeService(localPreferenceService: preferenceService);
});
