import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/consolidated_auth_provider.dart';
import '../../utils/auth_operations.dart';
import '../login_screen.dart';

class AccountOptionsScreen extends ConsumerWidget {
  const AccountOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrichedAccountsAsync = ref.watch(enrichedAccountsProvider);
    final currentUserAsync = ref.watch(authStateProvider);
    final currentUser = currentUserAsync.value;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Account Options',
        showBackButton: true,
      ),
      body: ListView(
        children: [
          // Show all accounts section
          enrichedAccountsAsync.when(
            data: (accounts) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Your Accounts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...accounts.map((account) {
                    final email = account['email'] ?? 'Unknown';
                    final firstName = account['firstName'] ?? '';
                    final isCurrentAccount = currentUser?.email == email;
                    final hasUniqueName = account['hasUniqueName'] ?? false;

                    // Determine display name - use firstName if unique, otherwise use email
                    final displayName = (firstName.isNotEmpty && hasUniqueName)
                        ? firstName
                        : email;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentAccount ? Colors.green : null,
                        child: Icon(
                          isCurrentAccount ? Icons.check : Icons.person,
                          color: isCurrentAccount ? Colors.white : null,
                        ),
                      ),
                      title: Text(displayName),
                      subtitle: isCurrentAccount
                          ? const Text('Current Account',
                              style: TextStyle(color: Colors.green))
                          : (hasUniqueName && email != 'Unknown'
                              ? Text(email)
                              : null),
                      trailing: isCurrentAccount
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.login),
                              tooltip: 'Switch to this account',
                              onPressed: () => AuthOperations.switchAccount(
                                  context, ref, email),
                            ),
                    );
                  }).toList(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Add Another Account'),
                    onTap: () => _addAnotherAccount(context, ref),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Failed to load accounts: ${error.toString()}'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            onTap: () {
              // Implement password change functionality
            },
          ),
          const Divider(),
          // Add logout option
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              try {
                final result = await AuthOperations.logout(context, ref);
                debugPrint('Logout result: $result');

                // Navigate to the login screen only if fully signed out
                if (result == SignOutResult.fullySignedOut && context.mounted) {
                  // Use a delay to ensure all cleanup is done before navigation
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error during logout: $e');
                // Show error to user
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout error: $e')),
                  );
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => _deleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  // Simplified method to add another account
  Future<void> _addAnotherAccount(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Delete account method - still complex due to multiple confirmations needed
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // Implementation remains similar but uses the new providers
    // ...existing code...
  }
}
