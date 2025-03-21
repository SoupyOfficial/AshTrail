import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smoke_log/models/user_profile.dart';
import 'package:smoke_log/services/user_profile_service.dart';
import '../mocks/auth_service_mock.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late UserProfileService userProfileService;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    when(mockAuth.currentUser).thenReturn(mockUser);

    userProfileService = UserProfileService(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('UserProfileService', () {
    //Working
    test('should create default profile if none exists', () async {
      // Act
      final profile = await userProfileService.getUserProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile!.uid, equals(mockUser.uid));
      expect(profile.email, equals(mockUser.email));

      // Verify profile was saved to Firestore
      final doc =
          await fakeFirestore.collection('users').doc(mockUser.uid).get();
      expect(doc.exists, isTrue);
    });

    test('should update user profile', () async {
      // Arrange
      final profile = UserProfile(
        uid: mockUser.uid,
        email: mockUser.email!,
        firstName: 'Updated',
        lastName: 'Name',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Act
      await userProfileService.updateUserProfile(profile);

      // Assert
      final doc =
          await fakeFirestore.collection('users').doc(mockUser.uid).get();
      expect(doc.data()!['firstName'], equals('Updated'));
      expect(doc.data()!['lastName'], equals('Name'));
    });

    //Working
    test('should get user statistics', () async {
      // Arrange
      final now = DateTime.now();
      final logRef = fakeFirestore.collection('users/${mockUser.uid}/logs');

      // Add some test logs
      await logRef.add({
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'durationSeconds': 10.0,
      });

      await logRef.add({
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'durationSeconds': 15.0,
      });

      // Act
      final stats = await userProfileService.getUserStatistics();

      // Assert
      expect(stats['logCount'], equals(2));
      expect(stats['totalDuration'], equals(25.0));
      expect(stats['firstLogDate'], isA<DateTime>());
    });
  });
}
