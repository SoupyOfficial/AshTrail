import 'package:flutter/material.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'package:smoke_log/theme/app_theme.dart';

// Special entry point for UI testing that bypasses Firebase auth
void main() {
  runApp(const TestingApp());
}

class TestingApp extends StatelessWidget {
  const TestingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smoke Log',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(), // Directly show home screen for testing
    );
  }
}
