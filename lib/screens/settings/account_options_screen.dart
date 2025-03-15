import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/user_profile_provider.dart';
import '../login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountOptionsScreen extends ConsumerStatefulWidget {
  const AccountOptionsScreen({super.key});

  @override
  ConsumerState<AccountOptionsScreen> createState() =>
      _AccountOptionsScreenState();
}

class _AccountOptionsScreenState extends ConsumerState<AccountOptionsScreen> {
  bool _isLoading = false;

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? errorMessage;
    bool showPassword = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setDialogState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: !showPassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setDialogState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: !showPassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setDialogState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: !showPassword,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Validate passwords
                if (newPasswordController.text.length < 6) {
                  setDialogState(() {
                    errorMessage = 'New password must be at least 6 characters';
                  });
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  setDialogState(() {
                    errorMessage = 'Passwords do not match';
                  });
                  return;
                }

                try {
                  setDialogState(() {
                    errorMessage = null;
                    _isLoading = true;
                  });

                  final userProfileService =
                      ref.read(userProfileServiceProvider);
                  await userProfileService.updatePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password updated successfully')),
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    _isLoading = false;
                    errorMessage = 'Failed to update password: ${e.toString()}';
                  });
                }
              },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _disableAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Account'),
        content: const Text(
            'Your account will be disabled but your data will be preserved. '
            'You will need to contact support to reactivate your account. '
            'Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      await userProfileService.disableAccount();

      // Sign out and go to login screen
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been disabled')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable account: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // First confirmation
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'This will permanently delete your account and all associated data. '
            'This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Password confirmation
    final passwordController = TextEditingController();
    String? errorMessage;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your password to confirm account deletion:'),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Password is required';
                  });
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );

    if (confirm2 != true) {
      passwordController.dispose();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      await userProfileService.deleteAccount(passwordController.text);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      passwordController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Account Options',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Change password button
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),

                  const Divider(height: 32),
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Disable account button
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.block,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: const Text('Disable Account'),
                      subtitle: const Text(
                          'Your account will be disabled but your data will be preserved'),
                      onTap: _disableAccount,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delete account button
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: const Text('Delete Account'),
                      subtitle: const Text(
                          'Permanently delete your account and all associated data'),
                      onTap: _deleteAccount,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
