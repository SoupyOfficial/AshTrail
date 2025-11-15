import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import '../core/di/dependency_injection.dart';
import '../presentation/providers/auth_providers.dart';

/// Provider for UserProfileService with dependency injection
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final firestore = ref.watch(firebaseFirestoreInstanceDirectProvider);
  final auth = ref.watch(firebaseAuthInstanceProvider);
  return UserProfileService(
    firestore: firestore,
    auth: auth,
  );
});

/// Provider for current user profile
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;

  final userProfileService = ref.read(userProfileServiceProvider);
  return userProfileService.getUserProfile();
});

final userStatisticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final userProfileService = ref.read(userProfileServiceProvider);
  return userProfileService.getUserStatistics();
});
