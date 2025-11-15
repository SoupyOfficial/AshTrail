import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smoke_log/models/log.dart';
import 'package:smoke_log/services/log_repository.dart';
import 'package:smoke_log/services/cache_service.dart';
import 'package:mockito/mockito.dart';

class MockCacheService extends Mock implements CacheService {
  final Map<String, Log> _logs = {};

  @override
  Future<void> init() async {}

  @override
  bool isLogsCacheFresh() => true;

  @override
  List<Log> getAllLogs() => _logs.values.toList();

  @override
  Future<void> addOrUpdateLog(Log log) async {
    _logs[log.id!] = log;
  }

  @override
  Future<void> removeLog(String logId) async {
    _logs.remove(logId);
  }

  @override
  Future<void> updateLogsCache(List<Log> logs) async {
    _logs.clear();
    for (final log in logs) {
      if (log.id != null) {
        _logs[log.id!] = log;
      }
    }
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late LogRepository logRepository;
  late MockCacheService mockCacheService;
  const String testUserId = 'test-user-id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockCacheService = MockCacheService();

    // Inject the mock cache service
    logRepository = LogRepository(testUserId);
    // Hack to replace the cache service
    // Note: In a real app, you'd use dependency injection
    // logRepository._cacheService = mockCacheService;
  });

  group('LogRepository', () {
    test('should add a log', () async {
      // Arrange
      final log = Log(
        timestamp: DateTime.now(),
        durationSeconds: 10.0,
        potencyRating: null,
      );

      // Act
      await logRepository.addLog(log);

      // Assert - check in Firestore
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('logs')
          .get();

      expect(snapshot.docs.length, equals(1));

      // Check log properties
      final savedLog = Log.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
      expect(savedLog.durationSeconds, equals(10.0));
    });

    test('should retrieve logs as a stream', () async {
      // Arrange
      final log1 = Log(
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        durationSeconds: 5.0,
        potencyRating: null,
      );
      final log2 = Log(
        timestamp: DateTime.now(),
        durationSeconds: 8.0,
        potencyRating: null,
      );

      await logRepository.addLog(log1);
      await logRepository.addLog(log2);

      // Act
      final logStream = logRepository.streamLogs();

      // Assert
      expect(
        logStream,
        emits(predicate<List<Log>>((logs) => logs.length == 2)),
      );
    });

    test('should delete a log', () async {
      // Arrange
      final log = Log(
        timestamp: DateTime.now(),
        durationSeconds: 3.0,
        potencyRating: null,
      );

      // Add log first
      await logRepository.addLog(log);
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('logs')
          .get();
      final logId = snapshot.docs.first.id;

      // Act
      await logRepository.deleteLog(logId);

      // Assert
      final updatedSnapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('logs')
          .get();
      expect(updatedSnapshot.docs.length, equals(0));
    });

    test('should update a log', () async {
      // Arrange
      final log = Log(
        timestamp: DateTime.now(),
        durationSeconds: 3.0,
        potencyRating: null,
      );

      // Add log first
      await logRepository.addLog(log);
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('logs')
          .get();
      final logId = snapshot.docs.first.id;

      final updatedLog = Log.fromMap(
        snapshot.docs.first.data(),
        logId,
      ).copyWith(durationSeconds: 7.0);

      // Act
      await logRepository.updateLog(updatedLog);

      // Assert
      final updatedSnapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('logs')
          .get();
      final retrievedLog = Log.fromMap(
        updatedSnapshot.docs.first.data(),
        updatedSnapshot.docs.first.id,
      );
      expect(retrievedLog.durationSeconds, equals(7.0));
    });
  });
}
