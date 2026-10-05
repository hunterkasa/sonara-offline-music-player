import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/library_scanner.dart';
import 'package:sonara/domain/services/playlist_service.dart';
import 'package:sonara/shared/cards/media_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final db = ref.watch(databaseProvider);
    final scanProgress = ref.watch(libraryScannerProvider);
    final playback = ref.watch(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);
    final playlistsAsync = ref.watch(allPlaylistsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getGreeting(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Rescan Library',
            onPressed: () {
              haptics.light();
              ref
                  .read(libraryScannerProvider.notifier)
                  .scanLibrary(isFullScan: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              haptics.selection();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(libraryScannerProvider.notifier)
              .scanLibrary(isFullScan: true);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          children: [
            // Live scanning indicator
            if (scanProgress.isScanning)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        scanProgress.statusMessage ?? 'Scanning local music...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Access Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 3.0,
              children: [
                _buildQuickCard(
                  context,
                  icon: Icons.favorite_rounded,
                  title: 'Liked Songs',
                  color: Colors.redAccent,
                  onTap: () {
                    haptics.selection();
                    context.go('/library');
                  },
                ),
                _buildQuickCard(
                  context,
                  icon: Icons.shuffle_rounded,
                  title: 'Shuffle All',
                  color: Colors.deepPurpleAccent,
                  onTap: () async {
                    haptics.selection();
                    final tracks = await (db.select(
                      db.tracks,
                    )..orderBy([(t) => d.OrderingTerm.asc(t.titleSort)])).get();
                    if (tracks.isNotEmpty) {
                      final shuffled = List<Track>.from(tracks)..shuffle();
                      await playback.playTrack(shuffled.first.trackKey);
                    }
                  },
                ),
                _buildQuickCard(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Recently Added',
                  color: Colors.teal,
                  onTap: () {
                    haptics.selection();
                    context.go('/library');
                  },
                ),
                _buildQuickCard(
                  context,
                  icon: Icons.repeat_rounded,
                  title: 'On Repeat',
                  color: Colors.amber,
                  onTap: () {
                    haptics.selection();
                    context.go('/library');
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Jump back in (Albums Shelf)
            _buildShelfHeader(context, 'Jump Back In'),
            const SizedBox(height: AppSpacing.s),
            StreamBuilder<List<Album>>(
              stream:
                  (db.select(db.albums)
                        ..orderBy([(a) => d.OrderingTerm.desc(a.year)])
                        ..limit(10))
                      .watch(),
              builder: (context, snapshot) {
                final albums = snapshot.data ?? [];
                if (albums.isEmpty) {
                  return _buildEmptyShelfPlaceholder(
                    context,
                    message: 'Scan your library to see albums here',
                  );
                }

                return SizedBox(
                  height: 190.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return SizedBox(
                        width: 140.0,
                        child: MediaCard(
                          title: album.title,
                          subtitle: album.year != null ? '${album.year}' : null,
                          artworkKey: album.artworkKey,
                          onTap: () {
                            haptics.selection();
                            context.push('/album/${album.id}');
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.l),

            // On Repeat (Top Played Tracks)
            StreamBuilder<List<Track>>(
              stream: db.watchTopTracks(limit: 10),
              builder: (context, snapshot) {
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShelfHeader(context, 'On Repeat'),
                    const SizedBox(height: AppSpacing.s),
                    SizedBox(
                      height: 190.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return SizedBox(
                            width: 140.0,
                            child: MediaCard(
                              title: track.title,
                              subtitle: '${track.playCount} plays',
                              filePath: track.path,
                              onTap: () {
                                haptics.selection();
                                playback.playTrack(track.trackKey);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                );
              },
            ),

            // Your Top Artists (Circular Shelf)
            StreamBuilder<List<Artist>>(
              stream: db.watchTopArtists(limit: 10),
              builder: (context, snapshot) {
                final artists = snapshot.data ?? [];
                if (artists.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShelfHeader(context, 'Your Top Artists'),
                    const SizedBox(height: AppSpacing.s),
                    SizedBox(
                      height: 150.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: artists.length,
                        itemBuilder: (context, index) {
                          final artist = artists[index];
                          return SizedBox(
                            width: 110.0,
                            child: InkWell(
                              onTap: () {
                                haptics.selection();
                                context.push('/artist/${artist.id}');
                              },
                              borderRadius: BorderRadius.circular(55),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 40,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    artist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                );
              },
            ),

            // Recently Added (Tracks Shelf)
            StreamBuilder<List<Track>>(
              stream: db.watchRecentlyAddedTracks(limit: 10),
              builder: (context, snapshot) {
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShelfHeader(context, 'Recently Added'),
                    const SizedBox(height: AppSpacing.s),
                    SizedBox(
                      height: 190.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return SizedBox(
                            width: 140.0,
                            child: MediaCard(
                              title: track.title,
                              subtitle: 'Recently Added',
                              filePath: track.path,
                              onTap: () {
                                haptics.selection();
                                playback.playTrack(track.trackKey);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                );
              },
            ),

            // Made For You (Playlists Shelf)
            playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShelfHeader(context, 'Made For You'),
                    const SizedBox(height: AppSpacing.s),
                    SizedBox(
                      height: 150.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return SizedBox(
                            width: 130.0,
                            child: InkWell(
                              onTap: () {
                                haptics.selection();
                                context.push('/playlist/${playlist.id}');
                              },
                              borderRadius: AppRadii.cardRadius,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120.0,
                                    height: 100.0,
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: AppRadii.cardRadius,
                                    ),
                                    child: Icon(
                                      playlist.isSmart
                                          ? Icons.auto_awesome_rounded
                                          : Icons.queue_music_rounded,
                                      size: 40,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    playlist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmptyShelfPlaceholder(
    BuildContext context, {
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 120.0,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_rounded,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: AppRadii.cardRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
