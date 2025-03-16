import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/credential_service.dart';
import '../widgets/custom_app_bar.dart';

class UserAccountSelector extends ConsumerWidget {
  final String currentEmail;
  final Function(String) onUserSelected;

  const UserAccountSelector({
    super.key,
    required this.currentEmail,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(userAccountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        // Filter out the current user
        final otherAccounts = accounts
            .where((account) => account['email'] != currentEmail)
            .toList();

        if (otherAccounts.isEmpty) {
          return const Card(
            margin: EdgeInsets.all(16.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No other accounts available to transfer to',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Transfer to account:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: otherAccounts.length,
                itemBuilder: (context, index) {
                  final account = otherAccounts[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(account['email'] ?? 'Unknown'),
                    onTap: () => onUserSelected(account['email'] ?? ''),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading accounts')),
    );
  }
}
