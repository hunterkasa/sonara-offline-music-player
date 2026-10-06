import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
import '../../domain/services/duplicate_finder_service.dart';

final duplicatesProvider = FutureProvider.autoDispose<List<DuplicateCluster>>((
  ref,
) {
  final service = ref.watch(duplicateFinderServiceProvider);
  return service.findDuplicates();
});

class DuplicateFinderScreen extends ConsumerWidget {
  const DuplicateFinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final duplicatesAsync = ref.watch(duplicatesProvider);
    final haptics = ref.read(hapticServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Finder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Duplicates',
            onPressed: () {
              haptics.light();
              ref.invalidate(duplicatesProvider);
            },
          ),
        ],
      ),
      body: duplicatesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.m),
              Text('Scanning library for duplicate audio...'),
            ],
          ),
        ),
        error: (err, _) =>
            Center(child: Text('Error scanning duplicates: $err')),
        data: (clusters) {
          if (clusters.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'No Duplicates Found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your music library is clean and organized.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: clusters.length,
            itemBuilder: (context, index) {
              final cluster = clusters[index];
              return _ClusterCard(cluster: cluster);
            },
          );
        },
      ),
    );
  }
}

class _ClusterCard extends ConsumerWidget {
  const _ClusterCard({required this.cluster});

  final DuplicateCluster cluster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.read(duplicateFinderServiceProvider);
    final haptics = ref.read(hapticServiceProvider);

    final isExact = cluster.matchType == DuplicateMatchType.exactFile;
    final badgeLabel = isExact ? 'Exact File Duplicate' : 'Metadata Match';
    final badgeColor = isExact
        ? Colors.orangeAccent
        : theme.colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cluster.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            ...cluster.tracks.map((track) {
              final sizeMb = (track.sizeBytes / (1024 * 1024)).toStringAsFixed(
                2,
              );
              final format = track.path.split('.').last.toUpperCase();
              final kbps = track.bitrate != null
                  ? '${(track.bitrate! / 1000).round()} kbps'
                  : '';

              return Container(
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$format · $sizeMb MB $kbps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            track.path,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility_off_outlined),
                      tooltip: 'Hide from library',
                      onPressed: () async {
                        haptics.selection();
                        await service.hideTrack(track.trackKey);
                        ref.invalidate(duplicatesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Hidden "${track.title}" from library',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete track',
                      onPressed: () => _confirmDelete(context, ref, track),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Track track) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Duplicate Track?'),
        content: Text(
          'Remove "${track.title}" from your library? The file will also be deleted from device storage if possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final service = ref.read(duplicateFinderServiceProvider);
              await service.deleteTrack(track, deleteFile: true);
              ref.invalidate(duplicatesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${track.title}"')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
