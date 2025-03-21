import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_aggregates.dart';
import '../models/log.dart';
import '../services/log_repository.dart';
import './auth_provider.dart';
import './firebase_providers.dart'; // Add this import

// Repository provider with Firebase initialization
final logRepositoryProvider = Provider<LogRepository>((ref) {
  // Wait for Firebase to be initialized
  final isInitialized = ref.watch(firebaseInitializerProvider).value ?? false;
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      final repo = LogRepository(user?.uid ?? '');
      // If we have a valid user and Firebase is initialized, start sync service
      if (user != null && isInitialized) {
        repo.startSyncService();
      }
      return repo;
    },
    loading: () => LogRepository(''),
    error: (_, __) => LogRepository(''),
  );
}, dependencies: [
  firebaseInitializerProvider,
  authStateProvider
]); // Declare dependencies

// Stream of logs with better error handling
final logsStreamProvider = StreamProvider<List<Log>>((ref) {
  final repository = ref.watch(logRepositoryProvider);

  // First try to get cached logs
  try {
    return repository.streamLogs();
  } catch (e) {
    print('Error loading logs stream: $e');
    return Stream.value([]);
  }
});

// Computed aggregates using the updated LogAggregates model.
final logAggregatesProvider = Provider<LogAggregates>((ref) {
  final logsAsyncValue = ref.watch(logsStreamProvider);
  return logsAsyncValue.when(
    data: (logs) => LogAggregates.fromLogs(logs),
    loading: () => LogAggregates(
        lastHit: DateTime.now(), totalSecondsToday: 0, thcContent: 0.0),
    error: (_, __) => LogAggregates(
        lastHit: DateTime.now(), totalSecondsToday: 0, thcContent: 0.0),
  );
});

// Add new provider for selected log if needed
final selectedLogProvider = StateProvider<Log?>((ref) => null);
