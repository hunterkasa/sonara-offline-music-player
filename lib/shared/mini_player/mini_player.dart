import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';

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

    final progressRatio = snapshot.duration.inMilliseconds > 0
        ? (snapshot.position.inMilliseconds / snapshot.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: 'Mini Player: ${snapshot.title} by ${snapshot.artist}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: AppRadii.cardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Hairline progress bar
              LinearProgressIndicator(
                value: progressRatio,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  child: Row(
                    children: [
                      // Artwork thumbnail with RepaintBoundary per coding standard
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: theme.colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.music_note,
                              color: theme.colorScheme.onSecondaryContainer,
                              size: 24,
                            ),
                          ),
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
                        icon: Icon(
                          snapshot.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        iconSize: 30,
                        tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                        onPressed: () {
                          ref
                              .read(playbackControllerProvider)
                              .togglePlayPause();
                        },
                      ),
                      // Skip to next button
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 26,
                        tooltip: 'Next Track',
                        onPressed: () {
                          ref.read(playbackControllerProvider).skipToNext();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
