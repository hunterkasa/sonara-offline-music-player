import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';
import 'package:sonara/shared/cards/media_card.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final int artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playback = ref.watch(playbackControllerProvider);

    return Scaffold(
      body: StreamBuilder<Artist?>(
        stream: (db.select(
          db.artists,
        )..where((a) => a.id.equals(artistId))).watchSingleOrNull(),
        builder: (context, artistSnap) {
          if (!artistSnap.hasData || artistSnap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final artist = artistSnap.data!;

          return StreamBuilder<List<Track>>(
            stream:
                (db.select(db.tracks)
                      ..where((t) => t.artistId.equals(artistId))
                      ..orderBy([
                        (t) => d.OrderingTerm.desc(t.playCount),
                        (t) => d.OrderingTerm.asc(t.titleSort),
                      ]))
                    .watch(),
            builder: (context, tracksSnap) {
              final tracks = tracksSnap.data ?? [];

              return StreamBuilder<List<Album>>(
                stream:
                    (db.select(db.albums)
                          ..where((a) => a.albumArtistId.equals(artistId))
                          ..orderBy([(a) => d.OrderingTerm.desc(a.year)]))
                        .watch(),
                builder: (context, albumsSnap) {
                  final albums = albumsSnap.data ?? [];

                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 260.0,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            artist.name,
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
                                  colorScheme.secondaryContainer.withValues(
                                    alpha: 0.8,
                                  ),
                                  colorScheme.surface,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 36.0,
                                  bottom: 44.0,
                                ),
                                child: ArtworkWidget(
                                  title: artist.name,
                                  artworkKey: artist.artworkKey,
                                  size: 140.0,
                                  isCircular: true,
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
                                artist.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '${tracks.length} songs • ${albums.length} albums',
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
                                              playback.playQueue(
                                                tracks
                                                    .map((t) => t.trackKey)
                                                    .toList(),
                                                initialIndex: 0,
                                              );
                                            },
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
                                      label: const Text('Play'),
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: tracks.isEmpty
                                          ? null
                                          : () {
                                              playback.playQueue(
                                                tracks
                                                    .map((t) => t.trackKey)
                                                    .toList(),
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
                      if (albums.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              16.0,
                              16.0,
                              8.0,
                            ),
                            child: Text(
                              'Albums',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 190.0,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              itemCount: albums.length,
                              itemBuilder: (context, index) {
                                final album = albums[index];
                                return SizedBox(
                                  width: 140.0,
                                  child: MediaCard(
                                    title: album.title,
                                    subtitle: album.year != null
                                        ? '${album.year}'
                                        : null,
                                    artworkKey: album.artworkKey,
                                    onTap: () {
                                      context.push('/album/${album.id}');
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            20.0,
                            16.0,
                            8.0,
                          ),
                          child: Text(
                            'Songs',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (tracks.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('No songs found for this artist'),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final track = tracks[index];
                            return TrackTile(
                              track: track,
                              onTap: () {
                                playback.playQueue(
                                  tracks.map((t) => t.trackKey).toList(),
                                  initialIndex: index,
                                );
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
          );
        },
      ),
    );
  }
}
