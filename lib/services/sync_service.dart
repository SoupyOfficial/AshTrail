import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final FirebaseFirestore _firestore;
  final String userId;
  Timer? _syncTimer;
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  // Default sync interval: 5 minutes
  static const Duration defaultSyncInterval = Duration(minutes: 5);

  SyncService(this._firestore, this.userId);

  // Factory constructor for creating an empty sync service
  factory SyncService.empty() {
    final emptyService = SyncService(FirebaseFirestore.instance, '');
    // Initialize with noUser status
    emptyService._syncStatusController.add(SyncStatus.noUser);
    return emptyService;
  }

  void startPeriodicSync({Duration interval = defaultSyncInterval}) {
    // Cancel any existing timer
    stopPeriodicSync();

    // Start new periodic sync
    _syncTimer = Timer.periodic(interval, (_) => syncWithServer());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncWithServer() async {
    // Don't try to sync if there's no user
    if (userId.isEmpty) {
      _syncStatusController.add(SyncStatus.noUser);
      return;
    }

    // Notify listeners that sync started
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncStatusController.add(SyncStatus.offline);
        return;
      }

      // Force a server read to sync any pending writes
      // This leverages Firebase's automatic sync when online
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .get(const GetOptions(source: Source.server));

      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      if (kDebugMode) {
        print('Sync error: $e');
      }
    }
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void dispose() {
    stopPeriodicSync();
    _syncStatusController.close();
  }
}

enum SyncStatus { syncing, synced, offline, error, noUser }
