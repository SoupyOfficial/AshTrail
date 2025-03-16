import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// Assuming you have database providers
// If you don't, this would need to be adjusted to match your database implementation
class DatabaseTestHelper {
  late FakeFirebaseFirestore fakeFirestore;
  late ProviderContainer container;

  DatabaseTestHelper() {
    fakeFirestore = FakeFirebaseFirestore();

    // Setup your container with overrides for database providers
    // This is an example - adjust to match your actual database providers
    container = ProviderContainer(
      overrides: [
        // Example: databaseProvider.overrideWithValue(fakeFirestore),
      ],
    );
  }

  // Helper method to populate test data
  Future<void> populateTestData({
    required String collectionPath,
    required List<Map<String, dynamic>> documents,
  }) async {
    final collection = fakeFirestore.collection(collectionPath);
    for (final doc in documents) {
      await collection.add(doc);
    }
  }

  // Helper to clear test data
  Future<void> clearCollection(String collectionPath) async {
    final snapshot = await fakeFirestore.collection(collectionPath).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  void dispose() {
    container.dispose();
  }
}
