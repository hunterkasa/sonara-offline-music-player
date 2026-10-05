import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/artwork/artwork_widget.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final queue = ref.watch(queueListProvider).value ?? const [];
    final snapshot =
        ref.watch(playbackSnapshotProvider).value ??
        ref.read(playbackControllerProvider).currentSnapshot;
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);

    final currentIndex = queue.indexWhere(
      (t) => t.trackKey == snapshot.currentTrackKey,
    );
    final currentTrack = currentIndex != -1 ? queue[currentIndex] : null;

    return SafeArea(
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.s,
              bottom: AppSpacing.xs,
            ),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAY QUEUE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${queue.length} ${queue.length == 1 ? 'track' : 'tracks'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all_rounded, size: 20),
                  label: const Text('Clear'),
                  onPressed: queue.isEmpty
                      ? null
                      : () {
                          haptics.medium();
                          playback.clearQueue();
                          Navigator.of(context).pop();
                        },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Now Playing Item
          if (currentTrack != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.xxs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NOW PLAYING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: ArtworkWidget(
                artworkKey: currentTrack.artworkKey,
                filePath: currentTrack.path,
                title: currentTrack.title,
                size: 44,
              ),
              title: Text(
                currentTrack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                snapshot.artist.isNotEmpty ? snapshot.artist : 'Sonara Audio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                snapshot.isPlaying
                    ? Icons.volume_up_rounded
                    : Icons.pause_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 1),
          ],

          // Up Next Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              AppSpacing.xxs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'UP NEXT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Reorderable Up Next List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Text(
                      'Queue is empty',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: queue.length,
                    padding: const EdgeInsets.only(bottom: AppSpacing.l),
                    onReorderItem: (oldIndex, newIndex) {
                      haptics.selection();
                      playback.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrent = index == currentIndex;

                      return Dismissible(
                        key: ValueKey(track.trackKey),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.l),
                          color: theme.colorScheme.errorContainer,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        onDismissed: (_) {
                          haptics.light();
                          playback.removeFromQueue(index);
                        },
                        child: ListTile(
                          key: ValueKey('tile_${track.trackKey}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                            vertical: 2,
                          ),
                          leading: ArtworkWidget(
                            artworkKey: track.artworkKey,
                            filePath: track.path,
                            title: track.title,
                            size: 40,
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            _formatDuration(
                              Duration(milliseconds: track.durationMs),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle_rounded),
                          ),
                          onTap: () {
                            haptics.selection();
                            playback.playTrack(track.trackKey);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
