import 'package:mockito/mockito.dart';
import 'package:smoke_log/models/user_profile.dart';
import 'package:smoke_log/services/user_profile_service.dart';

class MockUserProfileService extends Mock implements UserProfileService {
  final UserProfile? _profile;

  MockUserProfileService([this._profile]);

  @override
  Future<UserProfile?> getUserProfile() async {
    if (_profile != null) return _profile;

    return UserProfile(
      uid: 'test-uid',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, dynamic>> getUserStatistics() async {
    return {
      'logCount': 42,
      'firstLogDate': DateTime.now().subtract(const Duration(days: 30)),
      'totalDuration': 3600.0,
    };
  }
}
