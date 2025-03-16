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
    // Use the provider instead of direct Firebase access
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
          userAccountsAsync.when(
            data: (accounts) {
              // Add first names to accounts from user provider if available
              final enrichedAccounts = accounts.map((account) {
                final enrichedAccount = {...account};

                // If this is the current account and we have displayName
                if (currentUser?.email == account['email'] &&
                    currentUser?.displayName != null) {
                  final displayNameParts = currentUser!.displayName!.split(' ');
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
                  firstNameCount[firstName] =
                      (firstNameCount[firstName] ?? 0) + 1;
                }
              }

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
                  ...enrichedAccounts.map((account) {
                    final email = account['email'] ?? 'Unknown';
                    final firstName = account['firstName'] ?? '';
                    final isCurrentAccount = currentUser?.email == email;

                    // Determine display name - use firstName if unique, otherwise use email
                    final bool hasUniqueName = firstName.isNotEmpty &&
                        (firstNameCount[firstName] == 1);
                    final displayName = hasUniqueName ? firstName : email;

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
                          : (hasUniqueName ? Text(email) : null),
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
                                            content: Text(
                                                'Switched to $displayName')),
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
            onTap: () async {
              // First confirmation dialog
              final confirm1 = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to delete your account?\n\n'
                    'WARNING: This action is PERMANENT and CANNOT be undone. '
                    'Your account and all your data will be permanently erased.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Proceed'),
                    ),
                  ],
                ),
              );

              if (confirm1 != true || !context.mounted) return;

              // Second confirmation dialog requiring password
              final passwordController = TextEditingController();
              final confirm2 = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Account Deletion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'This will PERMANENTLY delete your account and all your data. '
                        'This action is IRREVERSIBLE.\n\n'
                        'To confirm, please type "DELETE MY ACCOUNT" below:',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(
                        context,
                        passwordController.text == 'DELETE MY ACCOUNT',
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              );

              passwordController.dispose();

              if (confirm2 != true || !context.mounted) return;

              // Third and final confirmation dialog
              final confirm3 = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Final Warning'),
                  content: const Text(
                    'You are about to PERMANENTLY DELETE your account and all associated data.\n\n'
                    'This is your FINAL WARNING.\n\n'
                    'Once confirmed, your account will be terminated and you CANNOT recover your data.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Go Back'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete My Account Permanently'),
                    ),
                  ],
                ),
              );

              if (confirm3 != true || !context.mounted) return;

              // Show password confirmation for final security check
              final securityController = TextEditingController();
              final passwordConfirm = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Password'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'For security reasons, please enter your password to complete account deletion:',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: securityController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                        ),
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: () =>
                          Navigator.pop(context, securityController.text),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              );

              securityController.dispose();

              if (passwordConfirm == null ||
                  passwordConfirm.isEmpty ||
                  !context.mounted) return;

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text("Deleting account..."),
                    ],
                  ),
                ),
              );

              try {
                // Call the user profile service to delete the account
                final userProfileService = ref.read(userProfileServiceProvider);
                await userProfileService.deleteAccount(passwordConfirm);

                // Close the loading dialog
                if (context.mounted &&
                    Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                // Get the updated user accounts list
                final userAccounts =
                    await ref.read(credentialServiceProvider).getUserAccounts();
                // Navigate to login screen
                if (context.mounted && userAccounts.isEmpty) {
                  // If no accounts left, go to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } else {
                  // If accounts remain, go back to the account settings screen
                  Navigator.of(context).pop();

                  // Set the first account as active
                  if (userAccounts.isNotEmpty) {
                    final firstAccount = userAccounts.first;
                    await ref
                        .read(authServiceProvider)
                        .switchAccount(firstAccount['email']!);
                  }
                  // Refresh the page to show updated accounts
                  ref.refresh(userAccountsProvider);
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                      ),
                    );
                  }
                }
              } catch (e) {
                // Close the loading dialog
                if (context.mounted &&
                    Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
