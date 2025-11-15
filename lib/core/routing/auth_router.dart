import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/login_screen.dart';
import '../../screens/home_screen.dart';
import '../../core/initialization/app_initializer.dart';
import '../../core/interfaces/firebase_auth_interface.dart';

/// Service responsible for routing based on authentication state
/// Single Responsibility: Determine which screen to show based on auth state
/// Uses dependency injection for Firebase Auth
class AuthRouter {
  final IFirebaseAuth _auth;

  AuthRouter(this._auth);

  /// Get the appropriate home widget based on authentication state
  /// Returns HomeScreen directly in screenshot mode, otherwise uses StreamBuilder
  Widget buildHomeWidget() {
    if (AppInitializer.isScreenshotMode) {
      return const HomeScreen();
    }

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
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
    );
  }
}

