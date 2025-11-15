import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'core/initialization/app_initializer.dart';
import 'core/routing/auth_router.dart';
import 'core/di/dependency_injection.dart';
import 'providers/theme_service_provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'utils/coordinate_finder.dart';

/// Application entry point
/// Single Responsibility: Initialize app and set up providers
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize application services
  await AppInitializer.initialize();

  runApp(
    riverpod.ProviderScope(
      child: riverpod.Consumer(
        builder: (context, ref, _) {
          final themeService = ref.watch(userThemeServiceProvider);
          final auth = ref.watch(firebaseAuthInstanceProvider);
          
          return ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(
              themeService: themeService,
              auth: auth,
            ),
            child: const MyApp(),
          );
        },
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
        return riverpod.Consumer(
          builder: (context, ref, _) {
            final auth = ref.watch(firebaseAuthProvider);
            final authRouter = AuthRouter(auth);
            
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Smoke Log',
              theme: AppTheme.lightTheme(themeProvider.accentColor),
              darkTheme: AppTheme.darkTheme(themeProvider.accentColor),
              themeMode: themeProvider.themeMode,
              key: ValueKey(themeProvider.themeMode),
              navigatorKey: GlobalNavigatorKey.navigatorKey,
              home: authRouter.buildHomeWidget(),
            );
          },
        );
      },
    );

    // Wrap with CoordinateFinder only during development and screenshot mode
    if (AppInitializer.isScreenshotMode && kDebugMode) {
      app = CoordinateFinder(child: app);
    }

    return app;
  }
}

// Add a global navigator key
class GlobalNavigatorKey {
  static final navigatorKey = GlobalKey<NavigatorState>();
}
