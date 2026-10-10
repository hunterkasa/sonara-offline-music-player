import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/playlist/add_to_playlist_sheet.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

class FolderDetailScreen extends ConsumerWidget {
  final String folderPath;

  const FolderDetailScreen({super.key, required this.folderPath});

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

  String _getFolderDisplayName() {
    if (folderPath.isEmpty || folderPath == 'Root') return 'Root Folder';
    final base = p.basename(folderPath);
    return base.isNotEmpty ? base : folderPath;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playback = ref.watch(playbackControllerProvider);
    final haptics = ref.watch(hapticServiceProvider);
    final displayName = _getFolderDisplayName();

    return StreamBuilder<List<Track>>(
      stream: db.watchTracksForFolder(folderPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tracks = snapshot.data ?? [];
        final trackKeys = tracks.map((t) => t.trackKey).toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240.0,
                pinned: true,
                actions: [
                  if (tracks.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.playlist_add_rounded),
                      tooltip: 'Add All to Playlist',
                      onPressed: () {
                        haptics.selection();
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) =>
                              AddToPlaylistSheet(trackKeys: trackKeys),
                        );
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    displayName,
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
                          colorScheme.tertiaryContainer.withValues(alpha: 0.85),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 48.0),
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
                            Icons.folder_rounded,
                            size: 52,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Header Details & Play/Shuffle Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (folderPath.isNotEmpty && folderPath != 'Root')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  folderPath,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                      await playback.playQueue(
                                        trackKeys,
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
                                      await playback.playQueue(
                                        trackKeys,
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

              // Track List or Empty State
              if (tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No songs found in this folder',
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
                        playback.playQueue(trackKeys, initialIndex: index);
                      },
                    );
                  }, childCount: tracks.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 96.0)),
            ],
          ),
        );
      },
    );
  }
}
