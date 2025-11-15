import '../repositories/log_repository_interface.dart';

/// Use case for deleting a log
/// Encapsulates the business logic for log deletion
class DeleteLogUseCase {
  final ILogRepository _logRepository;

  DeleteLogUseCase(this._logRepository);

  /// Execute the use case to delete a log
  /// 
  /// Validates the log ID and deletes it from the repository
  /// Throws [Exception] if validation fails or repository operation fails
  Future<void> execute(String logId) async {
    if (logId.isEmpty) {
      throw Exception('Log ID cannot be empty');
    }

    await _logRepository.deleteLog(logId);
  }
}

