import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/app_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../theme/theme.dart';

/// Root application widget. Wires the router and theme from providers.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStorageProvider);
    if (authState.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final router = ref.watch(goRouterProvider);
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(maxScaleFactor: 1.0);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: MaterialApp.router(
        title: 'Sintera',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
