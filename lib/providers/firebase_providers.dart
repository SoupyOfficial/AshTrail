import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

// A provider that tracks whether Firebase has been initialized
final firebaseInitializerProvider = FutureProvider<bool>((ref) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    // In tests or environments where Firebase isn't available,
    // we'll handle the error gracefully
    print('Firebase initialization error: $e');
    return false;
  }
});

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  // Force dependency on the initializer
  ref.watch(firebaseInitializerProvider);
  return FirebaseFirestore.instance;
});
