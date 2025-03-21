import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/models/log.dart';
import 'package:smoke_log/providers/log_providers.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import 'package:smoke_log/providers/firebase_providers.dart';
import '../mocks/log_repository_mock.dart';
import '../mocks/auth_service_mock.dart';
import '../helpers/firebase_test_helper.dart'; // Import the Firebase test helper

void main() {
  late ProviderContainer container;
  late MockLogRepository mockLogRepository;
  late MockUser mockUser;

  setUpAll(() async {
    // Setup Firebase mocks before all tests
    await FirebaseTestHelper.setupFirebaseMocks();
  });

  setUp(() {
    mockUser = MockUser();

    // Create a mock repository with sample logs
    final sampleLogs = [
      Log(
        id: 'log1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        durationSeconds: 10.0,
        reason: ['Relaxation'],
        moodRating: 7,
        physicalRating: 6,
        potencyRating: 0,
      ),
      Log(
        id: 'log2',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        durationSeconds: 15.0,
        reason: ['Medicinal'],
        moodRating: 8,
        physicalRating: 7,
        potencyRating: 0,
      ),
    ];
    mockLogRepository = MockLogRepository(sampleLogs);

    container = ProviderContainer(
      overrides: [
        // Override Firebase initializer to return true
        firebaseInitializerProvider.overrideWith((_) => Future.value(true)),

        // Auth provider override to provide a user
        authStateProvider.overrideWith((_) => Stream.value(mockUser)),

        // Override the log repository provider
        logRepositoryProvider.overrideWithValue(mockLogRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    mockLogRepository.dispose();
  });

  group('Log Providers', () {
    test('logsStreamProvider should stream logs', () async {
      // Act
      final logsAsync = container.read(logsStreamProvider);

      // Assert
      expect(logsAsync.value!.length, equals(2));
    });

    test('logAggregatesProvider should calculate aggregates correctly',
        () async {
      // Act
      final aggregates = container.read(logAggregatesProvider);

      // Assert
      expect(aggregates.totalSecondsToday, equals(25.0)); // sum of durations
    });

    test('adding a log should update the logs stream', () async {
      // Arrange
      final newLog = Log(
        timestamp: DateTime.now(),
        durationSeconds: 5.0,
        potencyRating: null,
      );

      // Act
      await mockLogRepository.addLog(newLog);

      // Wait for the stream to emit
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - check the provider contains the new log
      final logsAsync = container.read(logsStreamProvider);
      expect(logsAsync.value!.length, equals(3));
    });
  });
}
