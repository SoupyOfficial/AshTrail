import '../../models/log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for log repository operations
/// This defines the contract for log data access
abstract class ILogRepository {
  /// Stream logs with optional cache-only mode
  Stream<List<Log>> streamLogs({bool cacheOnly = false});

  /// Get logs from a specific source
  Future<List<Log>> getLogs({Source source = Source.cache});

  /// Add a new log
  Future<void> addLog(Log log);

  /// Update an existing log
  Future<void> updateLog(Log log);

  /// Delete a log by ID
  Future<void> deleteLog(String logId);

  /// Force refresh logs from server
  Future<List<Log>> refreshLogs();

  /// Check if cached logs are available
  Future<bool> hasCachedLogs();

  /// Batch update multiple logs
  Future<void> batchUpdateLogs(List<Log> logs);

  /// Force manual sync with server
  Future<void> syncNow();

  /// Transfer a log to another user
  Future<bool> transferLogToUser(String logId, String targetUserId);

  /// Cleanup resources
  void dispose();
}

