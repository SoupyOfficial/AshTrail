import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_repository.dart';
import '../services/sync_service.dart';
import 'log_providers.dart';
import 'auth_provider.dart'; // Add this import

// Provides access to the sync service through the log repository
final syncServiceProvider = Provider<SyncService>((ref) {
  final logRepo = ref.watch(logRepositoryProvider);
  final syncService = logRepo.syncService;

  // Ensure the SyncService is disposed when the provider is disposed
  ref.onDispose(() async {
    await Future.microtask(() {
      syncService.stopPeriodicSync(); // Ensure the timer is stopped
      syncService.dispose(); // Dispose of the SyncService
    });
  });

  return syncService;
}, dependencies: [logRepositoryProvider]); // Declare dependency

// Stream of sync status updates
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatus;
}, dependencies: [
  syncServiceProvider,
  authStateProvider
]); // Declare dependencies
