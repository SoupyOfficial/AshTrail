import 'package:flutter/material.dart';
import '../models/log.dart';
import '../models/log_aggregates.dart';
import '../utils/format_utils.dart';

class InfoDisplay extends StatelessWidget {
  final List<Log> logs;
  final double? liveThcContent;
  final double? liveBasicThcContent; // New parameter for basic THC model

  const InfoDisplay({
    super.key,
    required this.logs,
    this.liveThcContent,
    this.liveBasicThcContent, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    final aggregates = LogAggregates.fromLogs(logs);

    // Use the live value if available; otherwise, fallback to aggregates.
    final thcValue = (liveThcContent ?? aggregates.thcContent);
    final basicThcValue = (liveBasicThcContent ?? aggregates.thcContent);

    // Debug print to verify the value is being passed correctly
    // print(
    //     'InfoDisplay rebuilding with THC value: $thcValue mg (from live provider: ${liveThcContent != null})');

    // // Helper to format a Duration as HH:MM:SS.
    // String formatDurationHHMMSS(Duration duration) {
    //   String twoDigits(dynamic n) => n.toString().padLeft(2, '0');
    //   String threeDigits(dynamic n) => n.toString().padLeft(3, '0');
    //   final hours = twoDigits(duration.inHours);
    //   final minutes = twoDigits(duration.inMinutes.remainder(60));
    //   final seconds = twoDigits(duration.inSeconds.remainder(60));
    //   final milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));
    //   return "$hours:$minutes:$seconds.${milliseconds}s";
    // }

    // If no last hit is available, default to a zero Duration.
    final lastHitTime = aggregates.lastHit ?? DateTime.now();
    final timeSinceLastHit = DateTime.now().difference(lastHitTime);

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    final totalSecondsLast24 = logs
        .where((log) => log.timestamp.isAfter(cutoff))
        .fold<double>(0.0, (sum, log) => sum + log.durationSeconds);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Since Last Hit: ${formatDurationHHMMSS(timeSinceLastHit.inMilliseconds / 1000.0, detailed: true)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Duration Today: ${aggregates.formattedTotalSecondsToday}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Duration Last 24 Hours: ${formatDurationHHMMSS(totalSecondsLast24, detailed: true)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Raw THC Content: ${basicThcValue > 0.0001 ? "${basicThcValue.toStringAsFixed(3)} fg" : "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Psychoactive THC Content: ${thcValue > 0.0001 ? "${thcValue.toStringAsFixed(3)} mg" : "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // const SizedBox(height: 8),
            // Text(
            //   'Logs available: ${logs.length}',
            //   style: Theme.of(context).textTheme.bodySmall,
            // ),
            // Text(
            //   'Duration: ${formatSecondsDisplay(log.durationSeconds)} seconds',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
          ],
        ),
      ),
    );
  }
}
