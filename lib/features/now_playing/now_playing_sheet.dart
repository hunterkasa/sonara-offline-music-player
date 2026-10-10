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
import '../../shared/sheets/song_cover_picker_sheet.dart';
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

    final paletteAsync = ref.watch(paletteForTrackProvider(trackKey ?? ''));
    final dominantColor =
        paletteAsync.value?.primary ??
        (snapshot.title.isNotEmpty
            ? PaletteService.fromSeed(snapshot.title.hashCode).primary
            : const Color(0xFF6200EE));
    final isMinimalistOled =
        audioSettings.nowPlayingSkin == NowPlayingSkin.minimalistOled;
    final isBlackBg =
        isMinimalistOled || theme.scaffoldBackgroundColor == Colors.black;
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
              _NowPlayingToggleButton(
                isActive: visualizerMode != 'off',
                isBlackBg: isBlackBg,
                icon: visualizerMode == 'off'
                    ? Icons.graphic_eq_outlined
                    : Icons.graphic_eq_rounded,
                tooltip: 'Visualizer',
                showActiveDot: false,
                size: 40,
                iconSize: 22,
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
              _NowPlayingToggleButton(
                isActive: audioSettings.equalizerEnabled,
                isBlackBg: isBlackBg,
                icon: Icons.equalizer_rounded,
                tooltip: 'Equalizer',
                showActiveDot: false,
                size: 40,
                iconSize: 22,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 600;

                final artworkWidget = AnimatedSwitcher(
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
                          onLongPress: () {
                            if (track != null) {
                              haptics.medium();
                              SongCoverPickerSheet.show(context, track);
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
                                          title: track?.title ?? snapshot.title,
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
                                              color: Colors.black.withValues(
                                                alpha: 0.82,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              alignment: Alignment.center,
                                              child: AudioVisualizer(
                                                isPlaying: snapshot.isPlaying,
                                                position: snapshot.position,
                                                duration: snapshot.duration,
                                                speed: snapshot.speed,
                                                trackKey:
                                                    snapshot.currentTrackKey,
                                                bandGains:
                                                    audioSettings.bandGains,
                                                bassBoost:
                                                    audioSettings.bassBoost,
                                                style: switch (visualizerMode) {
                                                  'vuMeter' =>
                                                    VisualizerStyle.vuMeter,
                                                  'fluidWave' =>
                                                    VisualizerStyle.fluidWave,
                                                  _ => VisualizerStyle.spectrum,
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
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: dominantColor
                                                        .withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  switch (visualizerMode) {
                                                    'vuMeter' => 'VU METERS',
                                                    'fluidWave' => 'FLUID WAVE',
                                                    _ => 'SPECTRUM',
                                                  },
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: dominantColor,
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
                );

                final content = <Widget>[
                  if (isCompact)
                    SizedBox(
                      height: (constraints.maxHeight * 0.38).clamp(
                        160.0,
                        260.0,
                      ),
                      child: artworkWidget,
                    )
                  else
                    Expanded(flex: 5, child: artworkWidget),
                  SizedBox(height: isCompact ? AppSpacing.s : AppSpacing.m),

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
                      _NowPlayingToggleButton(
                        isActive: isFav,
                        isBlackBg: isBlackBg,
                        icon: isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        customActiveColor: const Color(0xFFFF3366),
                        customInactiveColor: isBlackBg
                            ? Colors.white60
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                        showActiveDot: false,
                        size: 44,
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
                      _NowPlayingToggleButton(
                        isActive: snapshot.shuffleEnabled,
                        isBlackBg: isBlackBg,
                        icon: Icons.shuffle_rounded,
                        tooltip: 'Shuffle',
                        onPressed: () {
                          haptics.selection();
                          playback.setShuffle(!snapshot.shuffleEnabled);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: isBlackBg
                              ? Colors.white
                              : theme.colorScheme.onSurface,
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
                          color: isBlackBg
                              ? Colors.white
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            snapshot.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: isBlackBg
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
                          color: isBlackBg
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                        iconSize: 36,
                        tooltip: 'Next',
                        onPressed: () {
                          haptics.selection();
                          playback.skipToNext();
                        },
                      ),
                      _NowPlayingToggleButton(
                        isActive: snapshot.repeatMode > 0,
                        isBlackBg: isBlackBg,
                        icon: snapshot.repeatMode == 2
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
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
                        color: isBlackBg
                            ? Colors.white70
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
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
                        color: isBlackBg
                            ? Colors.white70
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
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
                      _NowPlayingToggleButton(
                        isActive: timerState.isActive,
                        isBlackBg: isBlackBg,
                        icon: timerState.isActive
                            ? Icons.timer_rounded
                            : Icons.timer_outlined,
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
                      _NowPlayingToggleButton(
                        isActive:
                            snapshot.speed != 1.0 ||
                            snapshot.pitchSemitones != 0,
                        isBlackBg: isBlackBg,
                        icon: Icons.speed_rounded,
                        tooltip: 'Playback Speed',
                        customChild:
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
                                        color: isBlackBg
                                            ? const Color(0xFF00E5FF)
                                            : theme.colorScheme.primary,
                                        fontSize: 9,
                                      ),
                                    ),
                                  Text(
                                    '${snapshot.speed}x',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isBlackBg
                                          ? const Color(0xFF00E5FF)
                                          : theme.colorScheme.primary,
                                      fontSize: snapshot.pitchSemitones != 0
                                          ? 9
                                          : 12,
                                    ),
                                  ),
                                ],
                              )
                            : null,
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
                        color: isBlackBg
                            ? Colors.white70
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
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
                ];

                if (isCompact) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: content,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Column(children: content),
                );
              },
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

class _NowPlayingToggleButton extends StatelessWidget {
  const _NowPlayingToggleButton({
    required this.isActive,
    required this.isBlackBg,
    required this.onPressed,
    required this.tooltip,
    this.icon,
    this.customChild,
    this.customActiveColor,
    this.customInactiveColor,
    this.showActiveDot = true,
    this.size = 48.0,
    this.iconSize = 24.0,
  });

  final bool isActive;
  final bool isBlackBg;
  final VoidCallback? onPressed;
  final String tooltip;
  final IconData? icon;
  final Widget? customChild;
  final Color? customActiveColor;
  final Color? customInactiveColor;
  final bool showActiveDot;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Active color: high-contrast, vibrant, punchy in all themes
    final activeColor =
        customActiveColor ??
        (isBlackBg
            ? const Color(0xFF00E5FF) // Electric cyan on pure black OLED/AMOLED
            : (isDark
                  ? (theme.colorScheme.primary.computeLuminance() < 0.2
                        ? const Color(0xFF64B5F6)
                        : theme.colorScheme.primary)
                  : theme.colorScheme.primary));

    // Inactive color: muted and distinctly low-emphasis
    final inactiveColor =
        customInactiveColor ??
        (isBlackBg
            ? Colors.white38
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45));

    final currentColor = isActive ? activeColor : inactiveColor;
    final currentBg = isActive
        ? activeColor.withValues(
            alpha: isBlackBg ? 0.22 : (isDark ? 0.20 : 0.14),
          )
        : Colors.transparent;

    return Semantics(
      selected: isActive,
      label: tooltip,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: currentBg,
          shape: BoxShape.circle,
          border: isActive
              ? Border.all(
                  color: activeColor.withValues(alpha: 0.45),
                  width: 1.2,
                )
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: size, minHeight: size),
              icon:
                  customChild ??
                  Icon(icon, color: currentColor, size: iconSize),
              tooltip: tooltip,
              onPressed: onPressed,
            ),
            if (showActiveDot && isActive)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.6),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
