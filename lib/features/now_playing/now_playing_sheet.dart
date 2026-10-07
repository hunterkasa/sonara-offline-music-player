import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../audio/sleep_timer.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/pitch_calculator.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/sources/palette_service.dart';
import '../../domain/models/audio_settings.dart';
import '../../domain/services/audio_settings_service.dart';
import '../../features/lyrics/lyrics_sheet.dart';
import '../../features/queue/queue_sheet.dart';
import '../../features/sleep_timer/sleep_timer_sheet.dart';
import '../../features/speed/speed_sheet.dart';
import '../../features/track_info/track_info_sheet.dart';
import '../../shared/artwork/artwork_widget.dart';
import '../../shared/sheets/track_context_sheet.dart';
import '../../shared/visualizer/audio_visualizer.dart';
import '../../shared/waveform/waveform_scrubber.dart';
import 'skins/minimalist_oled_skin.dart';
import 'skins/retro_cassette_skin.dart';
import 'skins/spinning_vinyl_skin.dart';

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
    final audioSettings = ref.watch(audioSettingsProvider);
    final visualizerMode = audioSettings.visualizerMode;

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
    final isMinimalistOled =
        audioSettings.nowPlayingSkin == NowPlayingSkin.minimalistOled;
    final effectiveAccent = isMinimalistOled ? Colors.white : dominantColor;

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
        decoration:
            audioSettings.nowPlayingSkin == NowPlayingSkin.minimalistOled
            ? const BoxDecoration(color: Colors.black)
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(
                      dominantColor.withValues(alpha: 0.35),
                      theme.scaffoldBackgroundColor,
                    ),
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
                icon: const Icon(Icons.style_outlined),
                tooltip: 'Player Skin',
                onPressed: () {
                  haptics.selection();
                  final nextSkin = switch (audioSettings.nowPlayingSkin) {
                    NowPlayingSkin.defaultModern =>
                      NowPlayingSkin.spinningVinyl,
                    NowPlayingSkin.spinningVinyl =>
                      NowPlayingSkin.retroCassette,
                    NowPlayingSkin.retroCassette =>
                      NowPlayingSkin.minimalistOled,
                    NowPlayingSkin.minimalistOled =>
                      NowPlayingSkin.defaultModern,
                  };
                  ref
                      .read(audioSettingsProvider.notifier)
                      .setNowPlayingSkin(nextSkin);
                  final skinName = switch (nextSkin) {
                    NowPlayingSkin.defaultModern => 'Default Modern',
                    NowPlayingSkin.spinningVinyl => 'Spinning Vinyl Turntable',
                    NowPlayingSkin.retroCassette => 'Retro 90s Cassette',
                    NowPlayingSkin.minimalistOled => 'Minimalist OLED',
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Skin: $skinName'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  visualizerMode == 'off'
                      ? Icons.graphic_eq_outlined
                      : Icons.graphic_eq_rounded,
                  color: visualizerMode != 'off'
                      ? theme.colorScheme.primary
                      : null,
                ),
                tooltip: 'Visualizer',
                onPressed: () {
                  haptics.selection();
                  final nextMode = switch (visualizerMode) {
                    'off' => 'spectrum',
                    'spectrum' => 'vuMeter',
                    'vuMeter' => 'fluidWave',
                    _ => 'off',
                  };
                  ref
                      .read(audioSettingsProvider.notifier)
                      .setVisualizerMode(nextMode);
                  final label = switch (nextMode) {
                    'spectrum' => 'Visualizer: Spectrum Analyzer',
                    'vuMeter' => 'Visualizer: Vintage VU Meters',
                    'fluidWave' => 'Visualizer: Fluid Harmonic Waves',
                    _ => 'Visualizer Disabled',
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(label),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.equalizer_rounded),
                tooltip: 'Equalizer',
                onPressed: () {
                  haptics.light();
                  context.push('/equalizer');
                },
              ),
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
                  // Artwork / Active Player Skin
                  Expanded(
                    flex: 5,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.06, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<String>(trackKey ?? snapshot.title),
                        child: switch (audioSettings.nowPlayingSkin) {
                          NowPlayingSkin.spinningVinyl => SpinningVinylSkin(
                            snapshot: snapshot,
                            artworkKey: track?.artworkKey,
                            filePath: track?.path,
                            title: track?.title ?? snapshot.title,
                          ),
                          NowPlayingSkin.retroCassette => RetroCassetteSkin(
                            snapshot: snapshot,
                          ),
                          NowPlayingSkin.minimalistOled => MinimalistOledSkin(
                            snapshot: snapshot,
                            artworkKey: track?.artworkKey,
                            filePath: track?.path,
                            title: track?.title ?? snapshot.title,
                          ),
                          NowPlayingSkin.defaultModern => Center(
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
                              onTap: () {
                                haptics.light();
                                if (visualizerMode != 'off') {
                                  final nextMode = switch (visualizerMode) {
                                    'spectrum' => 'vuMeter',
                                    'vuMeter' => 'fluidWave',
                                    _ => 'off',
                                  };
                                  ref
                                      .read(audioSettingsProvider.notifier)
                                      .setVisualizerMode(nextMode);
                                } else {
                                  playback.togglePlayPause();
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
                                      child: visualizerMode == 'off'
                                          ? ArtworkWidget(
                                              artworkKey: track?.artworkKey,
                                              filePath: track?.path,
                                              title:
                                                  track?.title ??
                                                  snapshot.title,
                                              size: double.infinity,
                                              borderRadius: 16.0,
                                            )
                                          : Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ArtworkWidget(
                                                  artworkKey: track?.artworkKey,
                                                  filePath: track?.path,
                                                  title:
                                                      track?.title ??
                                                      snapshot.title,
                                                  size: double.infinity,
                                                  borderRadius: 16.0,
                                                ),
                                                Container(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.82),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: AudioVisualizer(
                                                    isPlaying:
                                                        snapshot.isPlaying,
                                                    style:
                                                        switch (visualizerMode) {
                                                          'vuMeter' =>
                                                            VisualizerStyle
                                                                .vuMeter,
                                                          'fluidWave' =>
                                                            VisualizerStyle
                                                                .fluidWave,
                                                          _ =>
                                                            VisualizerStyle
                                                                .spectrum,
                                                        },
                                                    accentColor: dominantColor,
                                                    height: double.infinity,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 12,
                                                  right: 12,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black87,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: dominantColor
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      switch (visualizerMode) {
                                                        'vuMeter' =>
                                                          'VU METERS',
                                                        'fluidWave' =>
                                                          'FLUID WAVE',
                                                        _ => 'SPECTRUM',
                                                      },
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color:
                                                                dominantColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 10,
                                                            letterSpacing: 1.1,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Title, Artist, Favorite Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<String>(trackKey ?? snapshot.title),
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

                  // Waveform Scrubber
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: WaveformScrubber(
                      trackKey: trackKey ?? 'default_track',
                      position: snapshot.position,
                      duration: snapshot.duration,
                      accentColor: effectiveAccent,
                      height: 38,
                      onSeek: (pos) {
                        haptics.selection();
                        playback.seek(pos);
                      },
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Seek Bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: effectiveAccent,
                      inactiveTrackColor: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.25),
                      thumbColor: effectiveAccent,
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
                              ? (isMinimalistOled
                                    ? Colors.white
                                    : theme.colorScheme.primary)
                              : (isMinimalistOled
                                    ? Colors.white38
                                    : theme.colorScheme.onSurfaceVariant),
                        ),
                        tooltip: 'Shuffle',
                        onPressed: () {
                          haptics.selection();
                          playback.setShuffle(!snapshot.shuffleEnabled);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: isMinimalistOled ? Colors.white : null,
                        ),
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
                          color: isMinimalistOled
                              ? Colors.white
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            snapshot.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: isMinimalistOled
                                ? Colors.black
                                : theme.colorScheme.onPrimary,
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
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: isMinimalistOled ? Colors.white : null,
                        ),
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
                              ? (isMinimalistOled
                                    ? Colors.white
                                    : theme.colorScheme.primary)
                              : (isMinimalistOled
                                    ? Colors.white38
                                    : theme.colorScheme.onSurfaceVariant),
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
                        color: isMinimalistOled ? Colors.white70 : null,
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
                        color: isMinimalistOled ? Colors.white70 : null,
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
                              ? (isMinimalistOled
                                    ? Colors.white
                                    : theme.colorScheme.primary)
                              : (isMinimalistOled ? Colors.white70 : null),
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
                        icon:
                            (snapshot.speed != 1.0 ||
                                snapshot.pitchSemitones != 0)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (snapshot.pitchSemitones != 0)
                                    Text(
                                      PitchCalculator.formatKeyTranspose(
                                        snapshot.pitchSemitones,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMinimalistOled
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                        fontSize: 9,
                                      ),
                                    ),
                                  Text(
                                    '${snapshot.speed}x',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMinimalistOled
                                          ? Colors.white
                                          : theme.colorScheme.primary,
                                      fontSize: snapshot.pitchSemitones != 0
                                          ? 9
                                          : 12,
                                    ),
                                  ),
                                ],
                              )
                            : Icon(
                                Icons.speed_rounded,
                                color: isMinimalistOled ? Colors.white70 : null,
                              ),
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
                        color: isMinimalistOled ? Colors.white70 : null,
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
