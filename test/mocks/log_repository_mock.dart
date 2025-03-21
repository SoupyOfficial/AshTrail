import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:smoke_log/models/log.dart';
import 'package:smoke_log/services/log_repository.dart';
import 'package:smoke_log/services/sync_service.dart';

class MockSyncService extends Mock implements SyncService {
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  MockSyncService() {
    _syncStatusController.add(SyncStatus.synced);
  }

  @override
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  void setStatus(SyncStatus status) {
    _syncStatusController.add(status);
  }

  @override
  void dispose() {
    _syncStatusController.close();
  }
}

class MockLogRepository extends Mock implements LogRepository {
  final List<Log> _logs;
  final _logsStreamController = StreamController<List<Log>>.broadcast();
  final MockSyncService _syncService = MockSyncService();

  MockLogRepository([this._logs = const []]) {
    _logsStreamController.add(_logs);
  }

  @override
  SyncService get syncService => _syncService;

  @override
  Stream<List<Log>> streamLogs({bool cacheOnly = false}) {
    return _logsStreamController.stream;
  }

  @override
  Future<List<Log>> getLogs({Source source = Source.cache}) async {
    return _logs;
  }

  @override
  Future<void> addLog(Log log) async {
    final newLogs = [..._logs, log.copyWith(id: 'auto-id-${_logs.length}')];
    _logsStreamController.add(newLogs);
  }

  @override
  Future<void> deleteLog(String logId) async {
    final newLogs = _logs.where((log) => log.id != logId).toList();
    _logsStreamController.add(newLogs);
  }

  void dispose() {
    _logsStreamController.close();
    _syncService.dispose();
  }
}
