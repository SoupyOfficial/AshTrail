import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smoke_log/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:io' show Platform;
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/coordinate_finder.dart';

// Check if app is running in screenshot mode
bool get isScreenshotMode {
  // Check using dart-define (works with XCUITest)
  if (const bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false)) {
    return true;
  }

  // Fallback to route name check (for Fastlane)
  if (Platform.isIOS) {
    try {
      final args = PlatformDispatcher.instance.defaultRouteName;
      if (args.contains('FASTLANE_SNAPSHOT') ||
          args.contains('SCREENSHOT_MODE')) {
        return true;
      }
    } catch (_) {}
  }

  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print debug info to help with troubleshooting
  print('SCREENSHOT_MODE: ${isScreenshotMode}');
  print('Platform route: ${PlatformDispatcher.instance.defaultRouteName}');

  // Skip Firebase initialization in screenshot mode
  if (!isScreenshotMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore caching
    FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

    // Auto sign-in for development mode (skip for screenshot mode)
    if (kDebugMode && !isScreenshotMode) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'test@test.com',
          password: 'test11',
        );
        print('Debug mode: Auto signed in with test account');
      } catch (e) {
        print('Debug mode: Auto sign-in failed: $e');
      }
    }
  }

  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget app = Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Smoke Log',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          key: ValueKey(themeProvider.themeMode),
          navigatorKey: GlobalNavigatorKey.navigatorKey,
          home: isScreenshotMode
              ? const HomeScreen() // Direct to HomeScreen in screenshot mode
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData) {
                      return const HomeScreen();
                    }
                    return const LoginScreen();
                  },
                ),
        );
      },
    );

    // Wrap with CoordinateFinder only during development
    if (isScreenshotMode && kDebugMode) {
      app = CoordinateFinder(child: app);
    }

    return app;
  }
}

// Add a global navigator key
class GlobalNavigatorKey {
  static final navigatorKey = GlobalKey<NavigatorState>();
}
