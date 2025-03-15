import 'dart:math';
import '../../models/log.dart';

/// A utility class to compute THC concentration over time based on log entries.
///
/// For each log entry (treated as an inhalation event), the concentration is calculated using:
///
///   absorbedTHC = A * (1 - exp(-k_a * inhalationDuration))
///   remainingTHC = absorbedTHC * exp(-k_e * timeSinceLog)
///
/// where:
///   • A: absorptionCoefficient (default 0.25)
///   • k_a: absorptionRateConstant (default 0.1/60000 per millisecond)
///   • k_e: eliminationRateConstant (default 0.00024/60000 per millisecond)
///   • inhalationDuration: log.durationSeconds converted to milliseconds
///   • timeSinceLog: elapsed time from the log’s timestamp until time t (in milliseconds)
///
/// The final THC concentration at time t is the sum of remainingTHC from all logs.
class THCConcentration {
  final double absorptionCoefficient;
  final double absorptionRateConstant;
  final double eliminationRateConstant;
  final double eliminationPerUnitTime;
  List<Log> _logs;

  THCConcentration({
    this.absorptionCoefficient = 0.25, // Default 25% absorption.
    this.absorptionRateConstant =
        0.1 / 60000, // Default absorption rate per millisecond.
    this.eliminationRateConstant =
        0.00024 / 60000, // Default elimination rate per millisecond.
    this.eliminationPerUnitTime =
        0.00333 / 60000, // Default elimination per millisecond.
    required List<Log> logs,
  }) : _logs = logs;

  // Add a method to update logs
  void updateLogs(List<Log> newLogs) {
    _logs = newLogs;
  }

  /// Calculates the THC concentration at a given time [t] (in milliseconds since epoch).
  ///
  /// Each log entry is treated as an inhalation event where its duration (in seconds)
  /// is converted to milliseconds. The calculation sums the remaining THC from each log.
  double calculateTHCAtTime(double t) {
    double thcConcentration = 0.0;

    for (Log log in _logs) {
      double logTime = log.timestamp.millisecondsSinceEpoch.toDouble();
      // Convert duration from seconds to milliseconds.
      double logDurationInMillis = log.durationSeconds.toDouble() * 1000;

      // Calculate the absorbed THC for this log event.
      double absorbedTHC = absorptionCoefficient *
          (1 - exp(-absorptionRateConstant * logDurationInMillis));

      double timeSinceLog = t - logTime;

      if (timeSinceLog > 0) {
        double remainingTHC =
            absorbedTHC * exp(-eliminationRateConstant * timeSinceLog);
        thcConcentration += remainingTHC;
      }
    }

    return thcConcentration > 0 ? thcConcentration * 1000 : 0.0;
  }
}
