import 'package:fl_chart/fl_chart.dart';
import '../../models/log.dart';
import '../../domain/use_cases/thc_calculator.dart';
import '../../domain/models/thc_advanced_model.dart';

enum ChartRange { daily, weekly, monthly, yearly }

List<FlSpot> defaultDataProcessor(List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange;
  switch (range) {
    case ChartRange.daily:
      startRange = now.subtract(const Duration(hours: 24));
      break;
    case ChartRange.weekly:
      startRange = now.subtract(const Duration(days: 7));
      break;
    case ChartRange.monthly:
      startRange = now.subtract(const Duration(days: 30));
      break;
    case ChartRange.yearly:
      startRange = now.subtract(const Duration(days: 365));
      break;
  }

  // Filter out logs with null timestamps and then filter by range
  final filteredLogs = logs
      .where((log) => log.timestamp != null) // Ensure timestamp isn't null
      .where((log) => !log.timestamp.isBefore(startRange))
      .toList();

  return filteredLogs
      .map((log) => FlSpot(
            log.timestamp.millisecondsSinceEpoch.toDouble(),
            log.durationSeconds.toDouble(),
          ))
      .toList();
}

List<FlSpot> thcConcentrationDataProcessor(List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange, endRange;
  switch (range) {
    case ChartRange.daily:
      startRange = now.subtract(const Duration(hours: 24));
      endRange = now;
      break;
    case ChartRange.weekly:
      startRange = now.subtract(const Duration(days: 7));
      endRange = now;
      break;
    case ChartRange.monthly:
      startRange = now.subtract(const Duration(days: 30));
      endRange = now;
      break;
    case ChartRange.yearly:
      startRange = now.subtract(const Duration(days: 365));
      endRange = now;
      break;
  }

  final thcCalculator = THCConcentration(logs: logs);
  final spots = <FlSpot>[];

  late Duration sampleInterval;
  switch (range) {
    case ChartRange.daily:
      sampleInterval = const Duration(minutes: 1);
      break;
    case ChartRange.weekly:
      sampleInterval = const Duration(minutes: 10);
      break;
    case ChartRange.monthly:
      sampleInterval = const Duration(hours: 1);
      break;
    case ChartRange.yearly:
      sampleInterval = const Duration(hours: 6);
      break;
  }

  DateTime t = startRange;
  while (t.isBefore(endRange) || t.isAtSameMomentAs(endRange)) {
    final x = t.millisecondsSinceEpoch.toDouble();
    final y = thcCalculator.calculateTHCAtTime(x);
    spots.add(FlSpot(x, y));
    t = t.add(sampleInterval);
  }
  return spots;
}

List<FlSpot> advancedThcConcentrationDataProcessor(
    List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange, endRange;
  switch (range) {
    case ChartRange.daily:
      startRange = now.subtract(const Duration(hours: 24));
      endRange = now;
      break;
    case ChartRange.weekly:
      startRange = now.subtract(const Duration(days: 7));
      endRange = now;
      break;
    case ChartRange.monthly:
      startRange = now.subtract(const Duration(days: 30));
      endRange = now;
      break;
    case ChartRange.yearly:
      startRange = now.subtract(const Duration(days: 365));
      endRange = now;
      break;
  }

  // Create and configure advanced THC model
  final thcModel = THCModelNoMgInput();

  // Convert logs to inhalation events
  for (final log in logs) {
    // Map log data to inhalation event parameters
    // Default to joint, but could be enhanced to map reason to method
    final method = ConsumptionMethod.joint;

    // Use potencyRating as perceived strength if available
    final perceivedStrength = log.potencyRating != null
        ? (log.potencyRating! / 5.0).clamp(0.25, 2.0)
        : 1.0;

    thcModel.logInhalation(
      timestamp: log.timestamp,
      method: method,
      inhaleDurationSec: log.durationSeconds,
      perceivedStrength: perceivedStrength,
    );
  }

  // Generate chart data points
  final spots = <FlSpot>[];
  late Duration sampleInterval;

  switch (range) {
    case ChartRange.daily:
      sampleInterval = const Duration(minutes: 5);
      break;
    case ChartRange.weekly:
      sampleInterval = const Duration(minutes: 30);
      break;
    case ChartRange.monthly:
      sampleInterval = const Duration(hours: 3);
      break;
    case ChartRange.yearly:
      sampleInterval = const Duration(days: 1);
      break;
  }

  DateTime t = startRange;
  while (t.isBefore(endRange) || t.isAtSameMomentAs(endRange)) {
    final x = t.millisecondsSinceEpoch.toDouble();
    final y = thcModel.getTHCContentAtTime(t);
    spots.add(FlSpot(x, y));
    t = t.add(sampleInterval);
  }

  return spots;
}

List<FlSpot> cumulativeDataProcessor(List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange;
  final endRange = now;

  if (range == ChartRange.daily) {
    startRange = DateTime(now.year, now.month, now.day);
  } else if (range == ChartRange.yearly) {
    startRange = now.subtract(const Duration(days: 365));
  } else {
    switch (range) {
      case ChartRange.weekly:
        startRange = now.subtract(const Duration(days: 7));
        break;
      case ChartRange.monthly:
        startRange = now.subtract(const Duration(days: 30));
        break;
      default:
        break;
    }
  }

  final filteredLogs = logs
      .where((log) =>
          (log.timestamp.isAfter(startRange) ||
              log.timestamp.isAtSameMomentAs(startRange)) &&
          (log.timestamp.isBefore(endRange) ||
              log.timestamp.isAtSameMomentAs(endRange)))
      .toList();

  final spots = <FlSpot>[];

  if (range == ChartRange.daily) {
    final day = DateTime(now.year, now.month, now.day);
    final logsForDay = filteredLogs
        .where((log) =>
            DateTime(
                log.timestamp.year, log.timestamp.month, log.timestamp.day) ==
            day)
        .toList();
    logsForDay.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    double cumulative = 0;
    spots.add(FlSpot(day.millisecondsSinceEpoch.toDouble(), 0));
    for (final log in logsForDay) {
      cumulative += log.durationSeconds;
      spots.add(
          FlSpot(log.timestamp.millisecondsSinceEpoch.toDouble(), cumulative));
    }
  } else if (range == ChartRange.yearly) {
    final Map<DateTime, List<Log>> groupedLogs = {};
    for (final log in filteredLogs) {
      final monthKey = DateTime(log.timestamp.year, log.timestamp.month);
      groupedLogs.putIfAbsent(monthKey, () => []).add(log);
    }
    final sortedMonths = groupedLogs.keys.toList()..sort();
    for (final month in sortedMonths) {
      final logsForMonth = groupedLogs[month]!;
      final monthlyTotal =
          logsForMonth.fold(0.0, (prev, log) => prev + log.durationSeconds);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59);
      spots.add(FlSpot(
          lastDayOfMonth.millisecondsSinceEpoch.toDouble(), monthlyTotal));
    }
  } else {
    final Map<DateTime, List<Log>> groupedLogs = {};
    for (final log in filteredLogs) {
      final day =
          DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      groupedLogs.putIfAbsent(day, () => []).add(log);
    }
    final sortedDays = groupedLogs.keys.toList()..sort();
    for (final day in sortedDays) {
      final logsForDay = groupedLogs[day]!;
      final dailyTotal =
          logsForDay.fold(0.0, (prev, log) => prev + log.durationSeconds);
      final pointTime = DateTime(day.year, day.month, day.day, 23, 59);
      spots
          .add(FlSpot(pointTime.millisecondsSinceEpoch.toDouble(), dailyTotal));
    }
  }
  return spots;
}
