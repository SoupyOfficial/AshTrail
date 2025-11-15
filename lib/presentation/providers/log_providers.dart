import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/log_aggregates.dart';
import '../../models/log.dart';
import '../../domain/repositories/log_repository_interface.dart';
import '../../data/repositories/log_repository_impl.dart';
import '../../core/di/dependency_injection.dart';
import '../../services/sync_service.dart' hide SyncStatus;
import '../../domain/interfaces/sync_service_interface.dart';
import 'auth_providers.dart';

/// Repository provider with Firebase initialization and dependency injection
/// Follows Dependency Inversion Principle by injecting dependencies
final logRepositoryProvider = Provider<ILogRepository>((ref) {
  final isInitialized = ref.watch(firebaseInitializerProvider).value ?? false;
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firebaseFirestoreInstanceDirectProvider);
  final cacheService = ref.watch(cacheServiceProvider);

  return authState.when(
    data: (user) {
      final userId = user?.uid ?? '';
      // Create sync service for the user
      final syncService = userId.isNotEmpty
          ? SyncService(firestore, userId)
          : SyncService.empty();
      
      final repo = LogRepositoryImpl(
        firestore,
        userId,
        syncService,
        cacheService,
      );
      
      if (user != null && isInitialized) {
        repo.startSyncService();
      }
      return repo;
    },
    loading: () {
      final syncService = SyncService.empty();
      return LogRepositoryImpl(firestore, '', syncService, cacheService);
    },
    error: (_, __) {
      final syncService = SyncService.empty();
      return LogRepositoryImpl(firestore, '', syncService, cacheService);
    },
  );
});

/// Stream of logs with better error handling
final logsStreamProvider = StreamProvider<List<Log>>((ref) {
  final repository = ref.watch(logRepositoryProvider);

  try {
    return repository.streamLogs();
  } catch (e) {
    print('Error loading logs stream: $e');
    return Stream.value([]);
  }
});

/// Computed aggregates using the updated LogAggregates model
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

/// Provider for selected log
final selectedLogProvider = StateProvider<Log?>((ref) => null);

/// Provides access to the sync service through the log repository
/// Returns ISyncService interface for better abstraction
final syncServiceProvider = Provider<ISyncService>((ref) {
  final logRepo = ref.watch(logRepositoryProvider);
  // Access syncService through the implementation
  if (logRepo is LogRepositoryImpl) {
    final syncService = logRepo.syncService;
    
    ref.onDispose(() async {
      await Future.microtask(() {
        syncService.stopPeriodicSync();
        syncService.dispose();
      });
    });
    
    return syncService;
  }
  throw Exception('LogRepository implementation does not expose syncService');
});

/// Stream of sync status updates
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatus;
});

