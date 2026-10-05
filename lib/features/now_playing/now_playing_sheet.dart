import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../audio/sleep_timer.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/sources/palette_service.dart';
import '../../features/lyrics/lyrics_sheet.dart';
import '../../features/queue/queue_sheet.dart';
import '../../features/sleep_timer/sleep_timer_sheet.dart';
import '../../features/speed/speed_sheet.dart';
import '../../features/track_info/track_info_sheet.dart';
import '../../shared/artwork/artwork_widget.dart';
import '../../shared/sheets/track_context_sheet.dart';

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
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);
    final timerState = ref.watch(sleepTimerProvider);
    final db = ref.watch(databaseProvider);

    final trackKey = snapshot.currentTrackKey;
    final trackAsync = ref.watch(trackStreamProvider(trackKey));
    final track = trackAsync.value;
    final isFav = track?.isFavorite ?? false;

    final progressRatio = snapshot.duration.inMilliseconds > 0
        ? (snapshot.position.inMilliseconds / snapshot.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    final seed = snapshot.title.isNotEmpty
        ? snapshot.title.hashCode
        : 0xFF6200EE;
    final dominantColor = PaletteService.fromSeed(seed).primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onCollapse();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dominantColor.withValues(alpha: 0.35),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              tooltip: 'Collapse',
              onPressed: () {
                haptics.light();
                onCollapse();
              },
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
                onPressed: () async {
                  if (trackKey != null) {
                    final currentTrack = await db.getTrackByKey(trackKey);
                    if (currentTrack != null && context.mounted) {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (context) =>
                            TrackContextSheet(track: currentTrack),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  // Artwork with Scale Animation and Swipe Gestures
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < -200) {
                              haptics.selection();
                              unawaited(playback.skipToNext());
                            } else if (details.primaryVelocity! > 200) {
                              haptics.selection();
                              unawaited(playback.skipToPrevious());
                            }
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! > 200) {
                            haptics.light();
                            onCollapse();
                          }
                        },
                        child: AnimatedScale(
                          scale: snapshot.isPlaying ? 1.0 : 0.88,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: RepaintBoundary(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ArtworkWidget(
                                  artworkKey: track?.artworkKey,
                                  filePath: track?.path,
                                  title: track?.title ?? snapshot.title,
                                  size: double.infinity,
                                  borderRadius: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Title, Artist, Favorite Row
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
                      // Favorite Toggle
                      IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? theme.colorScheme.primary : null,
                        ),
                        iconSize: 28,
                        tooltip: isFav
                            ? 'Remove from Favorites'
                            : 'Add to Favorites',
                        onPressed: trackKey != null
                            ? () {
                                haptics.selection();
                                unawaited(db.toggleFavorite(trackKey));
                              }
                            : null,
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
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.25),
                      thumbColor: theme.colorScheme.primary,
                    ),
                    child: Slider(
                      value: progressRatio,
                      onChanged: (val) {
                        final targetMs =
                            (val * snapshot.duration.inMilliseconds).round();
                        playback.seek(Duration(milliseconds: targetMs));
                      },
                      onChangeEnd: (val) {
                        haptics.light();
                      },
                    ),
                  ),

                  // Elapsed & Remaining time + Quality badge
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
                        if (track != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _computeBadgeText(track),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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

                  // Transport Controls Row
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
                          haptics.selection();
                          playback.setShuffle(!snapshot.shuffleEnabled);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 36,
                        tooltip: 'Previous',
                        onPressed: () {
                          haptics.selection();
                          playback.skipToPrevious();
                        },
                      ),
                      Container(
                        width: 64,
                        height: 64,
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
                          iconSize: 36,
                          tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                          onPressed: () {
                            haptics.medium();
                            playback.togglePlayPause();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 36,
                        tooltip: 'Next',
                        onPressed: () {
                          haptics.selection();
                          playback.skipToNext();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          snapshot.repeatMode == 2
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: snapshot.repeatMode > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Repeat',
                        onPressed: () {
                          haptics.selection();
                          final nextMode = (snapshot.repeatMode + 1) % 3;
                          playback.setRepeatMode(nextMode);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Secondary Controls Row (Lyrics, Queue, Sleep Timer, Speed, Info)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lyrics_outlined),
                        tooltip: 'Lyrics',
                        onPressed: () async {
                          haptics.light();
                          if (context.mounted) {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => LyricsSheet(track: track),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded),
                        tooltip: 'Queue',
                        onPressed: () {
                          haptics.light();
                          unawaited(
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => const QueueSheet(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          timerState.isActive
                              ? Icons.timer_rounded
                              : Icons.timer_outlined,
                          color: timerState.isActive
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        tooltip: 'Sleep Timer',
                        onPressed: () {
                          haptics.light();
                          unawaited(
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => const SleepTimerSheet(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: snapshot.speed != 1.0
                            ? Text(
                                '${snapshot.speed}x',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              )
                            : const Icon(Icons.speed_rounded),
                        tooltip: 'Playback Speed',
                        onPressed: () {
                          haptics.light();
                          unawaited(
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => const SpeedSheet(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded),
                        tooltip: 'Track Info',
                        onPressed: () {
                          haptics.light();
                          if (trackKey != null) {
                            unawaited(
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) =>
                                    TrackInfoSheet(trackKey: trackKey),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _computeBadgeText(Track track) {
    final ext = track.path.split('.').last.toUpperCase();
    if (ext == 'FLAC' || ext == 'WAV') return 'LOSSLESS $ext';
    if (track.bitrate != null) {
      final kbps = (track.bitrate! / 1000).round();
      return '$ext · $kbps kbps';
    }
    return ext;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
