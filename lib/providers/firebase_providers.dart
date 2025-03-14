import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

// Provides the initialization status of Firebase
final firebaseInitializerProvider = FutureProvider<bool>((ref) async {
  if (!isFirebaseInitialized && !isScreenshotMode) {
    await initializeFirebase();
  }
  return isFirebaseInitialized;
});

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  // Force dependency on the initializer
  ref.watch(firebaseInitializerProvider);
  return FirebaseFirestore.instance;
});
