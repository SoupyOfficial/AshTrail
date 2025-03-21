import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:mockito/mockito.dart';

// Mock for FirebaseApp
class MockFirebaseApp extends Mock implements FirebaseApp {
  @override
  String get name => '[DEFAULT]';
}

// Setup Firebase mocks
class FirebaseTestHelper {
  static Future<void> setupFirebaseMocks() async {
    // Setup mock for FirebasePlatform
    TestWidgetsFlutterBinding.ensureInitialized();

    // Register a mock Firebase implementation
    setupFirebaseCoreMocks();
  }

  static Future<MockFirebaseAuth> getMockFirebaseAuth({
    bool signedIn = true,
    String uid = 'test-uid',
    String email = 'test@example.com',
    String displayName = 'Test User',
  }) async {
    await setupFirebaseMocks();

    final user = MockUser(
      isAnonymous: false,
      uid: uid,
      email: email,
      displayName: displayName,
    );

    return MockFirebaseAuth(
      mockUser: signedIn ? user : null,
      signedIn: signedIn,
    );
  }

  static MockGoogleSignIn getMockGoogleSignIn() {
    return MockGoogleSignIn();
  }
}

// Mock implementation for Firebase Core
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock MethodChannel for Firebase Core
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_core');
  channel.setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'mock-api-key',
            'appId': 'mock-app-id',
            'messagingSenderId': 'mock-sender-id',
            'projectId': 'mock-project-id',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    return null;
  });

  // Mock Platform Interface
  final platformApp = MockFirebaseApp();
  when(platformApp.name).thenReturn('[DEFAULT]');

  // Register the mock Firebase platform
  FirebasePlatform.instance =
      TestFirebasePlatformImplementation(appInstance: platformApp);
}

// Implementation of TestFirebasePlatform
class TestFirebasePlatformImplementation extends FirebasePlatform {
  TestFirebasePlatformImplementation({required this.appInstance});

  final FirebaseApp appInstance;

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return appInstance as FirebaseAppPlatform;
  }
}
