import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_account_provider.dart';

/// A widget that displays a list of user accounts and allows selection
class UserAccountSelector extends ConsumerWidget {
  /// The email of the currently active account
  final String currentEmail;

  /// Callback when user selects an account
  final Function(String) onUserSelected;

  const UserAccountSelector({
    super.key,
    required this.currentEmail,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get enriched accounts with names when available
    final accountsAsync = ref.watch(enrichedAccountsProvider);

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.account_circle),
                SizedBox(width: 8),
                Text(
                  'Select Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          accountsAsync.when(
            data: (accounts) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final email = account['email'] ?? 'Unknown';
                  final firstName = account['firstName'] ?? '';
                  final hasUniqueName = account['hasUniqueName'] ?? false;
                  final isCurrentAccount = email == currentEmail;

                  // Use firstName if available and unique, otherwise use email
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
                    subtitle: hasUniqueName ? Text(email) : null,
                    enabled: !isCurrentAccount,
                    onTap:
                        isCurrentAccount ? null : () => onUserSelected(email),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading accounts')),
          ),
        ],
      ),
    );
  }
}
