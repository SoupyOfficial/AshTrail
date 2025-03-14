import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/credential_service.dart';
import 'theme_toggle_switch.dart';
import 'user_switcher.dart';
import 'sync_indicator.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    super.key,
    required this.title,
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

  Future<List<Map<String, String>>> _getUserAccounts() async {
    final credentialService = ref.read(credentialServiceProvider);
    return credentialService.getUserAccounts();
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authTypeState = ref.watch(userAuthTypeProvider);

    return authState.when(
      data: (user) {
        final currentEmail = user?.email ?? 'Guest';

        return AppBar(
          title: Text(widget.title),
          actions: [
            // Keep only the sync indicator (removed duplicate ConnectivityIndicator)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: SyncIndicator(),
            ),
            // User account switcher
            FutureBuilder<List<Map<String, String>>>(
              future: _getUserAccounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    snapshot.hasError) {
                  return const SizedBox();
                }

                final accounts = snapshot.data ?? [];

                return UserSwitcher(
                  accounts: accounts,
                  currentEmail: currentEmail,
                  onSwitchAccount: _handleAccountSelection,
                  authType: authTypeState.value ?? 'none',
                );
              },
            ),
            const ThemeToggleSwitch(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(),
            ),
          ],
        );
      },
      loading: () => AppBar(title: Text(widget.title)),
      error: (_, __) => AppBar(title: Text(widget.title)),
    );
  }
}
