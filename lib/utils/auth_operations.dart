import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/screens/login_screen.dart';
import 'package:smoke_log/services/auth_service.dart';
import '../providers/consolidated_auth_provider.dart' as consolidated;

class AuthOperations {
  /// Switch to another user account with loading indicator and error handling
  static Future<bool> switchAccount(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    _showLoadingDialog(context, 'Switching accounts...');

    try {
      await ref.read(consolidated.authServiceProvider).switchAccount(email);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to $email')),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Switch account error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch account: $e')),
        );
      }
      return false;
    } finally {
      // if (context.mounted &&
      //     Navigator.of(context, rootNavigator: true).canPop()) {
      //   Navigator.of(context, rootNavigator: true).pop();
      // }
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

    _showLoadingDialog(context, 'Signing out...');

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
      return SignOutResult
          .fullySignedOut; // Default to fully signed out on error
    } finally {
      // if (context.mounted &&
      //     Navigator.of(context, rootNavigator: true).canPop()) {
      //   Navigator.of(context, rootNavigator: true).pop();
      // }
    }
  }

  // Helper to refresh all auth-related providers
  static void _refreshAuthProviders(WidgetRef ref) {
    ref.invalidate(consolidated.userAccountsProvider);
    ref.invalidate(consolidated.enrichedAccountsProvider);
    ref.invalidate(consolidated.authStateProvider);
    ref.invalidate(consolidated.authTypeProvider);
    ref.invalidate(consolidated.activeAccountProvider);
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
