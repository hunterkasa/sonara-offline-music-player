import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/daily_mix_service.dart';
import 'package:sonara/domain/services/track_radio_service.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';

class TodaysPickCard extends ConsumerWidget {
  const TodaysPickCard({super.key, required this.pick});

  final TodaysPick pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playback = ref.read(playbackControllerProvider);
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final snapshot = snapshotAsync.value ?? playback.currentSnapshot;
    final haptics = ref.read(hapticServiceProvider);
    final db = ref.read(databaseProvider);
    final radioService = ref.read(trackRadioServiceProvider);

    final isCurrentTrack = snapshot.currentTrackKey == pick.track.trackKey;
    final isPlaying = isCurrentTrack && snapshot.isPlaying;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.7),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () async {
            haptics.selection();
            if (isPlaying) {
              await playback.pause();
            } else {
              final keys = [
                pick.track.trackKey,
                ...pick.queue
                    .where((t) => t.trackKey != pick.track.trackKey)
                    .map((t) => t.trackKey),
              ];
              await playback.playQueue(keys, initialIndex: 0);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Playing Today's Pick: ${pick.track.title}"),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13.0,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            "TODAY'S PICK • ${pick.dateLabel.toUpperCase()}",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          pick.reason,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                // Main Spotlight Content Row
                Row(
                  children: [
                    // Artwork
                    Hero(
                      tag: 'todays_pick_art_${pick.track.trackKey}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ArtworkWidget(
                              artworkKey: pick.artworkKey,
                              filePath: pick.track.path,
                              title: pick.track.title,
                              size: 78.0,
                              borderRadius: 14.0,
                            ),
                            if (isPlaying)
                              Container(
                                width: 78.0,
                                height: 78.0,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 28.0,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),

                    // Song & Artist Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pick.track.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            pick.artistName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pick.albumTitle != null &&
                              pick.albumTitle!.isNotEmpty) ...[
                            const SizedBox(height: 2.0),
                            Text(
                              pick.albumTitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Big Play FAB Button
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.all(12.0),
                      ),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 30.0,
                      ),
                      onPressed: () async {
                        haptics.selection();
                        if (isPlaying) {
                          await playback.pause();
                        } else {
                          final keys = [
                            pick.track.trackKey,
                            ...pick.queue
                                .where((t) => t.trackKey != pick.track.trackKey)
                                .map((t) => t.trackKey),
                          ];
                          await playback.playQueue(keys, initialIndex: 0);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),

                // Quick actions footer
                Divider(
                  height: 16.0,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Start Radio button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: colorScheme.primary,
                      ),
                      icon: const Icon(Icons.radio_rounded, size: 18.0),
                      label: Text(
                        'Start Radio (${pick.queue.length} songs)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        haptics.selection();
                        await radioService.startRadio(pick.track);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Started Radio for "${pick.track.title}"',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),

                    // Like button
                    IconButton(
                      icon: Icon(
                        pick.track.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: pick.track.isFavorite
                            ? Colors.redAccent
                            : colorScheme.onSurfaceVariant,
                        size: 20.0,
                      ),
                      tooltip: pick.track.isFavorite ? 'Unlike' : 'Like',
                      onPressed: () async {
                        haptics.selection();
                        await db.toggleFavorite(pick.track.trackKey);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
