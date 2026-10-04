import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final int albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

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

    return Scaffold(
      body: StreamBuilder<Album?>(
        stream: (db.select(
          db.albums,
        )..where((a) => a.id.equals(albumId))).watchSingleOrNull(),
        builder: (context, albumSnap) {
          if (!albumSnap.hasData || albumSnap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final album = albumSnap.data!;

          return StreamBuilder<List<Track>>(
            stream:
                (db.select(db.tracks)
                      ..where((t) => t.albumId.equals(albumId))
                      ..orderBy([
                        (t) => d.OrderingTerm.asc(t.discNo),
                        (t) => d.OrderingTerm.asc(t.trackNo),
                        (t) => d.OrderingTerm.asc(t.titleSort),
                      ]))
                    .watch(),
            builder: (context, tracksSnap) {
              final tracks = tracksSnap.data ?? [];

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.primaryContainer.withValues(
                                alpha: 0.8,
                              ),
                              colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 40.0,
                              bottom: 48.0,
                            ),
                            child: ArtworkWidget(
                              title: album.title,
                              artworkKey: album.artworkKey,
                              size: 160.0,
                              borderRadius: 16.0,
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
                            album.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${tracks.length} tracks • ${_formatTotalDuration(tracks)}${album.year != null ? ' • ${album.year}' : ''}',
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
                                      : () {
                                          playback.playTrack(
                                            tracks.first.trackKey,
                                          );
                                        },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play'),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: tracks.isEmpty
                                      ? null
                                      : () {
                                          final shuffled = List<Track>.from(
                                            tracks,
                                          )..shuffle();
                                          playback.playTrack(
                                            shuffled.first.trackKey,
                                          );
                                        },
                                  icon: const Icon(Icons.shuffle_rounded),
                                  label: const Text('Shuffle'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                  ),
                  if (tracks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No tracks found in this album'),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final track = tracks[index];
                        return TrackTile(
                          track: track,
                          trackNumber: index + 1,
                          onTap: () {
                            playback.playTrack(track.trackKey);
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
