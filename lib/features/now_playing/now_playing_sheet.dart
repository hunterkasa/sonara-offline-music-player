import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';

class NowPlayingSheet extends ConsumerWidget {
  const NowPlayingSheet({super.key, required this.onCollapse});

  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final snapshot =
        snapshotAsync.value ??
        ref.read(playbackControllerProvider).currentSnapshot;

    final progressRatio = snapshot.duration.inMilliseconds > 0
        ? (snapshot.position.inMilliseconds / snapshot.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onCollapse();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            tooltip: 'Collapse',
            onPressed: onCollapse,
          ),
          title: Text(
            'NOW PLAYING',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More options',
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Center(
                    child: RepaintBoundary(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: AppRadii.artworkRadius,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 110,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                // Title, Artist, Favorite
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot.title.isEmpty
                                ? 'No track selected'
                                : snapshot.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            snapshot.artist.isEmpty
                                ? 'Sonara Audio'
                                : snapshot.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border_rounded),
                      iconSize: 28,
                      tooltip: 'Favorite',
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                // Seek Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: progressRatio,
                    onChanged: (val) {
                      final targetMs = (val * snapshot.duration.inMilliseconds)
                          .round();
                      ref
                          .read(playbackControllerProvider)
                          .seek(Duration(milliseconds: targetMs));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(snapshot.position),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _formatDuration(snapshot.duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                // Transport Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: snapshot.shuffleEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Shuffle',
                      onPressed: () {
                        ref
                            .read(playbackControllerProvider)
                            .setShuffle(!snapshot.shuffleEnabled);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 36,
                      tooltip: 'Previous',
                      onPressed: () {
                        ref.read(playbackControllerProvider).skipToPrevious();
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          snapshot.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                        iconSize: 42,
                        tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                        onPressed: () {
                          ref
                              .read(playbackControllerProvider)
                              .togglePlayPause();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 36,
                      tooltip: 'Next',
                      onPressed: () {
                        ref.read(playbackControllerProvider).skipToNext();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        snapshot.repeatMode == 1
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: snapshot.repeatMode > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Repeat',
                      onPressed: () {
                        final nextMode = (snapshot.repeatMode + 1) % 3;
                        ref
                            .read(playbackControllerProvider)
                            .setRepeatMode(nextMode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                // Secondary Row (lyrics, queue, timer, EQ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.lyrics_outlined),
                      tooltip: 'Lyrics',
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded),
                      tooltip: 'Queue',
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.timer_outlined),
                      tooltip: 'Sleep Timer',
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.equalizer_rounded),
                      tooltip: 'Equalizer',
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
