import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../services/credential_service.dart';
import 'theme_toggle_switch.dart';
import 'user_switcher.dart';
import 'sync_indicator.dart';

// Provider for user accounts to prevent excessive rebuilds
final userAccountsProvider = FutureProvider<List<Map<String, String>>>((ref) {
  final credentialService = ref.read(credentialServiceProvider);
  return credentialService.getUserAccounts();
});

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
  });

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  Future<void> _switchAccount(String email) async {
    if (email == FirebaseAuth.instance.currentUser?.email) return;

    try {
      await ref.read(authServiceProvider).switchAccount(email);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch account: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
  }

  Future<void> _handleAccountSelection(String email) async {
    if (email == 'Add Account') {
      // Sign out then redirect to the login screen.
      await _signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      await _switchAccount(email);
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authTypeState = ref.watch(userAuthTypeProvider);
    final accountsAsync = ref.watch(userAccountsProvider);

    return authState.when(
      data: (user) {
        final currentEmail = user?.email ?? 'Guest';

        return AppBar(
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _navigateToSettings,
                  tooltip: 'Settings',
                ),
          title: Text(widget.title ?? 'Smoke Log'),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: SyncIndicator(),
            ),
            // User account switcher with improved state handling
            accountsAsync.when(
              data: (accounts) => UserSwitcher(
                accounts: accounts,
                currentEmail: currentEmail,
                onSwitchAccount: _handleAccountSelection,
                authType: authTypeState.value ?? 'none',
              ),
              loading: () => const SizedBox(width: 24),
              error: (_, __) => const SizedBox(width: 24),
            ),
            const ThemeToggleSwitch(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(),
            ),
          ],
        );
      },
      loading: () => AppBar(title: Text(widget.title ?? 'Smoke Log')),
      error: (_, __) => AppBar(title: Text(widget.title ?? 'Smoke Log')),
    );
  }
}
