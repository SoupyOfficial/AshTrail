import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log.dart';
import '../domain/use_cases/thc_calculator.dart'; // For basic THC model
import '../domain/models/thc_advanced_model.dart'; // For advanced THC model
import 'log_providers.dart';

// Provider for user demographic settings
final userAgeProvider = Provider<int>((ref) => 30);
final userSexProvider = Provider<String>((ref) => "male");
final userBodyFatProvider = Provider<double>((ref) => 15.0);
final userCaloricBurnProvider = Provider<double>((ref) => 2000.0);

// Keep track of which logs have been processed
final _processedLogIdsProvider = StateProvider<Set<String>>((ref) => {});

// Single persistent THC model instance
final thcModelProvider = Provider<THCModelNoMgInput>((ref) {
  return THCModelNoMgInput(
    ageYears: ref.watch(userAgeProvider),
    sex: ref.watch(userSexProvider),
    bodyFatPercent: ref.watch(userBodyFatProvider),
    dailyCaloricBurn: ref.watch(userCaloricBurnProvider),
  );
});

// Advanced THC content provider
final liveThcContentProvider = StreamProvider<double>((ref) {
  final controller = StreamController<double>();
  final model = ref.watch(thcModelProvider);
  final processedLogIds = ref.watch(_processedLogIdsProvider);

  // Watch the logs stream to process new logs only once
  ref.listen<AsyncValue<List<Log>>>(logsStreamProvider, (_, logsAsync) {
    logsAsync.whenData((logs) {
      // Find and process only new logs
      for (final log in logs) {
        if (!processedLogIds.contains(log.id)) {
          ref
              .read(_processedLogIdsProvider.notifier)
              .update((state) => {...state, log.id!});

          // Process this log with the persistent model
          model.logInhalation(
            timestamp: log.timestamp,
            method: ConsumptionMethod.joint,
            inhaleDurationSec: log.durationSeconds,
            perceivedStrength: log.potencyRating != null
                ? (log.potencyRating! / 5.0).clamp(0.25, 2.0)
                : 1.0,
          );
        }
      }
    });
  });

  // Update timer - restore original frequency for better responsiveness
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    // Calculate THC content at current time for proper decay
    final currentTHC = model.getTHCContentAtTime(DateTime.now());
    controller.add(currentTHC);
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// Basic THC content provider - optimized with similar approach
final basicThcContentProvider = StreamProvider<double>((ref) {
  final controller = StreamController<double>();

  // Create a persistent calculator instance
  final calculator = THCConcentration(logs: []);

  // Process logs just once
  ref.listen<AsyncValue<List<Log>>>(logsStreamProvider, (_, logsAsync) {
    logsAsync.whenData((logs) {
      // Update the calculator with all logs
      calculator.updateLogs(logs);
    });
  });

  // Update timer - restore original frequency
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    final currentTHC = calculator
        .calculateTHCAtTime(DateTime.now().millisecondsSinceEpoch.toDouble());
    controller.add(currentTHC);
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
