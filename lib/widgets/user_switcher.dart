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
            ...accounts.map((account) {
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
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      accountAuthType == 'google'
                          ? FontAwesomeIcons.google
                          : Icons.email,
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
              style: TextStyle(
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
}
