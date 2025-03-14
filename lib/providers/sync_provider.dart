import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_repository.dart';
import '../services/sync_service.dart';
import 'log_providers.dart';

// Provides access to the sync service through the log repository
final syncServiceProvider = Provider<SyncService>((ref) {
  final logRepo = ref.watch(logRepositoryProvider);
  return logRepo.syncService;
});

// Stream of sync status updates
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatus;
});
