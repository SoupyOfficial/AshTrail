import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountOptionsScreen extends ConsumerWidget {
  const AccountOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAccountsAsync = ref.watch(userAccountsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Account Options',
        showBackButton: true,
      ),
      body: ListView(
        children: [
          // Show all accounts section
          userAccountsAsync.when(
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
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isCurrentAccount = currentUser?.email == email;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentAccount ? Colors.green : null,
                        child: Icon(
                          isCurrentAccount ? Icons.check : Icons.person,
                          color: isCurrentAccount ? Colors.white : null,
                        ),
                      ),
                      title: Text(email),
                      subtitle: isCurrentAccount
                          ? const Text('Current Account',
                              style: TextStyle(color: Colors.green))
                          : null,
                      trailing: isCurrentAccount
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.login),
                              tooltip: 'Switch to this account',
                              onPressed: () async {
                                try {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 16),
                                          Text("Switching accounts..."),
                                        ],
                                      ),
                                    ),
                                  );

                                  // Set a timeout to ensure dialog closes
                                  Future.delayed(const Duration(seconds: 5),
                                      () {
                                    if (context.mounted &&
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .canPop()) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    }
                                  });

                                  await ref
                                      .read(authServiceProvider)
                                      .switchAccount(email);

                                  // Close loading dialog immediately after operation completes
                                  if (context.mounted &&
                                      Navigator.of(context, rootNavigator: true)
                                          .canPop()) {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  }

                                  // Handle UI updates AFTER dialog is closed
                                  Future.microtask(() {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Switched to $email')),
                                      );
                                      // Refresh the page
                                      ref.refresh(userAccountsProvider);
                                    }
                                  });
                                } catch (e) {
                                  // Close loading dialog
                                  if (context.mounted &&
                                      Navigator.of(context, rootNavigator: true)
                                          .canPop()) {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Failed to switch: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                    );
                  }).toList(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Add Another Account'),
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Failed to load accounts')),
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
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(authServiceProvider).signOut();
                final userAccounts =
                    await ref.read(credentialServiceProvider).getUserAccounts();
                if (context.mounted && userAccounts.isEmpty) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } else {
                  // Set first account active
                  if (userAccounts.isNotEmpty) {
                    final firstAccount = userAccounts.first;
                    await ref
                        .read(authServiceProvider)
                        .switchAccount(firstAccount['email']!);
                  }
                  // Refresh the page to show updated accounts
                  ref.refresh(userAccountsProvider);
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
            onTap: () {
              // Implement account deletion functionality
            },
          ),
        ],
      ),
    );
  }
}
