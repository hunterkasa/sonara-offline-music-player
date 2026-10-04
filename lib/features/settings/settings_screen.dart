import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_provider.dart';
import '../../app/theme/theme_tokens.dart';
import '../../data/db/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'APPEARANCE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(_themeModeName(currentThemeMode)),
            onTap: () => _showThemeDialog(context, ref, currentThemeMode),
          ),
          const Divider(),
          if (kDebugMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'DEBUG TOOLS (PHASE 0)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.speed_rounded, color: Colors.amber),
              title: const Text('Seed 20,000 Synthetic DB Tracks'),
              subtitle: const Text(
                'Populates Drift DB for 60fps stress testing',
              ),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Seeding 20,000 synthetic rows in batches...',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                final db = ref.read(databaseProvider);
                final stopwatch = Stopwatch()..start();
                await db.seedSyntheticData(count: 20000);
                stopwatch.stop();
                final count = await db.getTrackCount();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seeded 20,000 tracks in ${stopwatch.elapsedMilliseconds} ms! Total: $count tracks.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'ABOUT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Sonara'),
            subtitle: Text(
              'Version 1.0.0 (Phase 0 Foundation) • 100% Offline & Private',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Sonara',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }

  String _themeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.amoled:
        return 'AMOLED Dark (Pure Black)';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode current,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select Theme'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.dark);
                Navigator.pop(ctx);
              },
              child: const Text('Dark (Default)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.amoled);
                Navigator.pop(ctx);
              },
              child: const Text('AMOLED Dark (Pure Black)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.light);
                Navigator.pop(ctx);
              },
              child: const Text('Light'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.system);
                Navigator.pop(ctx);
              },
              child: const Text('System Default'),
            ),
          ],
        );
      },
    );
  }
}
