import '../../models/log.dart';
import '../repositories/log_repository_interface.dart';

/// Use case for updating a log
/// Encapsulates the business logic for log updates
class UpdateLogUseCase {
  final ILogRepository _logRepository;

  UpdateLogUseCase(this._logRepository);

  /// Execute the use case to update a log
  /// 
  /// Validates the log and updates it in the repository
  /// Throws [Exception] if validation fails or repository operation fails
  Future<void> execute(Log log) async {
    if (log.id == null || log.id!.isEmpty) {
      throw Exception('Log ID is required for update');
    }

    if (log.durationSeconds < 0) {
      throw Exception('Duration cannot be negative');
    }

    if (log.timestamp == null) {
      throw Exception('Timestamp is required');
    }

    await _logRepository.updateLog(log);
  }
}

