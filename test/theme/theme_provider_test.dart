import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../mocks/theme_provider_mock.dart';

void main() {
  group('ThemeProvider', () {
    test('should start with default light theme', () {
      // Arrange
      final themeProvider = MockThemeProvider();

      // Assert
      expect(themeProvider.isDarkMode, isFalse);
      expect(themeProvider.accentColor, equals(Colors.blue));
      expect(themeProvider.themeMode, equals(ThemeMode.light));
    });

    test('should toggle theme mode', () async {
      // Arrange
      final themeProvider = MockThemeProvider();
      bool listenerCalled = false;

      themeProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      await themeProvider.toggleTheme();

      // Assert
      expect(themeProvider.isDarkMode, isTrue);
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(listenerCalled, isTrue);
    });

    test('should change accent color', () async {
      // Arrange
      final themeProvider = MockThemeProvider();
      bool listenerCalled = false;

      themeProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      await themeProvider.setAccentColor(Colors.red);

      // Assert
      expect(themeProvider.accentColor, equals(Colors.red));
      expect(listenerCalled, isTrue);
    });
  });
}
