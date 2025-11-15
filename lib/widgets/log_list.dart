import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log.dart';
import '../screens/edit_log_screen.dart';

class LogList extends StatelessWidget {
  final List<Log> logs;
  final Future<void> Function(String logId) onDeleteLog;

  LogList({super.key, required this.logs, required this.onDeleteLog});

  final _dateFormat = DateFormat('MMM d, y h:mm a');

  String _formatReason(String reason) {
    // Remove brackets if present
    String formatted = reason.trim();
    if (formatted.startsWith('[') && formatted.endsWith(']')) {
      formatted = formatted.substring(1, formatted.length - 1);
    }

    // If it's an empty list or just contains whitespace
    if (formatted.trim().isEmpty) {
      return '';
    }

    // Clean up any extra commas or whitespace
    List<String> parts = formatted
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.join(', ');
  }

  /// Get color for duration based on seconds
  /// - Royal blue to yellow (0-4s)
  /// - Yellow to red (4-8s)
  /// - Red to black (8-12s)
  /// - Black (12s+)
  Color _getDurationColor(double seconds) {
    if (seconds >= 12) {
      return Colors.black;
    } else if (seconds >= 8) {
      // Map 8-12 to a gradient from blood red to black
      final factor = (seconds - 8) / 4.0; // 0.0 to 1.0
      return Color.lerp(Colors.red[900]!, Colors.black, factor)!;
    } else if (seconds >= 4) {
      // Map 4-8 to a gradient from yellow to blood red
      final factor = (seconds - 4) / 4.0; // 0.0 to 1.0
      return Color.lerp(Colors.amber, Colors.red[900]!, factor)!;
    } else {
      // Map 0-4 to a gradient from royal blue to yellow
      final factor = seconds / 4.0; // 0.0 to 1.0
      return Color.lerp(Colors.blue[800], Colors.amber, factor)!;
    }
  }

  /// Get color for mood/physical rating (1-10)
  /// - 1-2: Red to black (worst)
  /// - 3-5: Red to orange
  /// - 6-8: Orange to green
  /// - 9-10: Green to royal blue (best)
  Color _getRatingColor(int? rating) {
    if (rating == null || rating == -1) return Colors.grey;

    if (rating <= 2) {
      // Map 1-2 to a gradient from black to red
      final factor = (rating - 1) / 1.0; // 0.0 to 1.0
      return Color.lerp(Colors.black, Colors.red[900]!, factor)!;
    } else if (rating <= 5) {
      // Map 3-5 to a gradient from red to orange
      final factor = (rating - 3) / 2.0; // 0.0 to 1.0
      return Color.lerp(Colors.red[900]!, Colors.orange, factor)!;
    } else if (rating <= 8) {
      // Map 6-8 to a gradient from orange to green
      final factor = (rating - 6) / 2.0; // 0.0 to 1.0
      return Color.lerp(Colors.orange, Colors.green, factor)!;
    } else {
      // Map 9-10 to a gradient from green to royal blue
      final factor = (rating - 9) / 1.0; // 0.0 to 1.0
      return Color.lerp(Colors.green, Colors.blue[800], factor)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return logs.isEmpty
        ? const Center(child: Text('No logs yet'))
        : ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Dismissible(
                key: Key(log.id!),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Log'),
                      content: const Text(
                          'Are you sure you want to delete this log?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) => onDeleteLog(log.id!),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  title: Row(
                    children: [
                      Expanded(
                          child: Text(_dateFormat.format(log.timestamp),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                      Container(
                        margin: const EdgeInsets.only(right: 16.0),
                        child: Text('${log.durationSeconds}s',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDurationColor(log.durationSeconds),
                              fontWeight: log.durationSeconds >= 8
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (log.reason != null && log.reason!.isNotEmpty)
                            Expanded(
                                child: Text(
                                    'Reason: ${_formatReason(log.reason!.join(","))}',
                                    style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Mood: ${log.moodRating}/10',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRatingColor(log.moodRating),
                                fontWeight: log.moodRating <= 2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          const SizedBox(width: 10),
                          Text('Physical: ${log.physicalRating}/10',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRatingColor(log.physicalRating),
                                fontWeight: log.physicalRating <= 2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ],
                      ),
                      if (log.notes != null && log.notes!.isNotEmpty)
                        Text('Notes: ${log.notes}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditLogScreen(log: log),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // Navigate to the edit screen when the list item is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditLogScreen(log: log),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }
}
