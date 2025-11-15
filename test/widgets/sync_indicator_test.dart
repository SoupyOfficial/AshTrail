import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/widgets/sync_indicator.dart';
import 'package:smoke_log/presentation/providers/log_providers.dart';
import 'package:smoke_log/services/sync_service.dart';
import '../mocks/log_repository_mock.dart';
import '../helpers/firebase_test_helper.dart'; // Import the Firebase test helper

void main() {
  late MockSyncService mockSyncService;

  setUpAll(() async {
    // Setup Firebase mocks before all tests
    await FirebaseTestHelper.setupFirebaseMocks();
  });

  setUp(() {
    mockSyncService = MockSyncService();
  });

  tearDown(() {
    mockSyncService.dispose();
  });

  group('SyncIndicator', () {
    testWidgets('should show spinner when syncing',
        (WidgetTester tester) async {
      // Arrange
      mockSyncService.setStatus(SyncStatus.syncing);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((_) => mockSyncService.syncStatus),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncIndicator(),
            ),
          ),
        ),
      );

      // Initial build
      await tester.pump();

      // Assert - check for spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show checkmark when synced',
        (WidgetTester tester) async {
      // Arrange
      mockSyncService.setStatus(SyncStatus.synced);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((_) => mockSyncService.syncStatus),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncIndicator(),
            ),
          ),
        ),
      );

      // Initial build
      await tester.pump();

      // Assert - check for checkmark icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should show cloud_off when offline',
        (WidgetTester tester) async {
      // Arrange
      mockSyncService.setStatus(SyncStatus.offline);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((_) => mockSyncService.syncStatus),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncIndicator(),
            ),
          ),
        ),
      );

      // Initial build
      await tester.pump();

      // Assert - check for offline icon
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('should transition between states',
        (WidgetTester tester) async {
      // Arrange - start syncing
      mockSyncService.setStatus(SyncStatus.syncing);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((_) => mockSyncService.syncStatus),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncIndicator(),
            ),
          ),
        ),
      );

      // Initial build
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Change to synced
      mockSyncService.setStatus(SyncStatus.synced);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200)); // Animation time

      // Assert - should now show checkmark
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
