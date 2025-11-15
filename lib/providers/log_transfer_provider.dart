import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/credential_service.dart';
import '../presentation/providers/log_providers.dart';
import '../domain/repositories/log_repository_interface.dart';
import '../core/di/dependency_injection.dart';

// Provide access to transfer functionality
final logTransferProvider = Provider<LogTransferService>((ref) {
  final logRepository = ref.watch(logRepositoryProvider);
  final credentialService = ref.watch(credentialServiceProvider);
  return LogTransferService(logRepository, credentialService);
});

// Service to handle log transfers
class LogTransferService {
  final ILogRepository logRepository;
  final CredentialService credentialService;

  LogTransferService(this.logRepository, this.credentialService);

  Future<List<Map<String, String>>> getAvailableUsers() async {
    return await credentialService.getUserAccounts();
  }

  Future<bool> transferLogToUser(String logId, String targetUserEmail) async {
    // Get the target user ID from the email
    final userAccounts = await credentialService.getUserAccounts();
    final targetUser = userAccounts.firstWhere(
        (account) => account['email'] == targetUserEmail,
        orElse: () => {'userId': '', 'email': ''});

    if (targetUser['userId']?.isEmpty ?? true) {
      return false;
    }

    return await logRepository.transferLogToUser(logId, targetUser['userId']!);
  }
}
