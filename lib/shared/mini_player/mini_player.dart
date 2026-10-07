import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
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
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final snapshot =
        snapshotAsync.value ??
        ref.read(playbackControllerProvider).currentSnapshot;
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);
    final db = ref.watch(databaseProvider);

    final progressRatio = snapshot.duration.inMilliseconds > 0
        ? (snapshot.position.inMilliseconds / snapshot.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    final audioSettings = ref.watch(audioSettingsProvider);
    final isOled =
        theme.scaffoldBackgroundColor == Colors.black ||
        audioSettings.nowPlayingSkin == NowPlayingSkin.minimalistOled;

    return Semantics(
      label: 'Mini Player: ${snapshot.title} by ${snapshot.artist}',
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
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: AppRadii.cardRadius,
            border: isOled
                ? Border.all(color: Colors.white24, width: 1.0)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isOled ? 0.4 : 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hairline progress bar
              LinearProgressIndicator(
                value: progressRatio,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOled ? Colors.white : theme.colorScheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    // Artwork thumbnail with RepaintBoundary
                    RepaintBoundary(
                      child: snapshot.currentTrackKey != null
                          ? FutureBuilder<Track?>(
                              future: db.getTrackByKey(
                                snapshot.currentTrackKey!,
                              ),
                              builder: (context, trackSnap) {
                                final track = trackSnap.data;
                                return ArtworkWidget(
                                  artworkKey: track?.artworkKey,
                                  filePath: track?.path,
                                  title: snapshot.title,
                                  size: 44,
                                  borderRadius: 8.0,
                                );
                              },
                            )
                          : ArtworkWidget(
                              title: snapshot.title,
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
                            snapshot.title.isEmpty
                                ? 'No track playing'
                                : snapshot.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            snapshot.artist.isEmpty
                                ? 'Sonara Music'
                                : snapshot.artist,
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
                        snapshot.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      iconSize: 30,
                      tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
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
