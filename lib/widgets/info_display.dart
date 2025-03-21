import 'package:flutter/material.dart';
import '../models/log.dart';
import '../models/log_aggregates.dart';
import '../utils/format_utils.dart';

class InfoDisplay extends StatelessWidget {
  final List<Log> logs;
  final double? liveThcContent;
  final double? liveBasicThcContent;

  const InfoDisplay({
    super.key,
    required this.logs,
    this.liveThcContent,
    this.liveBasicThcContent,
  });

  @override
  Widget build(BuildContext context) {
    final aggregates = LogAggregates.fromLogs(logs);

    // Use the live value if available; otherwise, fallback to zero
    final thcValue = liveThcContent ?? 0.0;
    final basicThcValue = liveBasicThcContent ?? 0.0;

    // If no last hit is available, default to current time (showing 0 duration since)
    final lastHitTime = aggregates.lastHit ?? DateTime.now();
    final timeSinceLastHit = DateTime.now().difference(lastHitTime);

    // Calculate duration for last 24 hours
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    final totalSecondsLast24 = logs
        .where((log) => log.timestamp.isAfter(cutoff))
        .fold<double>(0.0, (sum, log) => sum + log.durationSeconds);

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInfoRow(
                context: context,
                label: 'Time Since Last Hit',
                value: formatDurationHHMMSS(
                    timeSinceLastHit.inMilliseconds / 1000.0,
                    detailed: true),
              ),
              _buildInfoRow(
                context: context,
                label: 'Duration Today',
                value: aggregates.formattedTotalSecondsToday,
              ),
              _buildInfoRow(
                context: context,
                label: 'Duration Last 24 Hours',
                value: formatDurationHHMMSS(totalSecondsLast24, detailed: true),
              ),
              _buildInfoRow(
                context: context,
                label: 'Raw THC Content',
                value: basicThcValue > 0.0001
                    ? '${basicThcValue.toStringAsFixed(3)} fg'
                    : 'Loading...',
              ),
              _buildInfoRow(
                context: context,
                label: 'Psychoactive THC Content',
                value: thcValue > 0.0001
                    ? '${thcValue.toStringAsFixed(3)} mg'
                    : 'Loading...',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
