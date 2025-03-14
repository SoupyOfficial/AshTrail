import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:smoke_log/firebase_options.dart';

Future<void> cloneUserLogs(
    String sourceUserId, String destinationUserId) async {
  final firestore = FirebaseFirestore.instance;

  // Reference to the source user's logs collection
  final sourceLogsRef =
      firestore.collection('users').doc(sourceUserId).collection('logs');

  // Read all documents from the source user's logs collection
  final sourceSnapshot = await sourceLogsRef.get();

  if (sourceSnapshot.docs.isEmpty) {
    print('No logs found for source user $sourceUserId');
    return;
  }

  // Reference to the destination user's logs collection
  final destinationLogsRef =
      firestore.collection('users').doc(destinationUserId).collection('logs');

  // Start a write batch
  final batch = firestore.batch();

  // Delete existing documents in the destination user's logs collection
  final existingLogs = await destinationLogsRef.get();
  for (var doc in existingLogs.docs) {
    batch.delete(doc.reference);
  }

  // For each document in source logs collection, prepare and copy to destination
  for (var doc in sourceSnapshot.docs) {
    final data = doc.data();

    // Handle either 'length' or 'durationSeconds' field
    final durationSeconds = data.containsKey('length')
        ? (data['length'] ?? 0).toInt()
        : (data['durationSeconds'] ?? 0);

    // Use the existing notes field if present, otherwise add a default note
    final notes = data.containsKey('notes')
        ? data['notes']
        : 'Cloned from user $sourceUserId';

    // Prepare the new log data
    final newLogData = {
      'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
      'durationSeconds': durationSeconds,
      'reason': data['reason'] ?? '',
      'moodRating': data['moodRating'] ?? 0.0,
      'physicalRating': data['physicalRating'] ?? 0.0,
      'notes': notes,
      'potencyRating': data['potencyRating'] ?? 0,
    };

    // Use the same document ID to preserve any relationships
    batch.set(
        destinationLogsRef.doc(doc.id), newLogData, SetOptions(merge: true));
  }

  // Commit all batched writes
  await batch.commit();
  print(
      'Cloned ${sourceSnapshot.docs.length} documents from user $sourceUserId to user $destinationUserId logs.');
}

Future<void> main(List<String> args) async {
  // Check for source and destination user IDs as command line arguments
  if (args.length < 2) {
    // print(
    //     'Usage: dart run lib/scripts/clone_user_logs.dart <sourceUserId> <destinationUserId>');

    // For testing, you can uncomment and use default values:
    args = ['dITGZvTvcQOWllfaGvl6P6v6ACG3', '1Wu1BALZOiXlGHtzuVgCEic0Ecw1'];
    print(
        'No user IDs provided. Using default values for testing: sourceUserId=dITGZvTvcQOWllfaGvl6P6v6ACG3, destinationUserId=1Wu1BALZOiXlGHtzuVgCEic0Ecw1');
  }

  final sourceUserId = args[0];
  final destinationUserId = args[1];

  // Initialize Flutter bindings and Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print(
      'Starting to clone logs from user $sourceUserId to user $destinationUserId');

  await cloneUserLogs(sourceUserId, destinationUserId);
}
