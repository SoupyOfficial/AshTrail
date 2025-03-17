import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_account_service.dart';
import '../services/credential_service.dart';
import 'auth_provider.dart';

/// Provider for the AuthAccountService
final authAccountServiceProvider = Provider<AuthAccountService>((ref) {
  final credentialService = ref.watch(credentialServiceProvider);
  return AuthAccountService(credentialService: credentialService);
});

/// Provider to handle logout operation
final logoutProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authAccountService = ref.watch(authAccountServiceProvider);
  return authAccountService.signOutAndSwitchIfAvailable();
});

/// Provider to handle account deletion
final accountDeletionProvider =
    FutureProvider.family<void, String>((ref, password) async {
  final authAccountService = ref.watch(authAccountServiceProvider);
  await authAccountService.deleteAccount(password);
});
