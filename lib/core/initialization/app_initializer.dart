import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:ui';
import '../../services/cache_service.dart';
import '../../core/di/dependency_injection.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service responsible for application initialization
/// Single Responsibility: Handle all app startup logic
class AppInitializer {
  /// Flag to enable/disable auto-login in development mode
  static const bool enableAutoLoginInDevMode = false;

  /// Check if app is running in screenshot mode
  static bool get isScreenshotMode {
    // Check using dart-define (works with XCUITest)
    if (const bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false)) {
      return true;
    }

    // Skip platform-specific checks on web
    if (kIsWeb) {
      return false;
    }

    // Fallback to route name check (for Fastlane) - only for iOS
    try {
      final platform = defaultTargetPlatform;
      if (platform == TargetPlatform.iOS) {
        final args = PlatformDispatcher.instance.defaultRouteName;
        if (args.contains('FASTLANE_SNAPSHOT') ||
            args.contains('SCREENSHOT_MODE')) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Initialize the application
  /// Returns true if initialization was successful
  static Future<bool> initialize() async {
    // Print debug info to help with troubleshooting
    if (kDebugMode) {
      print('SCREENSHOT MODE: $isScreenshotMode');
      print('Platform route: ${PlatformDispatcher.instance.defaultRouteName}');
    }

    // Skip initialization in screenshot mode
    if (isScreenshotMode) {
      return true;
    }

    try {
      // Initialize Firebase through dependency injection
      await initializeFirebase();

      // Initialize cache service
      final cacheService = CacheService();
      await cacheService.init();

      // Auto sign-in for development mode (skip for screenshot mode)
      if (kDebugMode && !isScreenshotMode && enableAutoLoginInDevMode) {
        await _performAutoLogin();
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in app initialization: $e');
      }
      // Continue with app initialization even if setup fails
      // The app will handle unavailability appropriately
      return false;
    }
  }

  /// Perform auto-login in development mode
  static Future<void> _performAutoLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'test11',
      );
      if (kDebugMode) {
        print('Debug mode: Auto signed in with test account');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug mode: Auto sign-in failed: $e');
      }
    }
  }
}

