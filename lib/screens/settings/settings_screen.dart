import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smoke_log/screens/settings/accent_color_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/theme_provider.dart';
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
      appBar: const CustomAppBar(title: 'Settings', showBackButton: true),
      body: userProfileAsync.when(
        data: (profile) {
          return ListView(
            children: [
              if (profile != null)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
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
              // Add new section for app customization
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: Text(
                  'Customization',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              provider.Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    title: Text(
                      themeProvider.isDarkMode
                          ? 'Switch to Light Theme'
                          : 'Switch to Dark Theme',
                    ),
                    subtitle: const Text('Change app appearance'),
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),

              // Add accent color option
              provider.Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    leading: const Icon(Icons.color_lens),
                    title: const Text('Accent Color'),
                    subtitle: const Text('Customize app colors'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccentColorScreen(),
                        ),
                      );
                    },
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
        error: (error, _) =>
            Center(child: Text('Error loading profile: $error')),
      ),
    );
  }
}
