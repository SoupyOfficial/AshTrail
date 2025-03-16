import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoke_log/screens/home_screen.dart';
import 'package:smoke_log/screens/login_screen.dart';
import '../helpers/auth_test_helper.dart';

void main() {
  late AuthTestHelper authHelper;

  setUp(() {
    authHelper = AuthTestHelper();
    // Register fallback values for mocktail
    registerFallbackValue(Uri());
  });

  tearDown(() {
    authHelper.dispose();
  });

  group('LoginScreen', () {
    testWidgets('should display email and password fields',
        (WidgetTester tester) async {
      // Arrange - setup auth state to return not logged in
      final controller = StreamController<User?>();
      when(() =>
              authHelper.providerContainer.mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => controller.stream);
      controller.add(null);

      // Act - build the login screen
      await tester.pumpWidget(authHelper.buildLoginScreen());
      await tester.pumpAndSettle();

      // Assert - verify the fields are displayed
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Need an account? Register'), findsOneWidget);
    });

    testWidgets('should show error on invalid login',
        (WidgetTester tester) async {
      // Arrange - setup login failure
      authHelper.setupLoginFailure();

      // Act - build the login screen and attempt login
      await tester.pumpWidget(authHelper.buildLoginScreen());
      await tester.pumpAndSettle();

      // Fill out the form
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');

      // Press the login button
      await tester.ensureVisible(find.text('Login').last);
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Assert - verify error message appears
      expect(
          find.text('Login failed: Exception: Wrong password'), findsOneWidget);
    });

    testWidgets('should navigate to home screen on successful login',
        (WidgetTester tester) async {
      // Arrange - setup login success
      authHelper.setupLoginSuccess();

      // Mock navigation
      final mockObserver = MockNavigatorObserver();

      // Act - build login screen with navigation observer
      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        navigatorObservers: [mockObserver],
      ));

      // Fill login form
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      // Press login button
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Assert - verify navigation occurred (HomeScreen is not directly accessible here, so we check for navigation events)
      verify(() => mockObserver.didPush(any(), any()))
          .called(2); // Initial push + login push
    });
  });
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class StreamController<T> {
  final _controller = StreamController<T>();

  void add(T value) {
    _controller.add(value);
  }

  Stream<T> get stream => _controller.stream;

  void close() {
    _controller.close();
  }
}
