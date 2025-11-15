import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';
import '../interfaces/firebase_auth_interface.dart';
import '../interfaces/firebase_firestore_interface.dart';
import '../../services/credential_service.dart';
import '../../services/cache_service.dart';
import '../../services/token_service.dart';

/// Global flag to track if Firebase is initialized
bool isFirebaseInitialized = false;

/// Initialize Firebase with proper configuration
Future<void> initializeFirebase() async {
  if (isFirebaseInitialized) return;

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Only after successful initialization, configure Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    isFirebaseInitialized = true;
    print('Firebase initialized with offline persistence enabled');
  } catch (e) {
    print('Error initializing Firebase: $e');
    rethrow;
  }
}

/// Provider for Firebase initialization status
final firebaseInitializerProvider = FutureProvider<bool>((ref) async {
  try {
    await initializeFirebase();
    return true;
  } catch (e) {
    print('Firebase initialization error: $e');
    return false;
  }
});

/// Provider for FirebaseAuth instance
final firebaseAuthInstanceProvider = Provider<FirebaseAuth>((ref) {
  ref.watch(firebaseInitializerProvider);
  return FirebaseAuth.instance;
});

/// Provider for IFirebaseAuth wrapper
final firebaseAuthProvider = Provider<IFirebaseAuth>((ref) {
  final auth = ref.watch(firebaseAuthInstanceProvider);
  return FirebaseAuthWrapper(auth);
});

/// Provider for FirebaseFirestore instance
final firebaseFirestoreInstanceProvider = Provider<FirebaseFirestore>((ref) {
  ref.watch(firebaseInitializerProvider);
  return FirebaseFirestore.instance;
});

/// Provider for IFirebaseFirestore wrapper
final firebaseFirestoreProvider = Provider<IFirebaseFirestore>((ref) {
  final firestore = ref.watch(firebaseFirestoreInstanceProvider);
  return FirebaseFirestoreWrapper(firestore);
});

/// Provider for FirebaseFirestore instance (for direct access when needed)
final firebaseFirestoreInstanceDirectProvider = Provider<FirebaseFirestore>((ref) {
  ref.watch(firebaseInitializerProvider);
  return FirebaseFirestore.instance;
});

/// Provider for GoogleSignIn
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    clientId:
        '660497517730-an04u70e9dfg71meco3ev6gvcri684hk.apps.googleusercontent.com',
  );
});

/// Provider for CredentialService
final credentialServiceProvider = Provider<CredentialService>((ref) {
  return CredentialService();
});

/// Provider for CacheService (singleton)
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Provider for TokenService
final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

