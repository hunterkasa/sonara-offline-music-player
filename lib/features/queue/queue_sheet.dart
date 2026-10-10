import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/artwork/artwork_widget.dart';

class QueueSheet extends ConsumerStatefulWidget {
  const QueueSheet({super.key});

  @override
  ConsumerState<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends ConsumerState<QueueSheet> {
  double _pullDistance = 0.0;
  bool _isDismissing = false;

  void _handleDismiss() {
    if (!_isDismissing && mounted) {
      _isDismissing = true;
      ref.read(hapticServiceProvider).light();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Drag handle & Header Row with ultra-responsive pull-down dismiss
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 0) {
                _pullDistance += details.primaryDelta!;
                if (_pullDistance > 20.0) {
                  _handleDismiss();
                }
              }
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 60.0) {
                _handleDismiss();
              }
              _pullDistance = 0.0;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag pill handle
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s,
                    bottom: AppSpacing.xs,
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2.5),
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
                    buildDefaultDragHandles: false,
                    itemExtent: 56.0,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final elevation = Tween<double>(
                            begin: 0,
                            end: 6,
                          ).evaluate(animation);
                          return Material(
                            elevation: elevation,
                            color: theme.colorScheme.surfaceContainerHigh,
                            shadowColor: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    onReorderItem: (oldIndex, newIndex) {
                      haptics.selection();
                      playback.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrent = index == currentIndex;

                      return Dismissible(
                        key: ValueKey('${track.trackKey}_$index'),
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
                        child: SizedBox(
                          height: 56.0,
                          child: ListTile(
                            dense: true,
                            key: ValueKey('tile_${track.trackKey}'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                              vertical: 0,
                            ),
                            leading: ArtworkWidget(
                              artworkKey: track.artworkKey,
                              filePath: track.path,
                              title: track.title,
                              size: 38,
                              borderRadius: 6.0,
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
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _formatDuration(
                                Duration(milliseconds: track.durationMs),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  size: 22,
                                ),
                              ),
                            ),
                            onTap: () {
                              haptics.selection();
                              playback.skipToQueueItem(index);
                            },
                          ),
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
