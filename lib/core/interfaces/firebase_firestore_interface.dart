import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for Firebase Firestore operations
/// This abstraction allows for easier testing and potential future implementations
abstract class IFirebaseFirestore {
  CollectionReference<Map<String, dynamic>> collection(String path);
  Future<void> enablePersistence({
    bool persistenceEnabled = true,
    int cacheSizeBytes = Settings.CACHE_SIZE_UNLIMITED,
  });
}

/// Wrapper implementation for FirebaseFirestore
class FirebaseFirestoreWrapper implements IFirebaseFirestore {
  final FirebaseFirestore _firestore;

  FirebaseFirestoreWrapper(this._firestore);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);

  @override
  Future<void> enablePersistence({
    bool persistenceEnabled = true,
    int cacheSizeBytes = Settings.CACHE_SIZE_UNLIMITED,
  }) async {
    _firestore.settings = Settings(
      persistenceEnabled: persistenceEnabled,
      cacheSizeBytes: cacheSizeBytes,
    );
  }
}

