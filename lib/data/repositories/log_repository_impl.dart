import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/log.dart';
import '../../domain/repositories/log_repository_interface.dart';
import '../../domain/interfaces/sync_service_interface.dart';
import '../../domain/interfaces/cache_service_interface.dart';

/// Implementation of ILogRepository
/// Handles data access for logs with caching and sync support
/// Follows Dependency Inversion Principle by accepting dependencies through constructor
class LogRepositoryImpl implements ILogRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final ISyncService _syncService;
  final ICacheService _cacheService;
  bool _syncServiceStarted = false;
  bool _initialized = false;

  /// Constructor with dependency injection
  /// [firestore] - Firebase Firestore instance
  /// [userId] - Current user ID
  /// [syncService] - Sync service for data synchronization
  /// [cacheService] - Cache service for local data caching
  LogRepositoryImpl(
    this._firestore,
    this.userId,
    this._syncService,
    this._cacheService,
  ) {
    if (userId.isNotEmpty) {
      _init();
    }
  }

  Future<void> _init() async {
    if (_initialized || userId.isEmpty) return;

    await _cacheService.init();

    if (userId.isNotEmpty) {
      _syncService.startPeriodicSync();
    }

    _initialized = true;
  }

  /// Expose sync service for providers that need direct access
  /// Note: This exposes the concrete type for backward compatibility
  /// In the future, this should be removed and sync should be handled through the repository interface
  ISyncService get syncService => _syncService;

  CollectionReference<Map<String, dynamic>>? get _userLogsCollection {
    if (userId.isEmpty) return null;
    return _firestore.collection('users').doc(userId).collection('logs');
  }

  void startSyncService() {
    if (_syncServiceStarted || userId.isEmpty) return;
    _syncService.startPeriodicSync();
    _syncServiceStarted = true;
  }

  @override
  Future<void> addLog(Log log) async {
    if (userId.isEmpty) {
      throw Exception('Cannot add log: User not authenticated');
    }

    try {
      final collection = _userLogsCollection;
      if (collection == null) return;

      final docRef = await collection.add(log.toMap());
      final logWithId = log.copyWith(id: docRef.id);

      await _cacheService.addOrUpdateLog(logWithId);
      _syncService.syncWithServer().catchError((_) {});
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        print('Network unavailable, operation queued for sync');
        if (log.id != null) {
          await _cacheService.addOrUpdateLog(log);
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Stream<List<Log>> streamLogs({bool cacheOnly = false}) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    if (_cacheService.isLogsCacheFresh()) {
      print('Using in-memory logs cache');
      final cachedLogs = _cacheService.getAllLogs();

      if (cacheOnly) {
        return Stream.value(cachedLogs);
      }

      return StreamGroup.merge([
        Stream.value(cachedLogs),
        _getFirestoreLogsStream(),
      ]);
    }

    return _getFirestoreLogsStream();
  }

  Stream<List<Log>> _getFirestoreLogsStream() {
    if (userId.isEmpty || _userLogsCollection == null) {
      return Stream.value([]);
    }

    final query = _userLogsCollection!.orderBy('timestamp', descending: true);

    return query.snapshots(includeMetadataChanges: true).map((snapshot) {
      final isFromCache = snapshot.metadata.isFromCache;
      print('Getting logs from ${isFromCache ? "cache" : "server"}');

      final logs =
          snapshot.docs.map((doc) => Log.fromMap(doc.data(), doc.id)).toList();

      _cacheService.updateLogsCache(logs);

      return logs;
    }).handleError((error) {
      print('Error in streamLogs: $error');

      final cachedLogs = _cacheService.getAllLogs();
      if (cachedLogs.isNotEmpty) {
        return cachedLogs;
      }

      return <Log>[];
    });
  }

  @override
  Future<List<Log>> getLogs({Source source = Source.cache}) async {
    if (userId.isEmpty) {
      return [];
    }

    if (source == Source.cache && _cacheService.isLogsCacheFresh()) {
      return _cacheService.getAllLogs();
    }

    try {
      final snapshot = await _userLogsCollection!
          .orderBy('timestamp', descending: true)
          .get(GetOptions(source: source));

      final logs =
          snapshot.docs.map((doc) => Log.fromMap(doc.data(), doc.id)).toList();

      await _cacheService.updateLogsCache(logs);

      return logs;
    } catch (e) {
      if (e is FirebaseException &&
          e.code == 'unavailable' &&
          source == Source.cache) {
        return getLogs(source: Source.server);
      }

      final cachedLogs = _cacheService.getAllLogs();
      if (cachedLogs.isNotEmpty) {
        return cachedLogs;
      }

      rethrow;
    }
  }

  @override
  Future<void> updateLog(Log log) async {
    if (log.id == null) throw Exception('Log ID is null');

    if (userId.isEmpty) {
      throw Exception('Cannot update log: User not authenticated');
    }

    await _cacheService.addOrUpdateLog(log);

    try {
      await _userLogsCollection!.doc(log.id).update(log.toMap());
      _syncService.syncWithServer().catchError((_) {});
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        print('Network unavailable, update queued for sync');
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteLog(String logId) async {
    if (userId.isEmpty) {
      throw Exception('Cannot delete log: User not authenticated');
    }

    await _cacheService.removeLog(logId);

    try {
      await _userLogsCollection!.doc(logId).delete();
      _syncService.syncWithServer().catchError((_) {});
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        print('Network unavailable, deletion queued for sync');
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<List<Log>> refreshLogs() async {
    return getLogs(source: Source.server);
  }

  @override
  Future<bool> hasCachedLogs() async {
    if (userId.isEmpty) {
      return false;
    }

    final inMemoryLogs = _cacheService.getAllLogs();
    if (inMemoryLogs.isNotEmpty && _cacheService.isLogsCacheFresh()) {
      return true;
    }

    try {
      final snapshot = await _userLogsCollection!
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> batchUpdateLogs(List<Log> logs) async {
    if (userId.isEmpty) {
      throw Exception('Cannot batch update logs: User not authenticated');
    }

    final batch = _firestore.batch();

    for (final log in logs) {
      if (log.id == null) continue;
      batch.update(_userLogsCollection!.doc(log.id), log.toMap());
      await _cacheService.addOrUpdateLog(log);
    }

    await batch.commit();
  }

  @override
  Future<void> syncNow() => _syncService.syncWithServer();

  @override
  void dispose() {
    _syncService.dispose();
  }

  @override
  Future<bool> transferLogToUser(String logId, String targetUserId) async {
    if (userId.isEmpty || targetUserId.isEmpty || logId.isEmpty) {
      return false;
    }

    try {
      final logDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .get();

      if (!logDoc.exists) {
        return false;
      }

      final logData = logDoc.data()!;
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('logs')
          .doc(logId)
          .set(logData);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .delete();

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

