import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_provider.dart';
import '../../app/theme/theme_tokens.dart';
import '../../core/constants/licenses.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/database_provider.dart';
import '../../shared/artwork/sonara_brand_logo.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'HAPTICS & FEEDBACK',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration_rounded),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on playback controls and actions'),
            value: ref.watch(hapticsEnabledProvider),
            onChanged: (val) {
              ref.read(hapticsEnabledProvider.notifier).state = val;
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'AUDIO QUALITY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.equalizer_rounded),
            title: const Text('Equalizer'),
            subtitle: const Text('5-band EQ, presets, and sound enhancements'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/equalizer'),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Audio Settings & Effects'),
            subtitle: const Text(
              'ReplayGain, crossfade, smooth fades, and balance',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/audio-settings'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'LIBRARY TOOLS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_rounded),
            title: const Text('Duplicate Audio Finder'),
            subtitle: const Text(
              'Find and manage duplicate tracks by size & metadata',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/duplicates'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Backup & Restore'),
            subtitle: const Text(
              'Export and restore playlists, favorites, and settings',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/backup-restore'),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline_rounded),
            title: const Text('Storage Inspector & Cache'),
            subtitle: const Text('Inspect database and thumbnail cache usage'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/storage-inspector'),
          ),
          ListTile(
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amber,
            ),
            title: const Text('Sonara Wrapped'),
            subtitle: const Text(
              '100% offline recap cards & listening analytics',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/wrapped'),
          ),
          ListTile(
            leading: const Icon(
              Icons.content_cut_rounded,
              color: Colors.tealAccent,
            ),
            title: const Text('Audio Cutter & Ringtone Studio'),
            subtitle: const Text(
              'Slice songs into ringtones, alarms & notification sounds',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final db = ref.read(databaseProvider);
              final tracks = await db.getAllTracks();
              if (tracks.isNotEmpty && context.mounted) {
                await context.push('/cutter?trackKey=${tracks.first.trackKey}');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No tracks available to trim. Add songs to your library first.',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(),

          if (kDebugMode) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'LIBRARY & PERMISSIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security_rounded),
              title: const Text('Storage Permissions & Onboarding'),
              subtitle: const Text('Check audio permission and scan status'),
              onTap: () => context.push('/permission'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'DEBUG TOOLS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.orangeAccent,
              ),
              title: const Text('Clear Database'),
              subtitle: const Text('Removes all indexed and synthetic data'),
              onTap: () async {
                final db = ref.read(databaseProvider);
                await db.clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database cleared successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
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
            subtitle: Text('Version 1.0.0 • 100% Offline & Private'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Sonara License'),
            subtitle: const Text('MIT License • Free & Open Source'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showSonaraLicenseDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Third-Party Licenses'),
            subtitle: const Text('Open-source libraries powering Sonara'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Sonara',
                applicationVersion: '1.0.0',
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(AppSpacing.s),
                  child: SonaraBrandLogo(size: 48),
                ),
                applicationLegalese: '© 2026 Sonara Contributors\nReleased under the MIT License',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSonaraLicenseDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Center(child: SonaraBrandLogo(size: 40)),
          title: const Text('Sonara License', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    'MIT License • OSI Approved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Sonara is free and open-source software. You are free to use, modify, and distribute it in accordance with the terms below:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(AppSpacing.s),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: const SingleChildScrollView(
                    child: SelectableText(
                      kSonaraMitLicense,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy License'),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: kSonaraMitLicense));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('MIT License copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _themeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light (White Mode)';
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
                    .setThemeMode(AppThemeMode.light);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  const Icon(Icons.light_mode_rounded, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Light (White Mode)')),
                  if (current == AppThemeMode.light)
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.dark);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_rounded, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Dark (Default)')),
                  if (current == AppThemeMode.dark)
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.amoled);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  const Icon(Icons.contrast_rounded, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('AMOLED Dark (Pure Black)')),
                  if (current == AppThemeMode.amoled)
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeMode.system);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  const Icon(Icons.brightness_auto_rounded, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('System Default')),
                  if (current == AppThemeMode.system)
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
