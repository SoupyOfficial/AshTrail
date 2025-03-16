import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserSwitcher extends StatelessWidget {
  final List<Map<String, String>> accounts;
  final String currentEmail;
  final Function(String) onSwitchAccount;
  final String authType;

  const UserSwitcher({
    super.key,
    required this.accounts,
    required this.currentEmail,
    required this.onSwitchAccount,
    required this.authType,
  });

  @override
  Widget build(BuildContext context) {
    // Make sure we have accounts to show
    if (accounts.isEmpty) {
      return const SizedBox(); // Don't show anything if no accounts
    }

    // Check if current email is in the accounts list
    final bool currentEmailInAccounts = accounts.any(
      (account) => account['email'] == currentEmail,
    );

    // If current user isn't in the list but we have their email, create a temporary entry
    final displayAccounts = [...accounts];
    if (!currentEmailInAccounts && currentEmail != 'Guest') {
      displayAccounts.add({'email': currentEmail, 'authType': authType});
    }

    // Ensure interactive hit area is large enough
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: PopupMenuButton<String>(
        tooltip: 'Switch account',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        onSelected: onSwitchAccount,
        itemBuilder: (context) {
          final List<PopupMenuEntry<String>> menuItems = [
            ...displayAccounts.map((account) {
              final email = account['email'] ?? '';
              final accountAuthType = account['authType'] ?? 'password';
              final isCurrentUser = email == currentEmail;
              final icon = isCurrentUser ? Icons.check : null;

              return PopupMenuItem<String>(
                value: email,
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ] else
                      const SizedBox(width: 26), // Maintain consistent spacing
                    Expanded(
                      child: Text(email, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getAuthIcon(accountAuthType),
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              );
            }),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'Add Account',
              child: Row(
                children: [
                  Icon(Icons.person_add, size: 18),
                  SizedBox(width: 8),
                  Text('Add Account'),
                ],
              ),
            ),
          ];
          return menuItems;
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentEmail,
              style: const TextStyle(
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  IconData _getAuthIcon(String authType) {
    switch (authType) {
      case 'google':
        return FontAwesomeIcons.google;
      case 'apple':
        return FontAwesomeIcons.apple;
      case 'password':
      default:
        return Icons.email;
    }
  }
}
