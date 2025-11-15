import '../../models/log.dart';

/// Interface for cache service operations
abstract class ICacheService {
  /// Initialize the cache
  Future<void> init();

  /// Get all logs from cache
  List<Log> getAllLogs();

  /// Check if logs cache is fresh
  bool isLogsCacheFresh();

  /// Update logs cache with new logs
  Future<void> updateLogsCache(List<Log> logs);

  /// Get a specific log by ID
  Log? getLogById(String id);

  /// Add or update a single log
  Future<void> addOrUpdateLog(Log log);

  /// Remove a log by ID
  Future<void> removeLog(String id);

  /// Clear the entire cache
  Future<void> clearCache();
}

