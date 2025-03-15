import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log.dart';

/// Service that manages persistent caching throughout the app lifecycle.
class CacheService {
  static final CacheService _instance = CacheService._internal();

  // In-memory cache for logs
  Map<String, Log> _logsCache = {};

  // Cache timestamp to track freshness
  DateTime? _logsCacheTimestamp;

  // Cache freshness duration
  static const Duration cacheFreshnessDuration = Duration(hours: 12);

  // Key for logs cache in SharedPreferences
  static const String _logsCacheKey = 'logs_cache';
  static const String _logsCacheTimestampKey = 'logs_cache_timestamp';

  // Factory constructor to return the same instance
  factory CacheService() {
    return _instance;
  }

  // Private constructor for singleton
  CacheService._internal();

  // Initialize the cache from persistent storage
  Future<void> init() async {
    await _loadLogsFromStorage();
  }

  // Get all logs from cache
  List<Log> getAllLogs() {
    return _logsCache.values.toList();
  }

  // Check if logs cache is fresh
  bool isLogsCacheFresh() {
    if (_logsCacheTimestamp == null) return false;

    final now = DateTime.now();
    return now.difference(_logsCacheTimestamp!) < cacheFreshnessDuration;
  }

  // Update logs cache with new logs
  Future<void> updateLogsCache(List<Log> logs) async {
    // Clear current cache
    _logsCache.clear();

    // Add all logs to cache
    for (final log in logs) {
      if (log.id != null) {
        _logsCache[log.id!] = log;
      }
    }

    _logsCacheTimestamp = DateTime.now();

    // Save to storage asynchronously
    _saveLogsToStorage();
  }

  // Get a specific log by ID
  Log? getLogById(String id) {
    return _logsCache[id];
  }

  // Add or update a single log
  Future<void> addOrUpdateLog(Log log) async {
    if (log.id == null) return;

    _logsCache[log.id!] = log;
    _logsCacheTimestamp = DateTime.now();

    // Save to storage asynchronously
    _saveLogsToStorage();
  }

  // Remove a log by ID
  Future<void> removeLog(String id) async {
    _logsCache.remove(id);
    _logsCacheTimestamp = DateTime.now();

    // Save to storage asynchronously
    _saveLogsToStorage();
  }

  // Clear the entire cache
  Future<void> clearCache() async {
    _logsCache.clear();
    _logsCacheTimestamp = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsCacheKey);
    await prefs.remove(_logsCacheTimestampKey);
  }

  // Save logs to SharedPreferences
  Future<void> _saveLogsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert logs to JSON
      final logsJson =
          _logsCache.values.map((log) => json.encode(log.toMap())).toList();

      // Save logs and timestamp
      await prefs.setStringList(_logsCacheKey, logsJson);
      if (_logsCacheTimestamp != null) {
        await prefs.setString(
            _logsCacheTimestampKey, _logsCacheTimestamp!.toIso8601String());
      }
    } catch (e) {
      print('Error saving logs to storage: $e');
    }
  }

  // Load logs from SharedPreferences
  Future<void> _loadLogsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load timestamp
      final timestampString = prefs.getString(_logsCacheTimestampKey);
      if (timestampString != null) {
        _logsCacheTimestamp = DateTime.parse(timestampString);
      }

      // Check if cache is still fresh
      if (!isLogsCacheFresh()) {
        _logsCache.clear();
        return;
      }

      // Load logs
      final logsJson = prefs.getStringList(_logsCacheKey);
      if (logsJson != null) {
        _logsCache.clear();

        for (final logJson in logsJson) {
          try {
            final logMap = json.decode(logJson) as Map<String, dynamic>;
            final log = Log.fromMap(logMap, logMap['id']);
            if (log.id != null) {
              _logsCache[log.id!] = log;
            }
          } catch (e) {
            print('Error parsing log: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading logs from storage: $e');
    }
  }
}
