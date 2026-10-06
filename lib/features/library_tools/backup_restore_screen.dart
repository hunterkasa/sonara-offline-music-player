import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/theme/theme_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../domain/services/backup_service.dart';

final localBackupsProvider = FutureProvider.autoDispose<List<File>>((
  ref,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final backupDir = Directory(p.join(dir.path, 'backups'));
  if (!await backupDir.exists()) {
    await backupDir.create(recursive: true);
  }
  final files = <File>[];
  await for (final entity in backupDir.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      files.add(entity);
    }
  }
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return files;
});

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isExporting = false;
  bool _isRestoring = false;

  Future<void> _createBackup() async {
    setState(() => _isExporting = true);
    final haptics = ref.read(hapticServiceProvider);
    haptics.light();

    try {
      final service = ref.read(backupServiceProvider);
      final jsonStr = await service.createBackupJson();

      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(dir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final file = File(p.join(backupDir.path, 'sonara_backup_$stamp.json'));
      await file.writeAsString(jsonStr);

      ref.invalidate(localBackupsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created: ${p.basename(file.path)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create backup: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _restoreFile(File file) async {
    setState(() => _isRestoring = true);
    final haptics = ref.read(hapticServiceProvider);
    haptics.medium();

    try {
      final content = await file.readAsString();
      final service = ref.read(backupServiceProvider);
      final result = await service.restoreBackupJson(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${result.playlistsRestored} playlists, ${result.favoritesRestored} favorites, and ${result.settingsRestored} settings!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to restore backup: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backupsAsync = ref.watch(localBackupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          // Create Backup Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.backup_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Export Library Backup',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Saves all your custom playlists, favorites, listening statistics, smart rules, and audio preferences into a portable JSON bundle.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _createBackup,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isExporting ? 'Creating Backup...' : 'Create Backup Now',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Available Backups Section
          Text(
            'SAVED LOCAL BACKUPS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          backupsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.m),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Text('Error loading backups: $err'),
            data: (backups) {
              if (backups.isEmpty) {
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'No local backups saved yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: backups.map((file) {
                  final name = p.basename(file.path);
                  final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
                  final modified = file
                      .lastModifiedSync()
                      .toString()
                      .split('.')
                      .first;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    color: theme.colorScheme.surfaceContainerLow,
                    child: ListTile(
                      leading: const Icon(
                        Icons.settings_backup_restore_rounded,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('$sizeKb KB · $modified'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_rounded),
                            tooltip: 'Restore this backup',
                            onPressed: _isRestoring
                                ? null
                                : () => _confirmRestore(file),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete backup',
                            onPressed: () async {
                              await file.delete();
                              ref.invalidate(localBackupsProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmRestore(File file) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Library Backup?'),
        content: Text(
          'This will import playlists, favorites, listening stats, and preferences from ${p.basename(file.path)}. Existing data will be safely merged and relinked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restoreFile(file);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
