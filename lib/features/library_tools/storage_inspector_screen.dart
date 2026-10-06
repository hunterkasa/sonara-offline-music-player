import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../domain/services/storage_inspector_service.dart';

final storageInfoProvider = FutureProvider.autoDispose<StorageInfo>((ref) {
  final service = ref.watch(storageInspectorServiceProvider);
  return service.getStorageInfo();
});

class StorageInspectorScreen extends ConsumerStatefulWidget {
  const StorageInspectorScreen({super.key});

  @override
  ConsumerState<StorageInspectorScreen> createState() =>
      _StorageInspectorScreenState();
}

class _StorageInspectorScreenState
    extends ConsumerState<StorageInspectorScreen> {
  bool _isClearingCache = false;
  bool _isOptimizingDb = false;

  Future<void> _handleClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Artwork Cache?'),
        content: const Text(
          'This will delete all cached album art thumbnails. '
          'Thumbnails will be regenerated from audio files when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ref.read(hapticServiceProvider).medium();
    setState(() => _isClearingCache = true);

    try {
      final service = ref.read(storageInspectorServiceProvider);
      final freed = await service.clearArtworkCache();
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cleared ${StorageInspectorService.formatBytes(freed)} of artwork thumbnails',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }

  Future<void> _handleVacuumDb() async {
    ref.read(hapticServiceProvider).light();
    setState(() => _isOptimizingDb = true);

    try {
      final service = ref.read(storageInspectorServiceProvider);
      await service.vacuumDatabase();
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database vacuumed and optimized successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to optimize database: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOptimizingDb = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storageAsync = ref.watch(storageInfoProvider);
    final haptics = ref.read(hapticServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Inspector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              haptics.light();
              ref.invalidate(storageInfoProvider);
            },
          ),
        ],
      ),
      body: storageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Error loading storage info: $err')),
        data: (info) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              // Summary card
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 44,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Sonara Storage',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              StorageInspectorService.formatBytes(
                                info.totalSizeBytes,
                              ),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Artwork Cache Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            'Artwork Thumbnail Cache',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _MetricRow(
                        label: 'Cache Size',
                        value: StorageInspectorService.formatBytes(
                          info.artworkCacheSizeBytes,
                        ),
                      ),
                      _MetricRow(
                        label: 'Cached Images',
                        value: '${info.artworkCachedFilesCount} files',
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isClearingCache
                              ? null
                              : _handleClearCache,
                          icon: _isClearingCache
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear Artwork Cache'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Database Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            'Database & Index',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _MetricRow(
                        label: 'Database Size',
                        value: StorageInspectorService.formatBytes(
                          info.databaseSizeBytes,
                        ),
                      ),
                      _MetricRow(
                        label: 'Tracks Indexed',
                        value: '${info.totalTracksCount}',
                      ),
                      _MetricRow(
                        label: 'Albums Indexed',
                        value: '${info.totalAlbumsCount}',
                      ),
                      _MetricRow(
                        label: 'Artists Indexed',
                        value: '${info.totalArtistsCount}',
                      ),
                      _MetricRow(
                        label: 'Playlists Stored',
                        value: '${info.totalPlaylistsCount}',
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isOptimizingDb ? null : _handleVacuumDb,
                          icon: _isOptimizingDb
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Optimize Database (VACUUM)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
