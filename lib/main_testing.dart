import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'package:smoke_log/theme/app_theme.dart';
import 'package:smoke_log/theme/theme_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smoke_log/services/auth_service.dart';
import 'package:smoke_log/providers/consolidated_auth_provider.dart'
    as consolidated;
import 'package:firebase_auth/firebase_auth.dart';

// A mock User implementation for testing
class TestUser implements User {
  @override
  String get uid => 'test-user-id';

  @override
  String? get email => 'test@example.com';

  @override
  String? get displayName => 'Test User';

  // Implement all the other required methods and properties...
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Special entry point for UI testing that bypasses Firebase auth
void main() {
  // Create provider overrides for testing
  final testProviders = [
    // Override auth state to always return a logged-in user
    consolidated.authStateProvider
        .overrideWith((ref) => Stream.value(TestUser())),

    // Override auth type to simulate password login
    consolidated.authTypeProvider.overrideWith((ref) => 'password'),

    // Override user accounts to provide test accounts
    consolidated.userAccountsProvider.overrideWith((ref) => Future.value([
          {
            'userId': 'test-user-id',
            'email': 'test@example.com',
            'authType': 'password',
            'firstName': 'Test'
          },
          {
            'userId': 'other-user-id',
            'email': 'other@example.com',
            'authType': 'google',
            'firstName': 'Other'
          },
        ])),

    // Override enriched accounts provider
    consolidated.enrichedAccountsProvider.overrideWith((ref) => Future.value([
          {
            'userId': 'test-user-id',
            'email': 'test@example.com',
            'authType': 'password',
            'firstName': 'Test',
            'hasUniqueName': true
          },
          {
            'userId': 'other-user-id',
            'email': 'other@example.com',
            'authType': 'google',
            'firstName': 'Other',
            'hasUniqueName': true
          },
        ])),
  ];

  runApp(
    ProviderScope(
      overrides: testProviders,
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const TestingApp(),
      ),
    ),
  );
}

class TestingApp extends ConsumerWidget {
  const TestingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider.Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smoke Log',
      theme: themeProvider.isDarkMode
          ? AppTheme.darkTheme(themeProvider.accentColor)
          : AppTheme.lightTheme(themeProvider.accentColor),
      home: const HomeScreen(), // Directly show home screen for testing
    );
  }
}
