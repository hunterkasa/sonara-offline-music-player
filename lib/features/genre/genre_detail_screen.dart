import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

class GenreDetailScreen extends ConsumerWidget {
  final int genreId;

  const GenreDetailScreen({super.key, required this.genreId});

  String _formatTotalDuration(List<Track> tracks) {
    final totalMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final totalMinutes = (totalMs / 60000).floor();
    if (totalMinutes >= 60) {
      final hours = (totalMinutes / 60).floor();
      final minutes = totalMinutes % 60;
      return '$hours hr $minutes min';
    }
    return '$totalMinutes min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playback = ref.watch(playbackControllerProvider);
    final haptics = ref.watch(hapticServiceProvider);

    return Scaffold(
      body: StreamBuilder<Genre?>(
        stream: db.watchGenre(genreId),
        builder: (context, genreSnap) {
          if (!genreSnap.hasData || genreSnap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final genre = genreSnap.data!;

          return StreamBuilder<List<Track>>(
            stream: db.watchTracksForGenre(genreId),
            builder: (context, tracksSnap) {
              final tracks = tracksSnap.data ?? [];

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        genre.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.tertiaryContainer.withValues(
                                alpha: 0.85,
                              ),
                              colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 24.0,
                              bottom: 48.0,
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.surfaceContainerHighest,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 52,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'} • ${_formatTotalDuration(tracks)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: tracks.isEmpty
                                      ? null
                                      : () async {
                                          haptics.selection();
                                          final keys = tracks
                                              .map((t) => t.trackKey)
                                              .toList();
                                          await playback.playQueue(
                                            keys,
                                            initialIndex: 0,
                                          );
                                        },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play All'),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: tracks.isEmpty
                                      ? null
                                      : () async {
                                          haptics.selection();
                                          final keys = tracks
                                              .map((t) => t.trackKey)
                                              .toList();
                                          await playback.playQueue(
                                            keys,
                                            initialIndex: 0,
                                            shuffle: true,
                                          );
                                        },
                                  icon: const Icon(Icons.shuffle_rounded),
                                  label: const Text('Shuffle'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tracks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No tracks in this genre',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final track = tracks[index];
                        return TrackTile(
                          track: track,
                          onTap: () {
                            haptics.selection();
                            final keys = tracks.map((t) => t.trackKey).toList();
                            playback.playQueue(keys, initialIndex: index);
                          },
                        );
                      }, childCount: tracks.length),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96.0)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
