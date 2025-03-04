import 'package:cloud_firestore/cloud_firestore.dart';

class Log {
  final String? id;
  final dynamic timestamp; // Firestore timestamp
  final double durationSeconds;
  final int moodRating;
  final int physicalRating;
  final int? potencyRating;
  final String? notes;
  final List<String>? reason;

  Log({
    this.id,
    required this.timestamp,
    this.durationSeconds = 0,
    List<String>? reason,
    this.moodRating = 1,
    this.physicalRating = 1,
    this.notes,
    required this.potencyRating,
  }) : reason = reason ?? [];

  factory Log.fromMap(Map<String, dynamic> map, String docId) {
    return Log(
      id: docId,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      durationSeconds: map['durationSeconds'] is String
          ? double.tryParse(map['durationSeconds']) ?? 0.0
          : (map['durationSeconds'] ?? 0.0).toDouble(),
      reason: map['reason'] is List
          ? List<String>.from(map['reason'])
          : [map['reason'] ?? ''],
      moodRating: (map['moodRating'] ?? 1).toInt(),
      physicalRating: (map['physicalRating'] ?? 1).toInt(),
      notes: map['notes'],
      potencyRating: map['potencyRating'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': durationSeconds,
      'reason': reason,
      'moodRating': moodRating,
      'physicalRating': physicalRating,
      'notes': notes,
      'potencyRating': potencyRating,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'potencyRating': potencyRating,
      'reason': reason,
      'moodRating': moodRating,
      'physicalRating': physicalRating,
      'notes': notes,
    };
  }

  Log copyWith({
    String? id,
    dynamic timestamp,
    double? durationSeconds,
    List<String>? reason,
    int? moodRating,
    int? physicalRating,
    String? notes,
    int? potencyRating,
  }) {
    return Log(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      reason: reason ?? this.reason,
      moodRating: moodRating ?? this.moodRating,
      physicalRating: physicalRating ?? this.physicalRating,
      notes: notes ?? this.notes,
      potencyRating: potencyRating ?? this.potencyRating,
    );
  }
}
