import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:smoke_log/utils/auth_operations.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../services/credential_service.dart';
import '../theme/theme_provider.dart';
import 'user_switcher.dart';
import 'sync_indicator.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final Color? backgroundColor; // Add parameter for custom background color

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.backgroundColor, // Allow custom background color to be passed
  });

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  Future<void> _switchAccount(String email) async {
    if (email == FirebaseAuth.instance.currentUser?.email) return;

    // Use the AuthOperations utility to handle switching accounts
    await AuthOperations.switchAccount(context, ref, email);

    // Refresh relevant providers after switching
    ref.invalidate(userAccountsProvider);
    ref.invalidate(authStateProvider);
    ref.invalidate(userAuthTypeProvider);
  }

  Future<void> _signOut() async {
    await AuthOperations.logout(context, ref);
  }

  Future<void> _handleAccountSelection(String email) async {
    if (email == 'Add Account') {
      // Sign out then redirect to the login screen
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

    // Get the accent color from ThemeProvider
    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context);
    final accentColor = widget.backgroundColor ?? themeProvider.accentColor;

    return authState.when(
      data: (user) {
        final currentEmail = user?.email ?? 'Guest';

        return AppBar(
          backgroundColor: accentColor, // Use the accent color or custom color
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
              data: (accounts) {
                // Map each account to ensure it has the right type
                final enrichedAccounts = accounts.map((account) {
                  // Convert to Map<String, dynamic> for consistency with the enrichedAccountsProvider
                  final Map<String, dynamic> enrichedAccount =
                      Map<String, dynamic>.from(
                          account.map((k, v) => MapEntry(k, v)));

                  // Try to get the displayName from auth and extract first name
                  if (user?.email == account['email'] &&
                      user?.displayName != null) {
                    final displayNameParts = user!.displayName!.split(' ');
                    if (displayNameParts.isNotEmpty) {
                      enrichedAccount['firstName'] = displayNameParts.first;
                    }
                  }

                  return enrichedAccount;
                }).toList();

                return UserSwitcher(
                  accounts: enrichedAccounts,
                  currentEmail: currentEmail,
                  onSwitchAccount: _handleAccountSelection,
                  authType: authTypeState.value ?? 'none',
                );
              },
              loading: () => const SizedBox(width: 24),
              error: (_, __) => const SizedBox(width: 24),
            ),
            // Removed ThemeToggleSwitch and logout button
          ],
        );
      },
      loading: () => AppBar(
        title: Text(widget.title ?? 'Smoke Log'),
        backgroundColor: accentColor, // Use accent color here too
      ),
      error: (_, __) => AppBar(
        title: Text(widget.title ?? 'Smoke Log'),
        backgroundColor: accentColor, // And here
      ),
    );
  }
}
