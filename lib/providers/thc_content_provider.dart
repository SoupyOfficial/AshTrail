import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_providers.dart';
import 'package:smoke_log/services/cache_service.dart';
import '../models/log.dart';
import '../domain/use_cases/thc_calculator.dart'; // For basic THC model
import '../domain/models/thc_advanced_model.dart'; // For advanced THC model
import '../presentation/providers/log_providers.dart';

// Provider for user demographic settings
final userAgeProvider = Provider<int>((ref) => 30);
final userSexProvider = Provider<String>((ref) => "male");
final userBodyFatProvider = Provider<double>((ref) => 15.0);
final userCaloricBurnProvider = Provider<double>((ref) => 2000.0);

// Keep track of which logs have been processed
final _processedLogIdsProvider = StateProvider<Set<String>>((ref) => {});

// Class to cache THC content at specific timestamps
class ThcContentCache {
  // Singleton pattern implementation
  static final ThcContentCache _instance = ThcContentCache._internal();

  factory ThcContentCache() {
    return _instance;
  }

  ThcContentCache._internal();

  final Map<int, double> _cache = {};
  static const int _defaultResolutionMinutes =
      30; // 30 minutes between points for weekly view

  // Get THC content at a specific timestamp, returns null if not in cache
  double? getContent(DateTime time) {
    final timeKey = _getTimeKey(time);
    return _cache[timeKey];
  }

  // Store THC content for a specific timestamp
  void storeContent(DateTime time, double content) {
    final timeKey = _getTimeKey(time);
    _cache[timeKey] = content;
  }

  // Convert DateTime to integer key (milliseconds since epoch)
  int _getTimeKey(DateTime time) {
    return time.millisecondsSinceEpoch;
  }

  // Pre-calculate THC content for a range of timestamps
  void preCalculateRange({
    required DateTime startTime,
    required DateTime endTime,
    required Duration increment,
    required double Function(DateTime) calculator,
  }) {
    DateTime currentTime = startTime;
    while (currentTime.isBefore(endTime) ||
        currentTime.isAtSameMomentAs(endTime)) {
      final content = calculator(currentTime);
      storeContent(currentTime, content);
      currentTime = currentTime.add(increment);
    }
  }

  // Initialize cache with historical data and future projection
  void initialize({
    required Duration historyDuration,
    required Duration futureDuration,
    required Duration increment,
    required double Function(DateTime) calculator,
  }) {
    final now = DateTime.now();
    final startTime = now.subtract(historyDuration);
    final endTime = now.add(futureDuration);

    preCalculateRange(
      startTime: startTime,
      endTime: endTime,
      increment: increment,
      calculator: calculator,
    );
  }

  // Clear cache (useful when user logs out)
  void clear() {
    _cache.clear();
  }
}

// Global singletons for advanced and basic THC caches
final _advancedCache = ThcContentCache();
final _basicCache = ThcContentCache();

// Single persistent THC model instance with cache
final thcModelProvider = Provider<THCModelNoMgInput>((ref) {
  return THCModelNoMgInput(
    ageYears: ref.watch(userAgeProvider),
    sex: ref.watch(userSexProvider),
    bodyFatPercent: ref.watch(userBodyFatProvider),
    dailyCaloricBurn: ref.watch(userCaloricBurnProvider),
  );
});

// Advanced THC content cache provider (using global singleton)
final thcAdvancedCacheProvider = Provider<ThcContentCache>((ref) {
  return _advancedCache;
});

// Basic THC content cache provider (using global singleton)
final thcBasicCacheProvider = Provider<ThcContentCache>((ref) {
  return _basicCache;
});

// Advanced THC content provider
final liveThcContentProvider = StreamProvider<double>((ref) {
  final controller = StreamController<double>();
  final model = ref.watch(thcModelProvider);
  final processedLogIds = ref.watch(_processedLogIdsProvider);
  final cache = ref.watch(thcAdvancedCacheProvider);

  // Watch the logs stream to process new logs only once
  ref.listen<AsyncValue<List<Log>>>(logsStreamProvider, (_, logsAsync) {
    logsAsync.whenData((logs) {
      // Find and process only new logs
      bool hasNewLogs = false;
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
          hasNewLogs = true;
        }
      }

      // If we processed new logs, rebuild the cache
      if (hasNewLogs) {
        final now = DateTime.now();
        cache.initialize(
          historyDuration: const Duration(days: 7),
          futureDuration: const Duration(hours: 4),
          increment:
              const Duration(minutes: 30), // Can be adjusted based on needs
          calculator: (time) => model.getTHCContentAtTime(time),
        );
      }
    });
  });

  // Update timer - restore original frequency for better responsiveness
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    final now = DateTime.now();

    // Try to get from cache first
    double? cachedValue = cache.getContent(now);

    if (cachedValue != null) {
      controller.add(cachedValue);
    } else {
      // Calculate and cache if not found
      final currentTHC = model.getTHCContentAtTime(now);
      cache.storeContent(now, currentTHC);
      controller.add(currentTHC);
    }
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
  final cache = ref.watch(thcBasicCacheProvider);

  // Create a persistent calculator instance
  final calculator = THCConcentration(logs: []);

  // Process logs just once and initialize cache
  ref.listen<AsyncValue<List<Log>>>(logsStreamProvider, (_, logsAsync) {
    logsAsync.whenData((logs) {
      // Update the calculator with all logs
      calculator.updateLogs(logs);

      // Initialize the cache with pre-calculated values
      final now = DateTime.now();
      cache.initialize(
        historyDuration: const Duration(days: 7),
        futureDuration: const Duration(hours: 4),
        increment:
            const Duration(minutes: 30), // Can be adjusted based on needs
        calculator: (time) => calculator
            .calculateTHCAtTime(time.millisecondsSinceEpoch.toDouble()),
      );
    });
  });

  // Update timer - restore original frequency
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    final now = DateTime.now();

    // Try to get from cache first
    double? cachedValue = cache.getContent(now);

    if (cachedValue != null) {
      controller.add(cachedValue);
    } else {
      // Calculate and cache if not found
      final currentTHC =
          calculator.calculateTHCAtTime(now.millisecondsSinceEpoch.toDouble());
      cache.storeContent(now, currentTHC);
      controller.add(currentTHC);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// Add provider to get historical THC content at specific timestamps
final historicalThcContentProvider =
    Provider.family<double, DateTime>((ref, timestamp) {
  // Try advanced model first
  final advancedCache = ref.watch(thcAdvancedCacheProvider);
  double? value = advancedCache.getContent(timestamp);

  if (value != null) {
    return value;
  }

  // If not in advanced cache, try basic cache
  final basicCache = ref.watch(thcBasicCacheProvider);
  value = basicCache.getContent(timestamp);

  if (value != null) {
    return value;
  }

  // If not in either cache, calculate using advanced model
  final model = ref.watch(thcModelProvider);
  value = model.getTHCContentAtTime(timestamp);

  // Store for future use
  advancedCache.storeContent(timestamp, value);

  return value;
});

// Add a provider to initialize all caches on app start
final initializeCachesProvider = FutureProvider<bool>((ref) async {
  // Initialize the CacheService
  final cacheService = CacheService();
  await cacheService.init();

  // Register a listener to clear THC caches when user logs out
  ref.listen(authStateProvider, (previous, current) {
    current.whenData((user) {
      if (user == null) {
        // User logged out, clear caches
        _advancedCache.clear();
        _basicCache.clear();
      }
    });
  });

  return true;
});
