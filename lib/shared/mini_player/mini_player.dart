import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/database_provider.dart';
import '../../domain/models/audio_settings.dart';
import '../../domain/services/audio_settings_service.dart';
import '../artwork/artwork_widget.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meta = ref.watch(
      playbackSnapshotProvider.select((s) {
        final snap =
            s.value ?? ref.read(playbackControllerProvider).currentSnapshot;
        return (
          trackKey: snap.currentTrackKey,
          title: snap.title,
          artist: snap.artist,
          isPlaying: snap.isPlaying,
        );
      }),
    );
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);
    final trackAsync = ref.watch(trackStreamProvider(meta.trackKey));
    final track = trackAsync.value;

    final audioSettings = ref.watch(audioSettingsProvider);
    final isOled =
        theme.scaffoldBackgroundColor == Colors.black ||
        audioSettings.nowPlayingSkin == NowPlayingSkin.minimalistOled;
    final isWhite = theme.brightness == Brightness.light && !isOled;

    return Semantics(
      label: 'Mini Player: ${meta.title} by ${meta.artist}',
      button: true,
      child: GestureDetector(
        onTap: () {
          haptics.light();
          onTap();
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -200) {
              haptics.selection();
              playback.skipToNext();
            } else if (details.primaryVelocity! > 200) {
              haptics.selection();
              playback.skipToPrevious();
            }
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -200) {
            haptics.light();
            onTap();
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: isOled
                ? const Color(0xFF0D0D0D)
                : (isWhite
                      ? Colors.white
                      : theme.colorScheme.surfaceContainerHigh),
            borderRadius: AppRadii.cardRadius,
            border: isOled
                ? Border.all(color: Colors.white24, width: 1.0)
                : (isWhite
                      ? Border.all(color: const Color(0xFFE0E0E0), width: 1.0)
                      : null),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isOled ? 0.4 : (isWhite ? 0.08 : 0.18),
                ),
                blurRadius: isWhite ? 10 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hairline progress bar isolated from parent rebuilds
              _MiniPlayerProgressBar(isOled: isOled, isWhite: isWhite),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    // Artwork thumbnail with RepaintBoundary
                    RepaintBoundary(
                      child: ArtworkWidget(
                        artworkKey: track?.artworkKey,
                        filePath: track?.path,
                        title: meta.title,
                        size: 44,
                        borderRadius: 8.0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    // Title & Artist
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.title.isEmpty
                                ? 'No track playing'
                                : meta.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta.artist.isEmpty ? 'Sonara Music' : meta.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Play / Pause button
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.all(8),
                      icon: Icon(
                        meta.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      iconSize: 30,
                      tooltip: meta.isPlaying ? 'Pause' : 'Play',
                      onPressed: () {
                        haptics.medium();
                        playback.togglePlayPause();
                      },
                    ),
                    // Skip to next button
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.all(8),
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 26,
                      tooltip: 'Next Track',
                      onPressed: () {
                        haptics.selection();
                        playback.skipToNext();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar({required this.isOled, required this.isWhite});

  final bool isOled;
  final bool isWhite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(
      playbackSnapshotProvider.select((s) {
        final snap =
            s.value ?? ref.read(playbackControllerProvider).currentSnapshot;
        if (snap.duration.inMilliseconds <= 0) return 0.0;
        return (snap.position.inMilliseconds / snap.duration.inMilliseconds)
            .clamp(0.0, 1.0);
      }),
    );

    return LinearProgressIndicator(
      value: progress,
      minHeight: 2.5,
      backgroundColor: isWhite ? const Color(0xFFF1F3F5) : Colors.transparent,
      valueColor: AlwaysStoppedAnimation<Color>(
        isOled ? Colors.white : theme.colorScheme.primary,
      ),
    );
  }
}
