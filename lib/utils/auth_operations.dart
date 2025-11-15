import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/screens/login_screen.dart';
import '../domain/interfaces/auth_service_interface.dart';
import '../providers/consolidated_auth_provider.dart' as consolidated;
import '../providers/user_account_provider.dart';

class AuthOperations {
  /// Switch to another user account with loading indicator and error handling
  static Future<bool> switchAccount(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    _showLoadingDialog(context, 'Switching accounts...');

    debugPrint('---------------------------------------------');
    debugPrint('Switching to account: $email');

    try {
      // Get details before switch for comparison
      final currentUser = ref.read(consolidated.authStateProvider).value;
      debugPrint('Current user: ${currentUser?.email}');
      debugPrint('Current displayName: ${currentUser?.displayName}');

      await ref.read(consolidated.authServiceProvider).switchAccount(email);

      // Get details after switch for verification
      final newUser = ref.read(consolidated.authStateProvider).value;
      debugPrint('Switched successfully');
      debugPrint('New user: ${newUser?.email}');
      debugPrint('New displayName: ${newUser?.displayName}');

      final userType = ref.read(consolidated.authTypeProvider);
      debugPrint('New auth type: $userType');
      debugPrint('---------------------------------------------');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to $email')),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Switch account error: $e');
      debugPrint('---------------------------------------------');
      if (context.mounted) {
        final bool shouldTryRelogin = e.toString().contains('token') ||
            e.toString().contains('expired') ||
            e.toString().contains('invalid');

        if (shouldTryRelogin) {
          // Close the current dialog
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Show a different dialog asking to re-login
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Session Expired'),
              content: Text(
                  'Your session for $email has expired. Please log in again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(isAddingAccount: true)),
                    );
                  },
                  child: const Text('Log In'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to switch account: $e')),
          );
        }
      }
      return false;
    } finally {
      if (context.mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Log out with confirmation, loading dialog and proper navigation
  static Future<SignOutResult> logout(
      BuildContext context, WidgetRef ref) async {
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

    if (confirmed != true) return SignOutResult.fullySignedOut;

    // Store dialog context reference to ensure we can dismiss it later
    BuildContext? dialogContext;

    // Show loading dialog with a stored context reference
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx; // Store the dialog context
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Signing out...'),
              ],
            ),
          );
        },
      );
    }

    try {
      // Perform the logout operation
      final result = await ref.read(consolidated.authServiceProvider).signOut();

      debugPrint('Logout result: $result');

      // Show a message if switched to another user
      if (result == SignOutResult.switchedToAnotherUser && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to another user')),
        );
      }

      return result;
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
      return SignOutResult.fullySignedOut;
    } finally {
      // Safely close the dialog using the stored context
      try {
        if (dialogContext != null &&
            (context.mounted || dialogContext!.mounted)) {
          Navigator.of(dialogContext!).pop();
        }
      } catch (e) {
        debugPrint('Error closing dialog: $e');
      }

      // Refresh all auth-related providers with delay to prevent crash
      Future.microtask(() {
        try {
          _refreshAuthProviders(ref);
        } catch (e) {
          debugPrint('Error refreshing providers: $e');
        }
      });
    }
  }

  // Helper to refresh all auth-related providers
  static void _refreshAuthProviders(WidgetRef ref) {
    try {
      ref.invalidate(consolidated.userAccountsProvider);
      ref.invalidate(enrichedAccountsProvider);
      ref.invalidate(consolidated.authStateProvider);
      ref.invalidate(consolidated.authTypeProvider);
      ref.invalidate(consolidated.activeAccountProvider);
    } catch (e) {
      debugPrint('Error during provider refresh: $e');
    }
  }

  // Helper to show a loading dialog
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );

    // Set a timeout to ensure dialog closes
    Future.delayed(const Duration(seconds: 5), () {
      if (context.mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }
}
