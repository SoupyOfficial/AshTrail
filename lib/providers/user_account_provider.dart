import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_providers.dart';
import '../services/user_account_service.dart';
import '../core/di/dependency_injection.dart';

/// Provider for the UserAccountService with dependency injection
final userAccountServiceProvider = Provider<UserAccountService>((ref) {
  final firestore = ref.watch(firebaseFirestoreInstanceDirectProvider);
  final auth = ref.watch(firebaseAuthInstanceProvider);
  return UserAccountService(
    firestore: firestore,
    auth: auth,
  );
});

/// Provider for enriched user accounts with additional information
final enrichedAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Get the basic accounts from the existing provider
  final accounts = await ref.watch(userAccountsProvider.future);

  // Use the service to enrich the accounts
  return ref.read(userAccountServiceProvider).getEnrichedAccounts(accounts);
});
