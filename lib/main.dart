import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/l10n/app_localizations.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SonaraApp()));
}

class SonaraApp extends ConsumerWidget {
  const SonaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    final lightTheme = AppTheme.light(seedColor: accentColor);
    final darkTheme = AppTheme.dark(seedColor: accentColor);
    final amoledTheme = AppTheme.amoled(seedColor: accentColor);

    ThemeData effectiveTheme;
    ThemeData? effectiveDarkTheme;
    ThemeMode effectiveMode;

    switch (themeMode) {
      case AppThemeMode.system:
        effectiveTheme = lightTheme;
        effectiveDarkTheme = darkTheme;
        effectiveMode = ThemeMode.system;
      case AppThemeMode.light:
        effectiveTheme = lightTheme;
        effectiveDarkTheme = null;
        effectiveMode = ThemeMode.light;
      case AppThemeMode.dark:
        effectiveTheme = darkTheme;
        effectiveDarkTheme = null;
        effectiveMode = ThemeMode.dark;
      case AppThemeMode.amoled:
        effectiveTheme = amoledTheme;
        effectiveDarkTheme = null;
        effectiveMode = ThemeMode.dark;
    }

    return MaterialApp.router(
      title: 'Sonara',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      darkTheme: effectiveDarkTheme,
      themeMode: effectiveMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
