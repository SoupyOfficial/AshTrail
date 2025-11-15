/// Interface for sync service operations
abstract class ISyncService {
  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatus;

  /// Start periodic sync with optional interval
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)});

  /// Stop periodic sync
  void stopPeriodicSync();

  /// Force sync with server
  Future<void> syncWithServer();

  /// Check if device is online
  Future<bool> isOnline();

  /// Cleanup resources
  void dispose();
}

/// Sync status enumeration
enum SyncStatus {
  syncing,
  synced,
  offline,
  error,
  noUser,
}

