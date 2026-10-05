import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/m3u_service.dart';
import 'package:sonara/domain/services/playlist_service.dart';
import 'package:sonara/shared/sheets/track_context_sheet.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final int playlistId;

  String _formatTotalDuration(List<Track> tracks) {
    final totalMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final minutes = totalMs ~/ 60000;
    final seconds = (totalMs % 60000) ~/ 1000;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMinutes = minutes % 60;
      return '${hours}h ${remMinutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistAsync = ref.watch(playlistStreamProvider(playlistId));
    final tracksAsync = ref.watch(playlistTracksStreamProvider(playlistId));
    final playlistService = ref.read(playlistServiceProvider);
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);

    return playlistAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $err')),
      ),
      data: (playlist) {
        if (playlist == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Playlist not found')),
          );
        }

        final tracks = tracksAsync.value ?? [];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                backgroundColor: colorScheme.surface,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.file_upload_outlined),
                    tooltip: 'Export to M3U8',
                    onPressed: () async {
                      haptics.selection();
                      await _exportPlaylist(context, ref, playlist);
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      haptics.selection();
                      if (value == 'rename') {
                        await _showRenameDialog(context, ref, playlist);
                      } else if (value == 'duplicate') {
                        final newId = await playlistService.duplicatePlaylist(
                          playlist.id,
                        );
                        if (context.mounted && newId > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Playlist duplicated'),
                            ),
                          );
                        }
                      } else if (value == 'delete') {
                        final confirmed = await _showDeleteDialog(context);
                        if (confirmed == true && context.mounted) {
                          await playlistService.deletePlaylist(playlist.id);
                          if (context.mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${playlist.name}"'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename Playlist'),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate Playlist'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Playlist',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Hero(
                          tag: 'playlist_art_${playlist.id}',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: AppRadii.cardRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              playlist.isSmart
                                  ? Icons.auto_awesome_rounded
                                  : Icons.queue_music_rounded,
                              size: 56,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons & meta
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tracks.length} tracks • ${_formatTotalDuration(tracks)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: tracks.isNotEmpty
                                  ? () {
                                      haptics.selection();
                                      final keys = tracks
                                          .map((t) => t.trackKey)
                                          .toList();
                                      playback.playQueue(keys, initialIndex: 0);
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play All'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: tracks.isNotEmpty
                                  ? () {
                                      haptics.selection();
                                      final keys = tracks
                                          .map((t) => t.trackKey)
                                          .toList();
                                      playback.playQueue(keys, initialIndex: 0);
                                      playback.setShuffle(true);
                                    }
                                  : null,
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('Shuffle'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                ),
              ),

              // Track list with reordering
              if (tracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'This playlist is empty. Add songs from your library!',
                    ),
                  ),
                )
              else
                SliverReorderableList(
                  itemCount: tracks.length,
                  onReorderItem: (oldIndex, newIndex) {
                    haptics.light();
                    playlistService.reorderTracks(
                      playlist.id,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Dismissible(
                      key: ValueKey(
                        'playlist_${playlist.id}_${track.trackKey}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                        ),
                        color: Colors.redAccent,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        haptics.light();
                        playlistService.removeTrackFromPlaylist(
                          playlist.id,
                          track.trackKey,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Removed "${track.title}" from playlist',
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                playlistService.addTracksToPlaylist(
                                  playlist.id,
                                  [track.trackKey],
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: TrackTile(
                          track: track,
                          trackNumber: index + 1,
                          onTap: () {
                            haptics.selection();
                            final keys = tracks.map((t) => t.trackKey).toList();
                            playback.playQueue(keys, initialIndex: index);
                          },
                          onMore: () {
                            haptics.medium();
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (ctx) => TrackContextSheet(track: track),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPlaylist(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final m3uService = ref.read(m3uServiceProvider);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final exportedFile = await m3uService.exportPlaylistToFile(
        playlist.id,
        docDir.path,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${exportedFile.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final playlistService = ref.read(playlistServiceProvider);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != playlist.name) {
      await playlistService.renamePlaylist(playlist.id, newName);
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: const Text(
          'This will delete the playlist. Songs in your library will not be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
