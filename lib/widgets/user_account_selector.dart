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
    // Use the provider instead of direct Firebase access
    final currentUserAsync = ref.watch(authStateProvider);

    return accountsAsync.when(
      data: (accounts) {
        // Filter out the current user
        final otherAccounts = accounts
            .where((account) => account['email'] != currentEmail)
            .toList();

        // Add first names to accounts using user displayName from the provider
        final enrichedAccounts = otherAccounts.map((account) {
          final enrichedAccount = {...account};
          // Check if we have a current user and access via the provider
          if (currentUserAsync.value?.displayName != null) {
            final displayNameParts =
                currentUserAsync.value!.displayName!.split(' ');
            if (displayNameParts.isNotEmpty) {
              enrichedAccount['firstName'] = displayNameParts.first;
            }
          }
          return enrichedAccount;
        }).toList();

        // Check for duplicate first names
        final Map<String, int> firstNameCount = {};
        for (final account in enrichedAccounts) {
          final firstName = account['firstName'];
          if (firstName != null && firstName.isNotEmpty) {
            firstNameCount[firstName] = (firstNameCount[firstName] ?? 0) + 1;
          }
        }

        if (enrichedAccounts.isEmpty) {
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
                itemCount: enrichedAccounts.length,
                itemBuilder: (context, index) {
                  final account = enrichedAccounts[index];
                  final email = account['email'] ?? 'Unknown';
                  final firstName = account['firstName'] ?? '';

                  // Determine display name - use firstName if unique, otherwise use email
                  final bool hasUniqueName =
                      firstName.isNotEmpty && (firstNameCount[firstName] == 1);
                  final displayName = hasUniqueName ? firstName : email;

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(displayName),
                    subtitle: hasUniqueName ? Text(email) : null,
                    onTap: () => onUserSelected(email),
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
