import '../../models/log.dart';
import '../repositories/log_repository_interface.dart';

/// Use case for adding a new log
/// Encapsulates the business logic for log creation
class AddLogUseCase {
  final ILogRepository _logRepository;

  AddLogUseCase(this._logRepository);

  /// Execute the use case to add a log
  /// 
  /// Validates the log and adds it to the repository
  /// Throws [Exception] if validation fails or repository operation fails
  Future<void> execute(Log log) async {
    // Validate log
    if (log.durationSeconds < 0) {
      throw Exception('Duration cannot be negative');
    }

    if (log.timestamp == null) {
      throw Exception('Timestamp is required');
    }

    // Add log to repository
    await _logRepository.addLog(log);
  }
}

