import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_preference_service.dart';
import '../services/user_theme_service.dart';
import '../core/di/dependency_injection.dart';

/// Provider for the theme preference service
final themePreferenceServiceProvider = Provider<ThemePreferenceService>((ref) {
  return ThemePreferenceService();
});

/// Provider for the user theme service with dependency injection
final userThemeServiceProvider = Provider<UserThemeService>((ref) {
  final preferenceService = ref.watch(themePreferenceServiceProvider);
  final firestore = ref.watch(firebaseFirestoreInstanceDirectProvider);
  final auth = ref.watch(firebaseAuthInstanceProvider);
  return UserThemeService(
    firestore: firestore,
    auth: auth,
    localPreferenceService: preferenceService,
  );
});
