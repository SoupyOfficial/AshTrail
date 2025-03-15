import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_app_bar.dart';
import 'personal_info_screen.dart';
import 'my_data_screen.dart';
import 'account_options_screen.dart';
import '../../providers/user_profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: userProfileAsync.when(
        data: (profile) {
          return ListView(
            children: [
              if (profile != null)
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    '${profile.firstName} ${profile.lastName ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(profile.email),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Personal Information'),
                subtitle: const Text('Update your profile details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_usage),
                title: const Text('My Data'),
                subtitle: const Text('View, export, or delete your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyDataScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Account Options'),
                subtitle: const Text('Change password, delete account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountOptionsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('App information and licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Smoke Log',
                    applicationVersion: '1.0.0',
                    applicationIcon: const FlutterLogo(),
                    applicationLegalese: '© 2023 Smoke Log',
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }
}
