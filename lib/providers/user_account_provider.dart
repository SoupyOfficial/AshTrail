import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/providers/auth_provider.dart';
import '../services/user_account_service.dart';

/// Provider for the UserAccountService
final userAccountServiceProvider = Provider<UserAccountService>((ref) {
  return UserAccountService();
});

/// Provider for enriched user accounts with additional information
final enrichedAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Get the basic accounts from the existing provider
  final accounts = await ref.watch(userAccountsProvider.future);

  // Use the service to enrich the accounts
  return ref.read(userAccountServiceProvider).getEnrichedAccounts(accounts);
});
