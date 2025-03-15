import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) return null;

  final userProfileService = ref.read(userProfileServiceProvider);
  return userProfileService.getUserProfile();
});

final userStatisticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final userProfileService = ref.read(userProfileServiceProvider);
  return userProfileService.getUserStatistics();
});
