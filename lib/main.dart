import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/l10n/app_localizations.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_provider.dart';
import 'audio/playback_controller.dart';
import 'audio/sonara_audio_handler.dart';
import 'core/constants/licenses.dart';
import 'core/logging/local_logger.dart';
import 'core/services/audio_intent_service.dart';
import 'core/services/widget_service.dart';
import 'data/db/app_database.dart';
import 'data/db/database_provider.dart';
import 'domain/services/audio_settings_service.dart';
import 'domain/services/device_profile_service.dart';
import 'domain/services/queue_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerSonaraLicense();

  // Android 10+ and Android 15 edge-to-edge system chrome configuration
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Local rotating file logger (100% offline)
  await LocalLogger.instance.init();

  FlutterError.onError = (details) {
    LocalLogger.instance.error(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LocalLogger.instance.error(
      'PlatformDispatcher Unhandled Error',
      error,
      stack,
    );
    return true;
  };

  final database = AppDatabase();
  final queueManager = QueueManager(db: database);

  SonaraAudioHandler? audioHandler;
  try {
    final settingsNotifier = AudioSettingsNotifier(database);
    final profileService = DeviceProfileService(
      db: database,
      settingsNotifier: settingsNotifier,
    );
    audioHandler = await AudioService.init(
      builder: () => SonaraAudioHandler(
        queueManager: queueManager,
        db: database,
        deviceProfileService: profileService,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.sonara.playback',
        androidNotificationChannelName: 'Sonara Music Playback',
        androidNotificationIcon: 'drawable/ic_notification',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF6750A4),
      ),
    );
    // Non-blocking state restoration so app renders first frame immediately
    unawaited(
      audioHandler.restoreSavedState().catchError((Object e) {
        debugPrint('restoreSavedState non-fatal error: $e');
      }),
    );
  } catch (e) {
    debugPrint('AudioService.init skipped or unavailable: $e');
  }

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      if (audioHandler != null)
        audioHandlerProvider.overrideWithValue(audioHandler),
    ],
  );

  try {
    final controller = container.read(playbackControllerProvider);
    final router = container.read(appRouterProvider);
    final intentService = AudioIntentService(
      playbackController: controller,
      db: database,
      onNavigate: (route) => router.go(route),
    );
    await intentService.init();
    // Initialize widget sync
    container.read(widgetServiceProvider);
  } catch (e) {
    debugPrint('AudioIntentService / WidgetService init skipped: $e');
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const SonaraApp()),
  );
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
