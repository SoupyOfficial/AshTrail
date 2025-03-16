import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/log.dart';
import 'sync_service.dart';
import 'cache_service.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  late final SyncService _syncService;
  late final CacheService _cacheService;
  bool _syncServiceStarted = false;
  bool _initialized = false;

  // Cache configuration
  static const Duration cacheFreshness = Duration(hours: 12);

  LogRepository(this.userId) {
    // Only initialize sync service if userId is not empty
    if (userId.isNotEmpty) {
      _syncService = SyncService(_firestore, userId);
      _cacheService = CacheService(); // Get singleton instance
      _init();
    } else {
      // Create a dummy sync service for empty userId
      _syncService = SyncService.empty();
      _cacheService = CacheService();
    }
  }

  Future<void> _init() async {
    if (_initialized || userId.isEmpty) return;

    // Initialize cache service
    await _cacheService.init();

    // Start sync service only if userId is not empty
    if (userId.isNotEmpty) {
      _syncService.startPeriodicSync();
    }

    _initialized = true;
  }

  SyncService get syncService => _syncService;

  CollectionReference<Map<String, dynamic>>? get _userLogsCollection {
    // Only return the collection reference if userId is not empty
    if (userId.isEmpty) return null;
    return _firestore.collection('users').doc(userId).collection('logs');
  }

  void startSyncService() {
    if (_syncServiceStarted || userId.isEmpty) return;
    _syncService.startPeriodicSync();
    _syncServiceStarted = true;
  }

  // Add log with offline support and update cache
  Future<void> addLog(Log log) async {
    // Don't attempt to save if userId is empty
    if (userId.isEmpty) {
      throw Exception('Cannot add log: User not authenticated');
    }

    try {
      final collection = _userLogsCollection;
      if (collection == null) return;

      final docRef = await collection.add(log.toMap());

      // Update the log with its ID
      final logWithId = log.copyWith(id: docRef.id);

      // Update the cache
      await _cacheService.addOrUpdateLog(logWithId);

      // Try to sync immediately if possible, but don't wait for it
      _syncService.syncWithServer().catchError((_) {});
    } catch (e) {
      // Handle offline cases
      if (e is FirebaseException && e.code == 'unavailable') {
        // Firestore SDK will auto-queue the write when connection returns
        print('Network unavailable, operation queued for sync');

        // Still update local cache even if offline
        if (log.id != null) {
          await _cacheService.addOrUpdateLog(log);
        }
      } else {
        rethrow;
      }
    }
  }

  // Stream logs with cache first, server update
  Stream<List<Log>> streamLogs({bool cacheOnly = false}) {
    // If userId is empty, return empty stream
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    // Check if we have fresh cached logs first
    if (_cacheService.isLogsCacheFresh()) {
      print('Using in-memory logs cache');
      // Return a single-value stream with cached logs
      final cachedLogs = _cacheService.getAllLogs();

      // If we only want cached data or we're offline, return just the cache
      if (cacheOnly) {
        return Stream.value(cachedLogs);
      }

      // Otherwise, combine the cache stream with the Firestore stream
      // This gives immediate data from cache, then updates from Firestore
      return StreamGroup.merge([
        Stream.value(cachedLogs),
        _getFirestoreLogsStream(),
      ]);
    }

    // If cache isn't fresh, get from Firestore
    return _getFirestoreLogsStream();
  }

  // Internal method to get logs from Firestore as a stream
  Stream<List<Log>> _getFirestoreLogsStream() {
    if (userId.isEmpty || _userLogsCollection == null) {
      return Stream.value([]);
    }

    final query = _userLogsCollection!.orderBy('timestamp', descending: true);

    return query.snapshots(includeMetadataChanges: true).map((snapshot) {
      // Check if we're getting data from cache or server
      final isFromCache = snapshot.metadata.isFromCache;
      print('Getting logs from ${isFromCache ? "cache" : "server"}');

      final logs =
          snapshot.docs.map((doc) => Log.fromMap(doc.data(), doc.id)).toList();

      // Update our cache whenever we get new data from Firestore
      _cacheService.updateLogsCache(logs);

      return logs;
    }).handleError((error) {
      print('Error in streamLogs: $error');

      // If there's an error, try to serve from cache
      final cachedLogs = _cacheService.getAllLogs();
      if (cachedLogs.isNotEmpty) {
        return cachedLogs;
      }

      // Fall back to an empty list in case of error
      return <Log>[];
    });
  }

  // Get logs from cache first, then server if needed
  Future<List<Log>> getLogs({Source source = Source.cache}) async {
    // If userId is empty, return empty list
    if (userId.isEmpty) {
      return [];
    }

    // If cache is fresh and the source is cache, return from memory cache
    if (source == Source.cache && _cacheService.isLogsCacheFresh()) {
      return _cacheService.getAllLogs();
    }

    try {
      final snapshot = await _userLogsCollection!
          .orderBy('timestamp', descending: true)
          .get(GetOptions(source: source));

      final logs =
          snapshot.docs.map((doc) => Log.fromMap(doc.data(), doc.id)).toList();

      // Update cache
      await _cacheService.updateLogsCache(logs);

      return logs;
    } catch (e) {
      if (e is FirebaseException &&
          e.code == 'unavailable' &&
          source == Source.cache) {
        // If cache read fails, try server
        return getLogs(source: Source.server);
      }

      // If any other error, try to return from memory cache
      final cachedLogs = _cacheService.getAllLogs();
      if (cachedLogs.isNotEmpty) {
        return cachedLogs;
      }

      rethrow;
    }
  }

  // Update with optimistic UI approach and cache update
  Future<void> updateLog(Log log) async {
    if (log.id == null) throw Exception('Log ID is null');

    // Don't attempt to update if userId is empty
    if (userId.isEmpty) {
      throw Exception('Cannot update log: User not authenticated');
    }

    // Update cache immediately for optimistic UI
    await _cacheService.addOrUpdateLog(log);

    try {
      await _userLogsCollection!.doc(log.id).update(log.toMap());
      // Try to sync immediately if possible
      _syncService.syncWithServer().catchError((_) {});
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        // Operation will be queued automatically by Firestore SDK
        print('Network unavailable, update queued for sync');
      } else {
        rethrow;
      }
    }
  }

  // Delete with optimistic UI approach and cache update
  Future<void> deleteLog(String logId) async {
    // Don't attempt to delete if userId is empty
    if (userId.isEmpty) {
      throw Exception('Cannot delete log: User not authenticated');
    }

    // Remove from cache immediately for optimistic UI
    await _cacheService.removeLog(logId);

    try {
      await _userLogsCollection!.doc(logId).delete();
      // Try to sync immediately if possible
      _syncService.syncWithServer().catchError((_) {});
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        // Operation will be queued automatically by Firestore SDK
        print('Network unavailable, deletion queued for sync');
      } else {
        rethrow;
      }
    }
  }

  // Force a refresh from the server
  Future<List<Log>> refreshLogs() async {
    return getLogs(source: Source.server);
  }

  // Check if we have cached data
  Future<bool> hasCachedLogs() async {
    // If userId is empty, return false
    if (userId.isEmpty) {
      return false;
    }

    // First check in-memory cache
    final inMemoryLogs = _cacheService.getAllLogs();
    if (inMemoryLogs.isNotEmpty && _cacheService.isLogsCacheFresh()) {
      return true;
    }

    // Then check Firestore cache
    try {
      final snapshot = await _userLogsCollection!
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Batch operations for efficiency
  Future<void> batchUpdateLogs(List<Log> logs) async {
    // Don't attempt to batch update if userId is empty
    if (userId.isEmpty) {
      throw Exception('Cannot batch update logs: User not authenticated');
    }

    final batch = _firestore.batch();

    // Update cache for all logs
    for (final log in logs) {
      if (log.id == null) continue;
      batch.update(_userLogsCollection!.doc(log.id), log.toMap());
      await _cacheService.addOrUpdateLog(log);
    }

    await batch.commit();
  }

  // Force manual sync with server
  Future<void> syncNow() => _syncService.syncWithServer();

  // Cleanup resources
  void dispose() {
    _syncService.dispose();
  }

  Future<bool> transferLogToUser(String logId, String targetUserId) async {
    if (userId.isEmpty || targetUserId.isEmpty || logId.isEmpty) {
      return false;
    }

    try {
      // Get the log document
      final logDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .get();

      if (!logDoc.exists) {
        return false;
      }

      // Create a new log in the target user's collection
      final logData = logDoc.data()!;
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('logs')
          .doc(logId)
          .set(logData);

      // Delete the log from the current user's collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .delete();

      // Force sync to ensure changes propagate
      await syncService.syncWithServer();

      return true;
    } catch (e) {
      debugPrint('Error transferring log: $e');
      return false;
    }
  }
}

// Helper class for merging streams
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>();

    final subscriptions = <StreamSubscription>[];

    for (final stream in streams) {
      final subscription = stream.listen(
        (data) => controller.add(data),
        onError: (e, st) => controller.addError(e, st),
      );
      subscriptions.add(subscription);
    }

    controller.onCancel = () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }
}
