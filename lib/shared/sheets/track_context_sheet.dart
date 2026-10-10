import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../domain/services/playlist_service.dart';
import '../../domain/services/track_radio_service.dart';
import '../../features/lyrics/lyrics_editor_sheet.dart';
import '../../features/playlist/add_to_playlist_sheet.dart';
import '../../features/tag_editor/tag_editor_sheet.dart';
import '../../features/track_info/track_info_sheet.dart';
import '../artwork/artwork_widget.dart';
import 'song_cover_picker_sheet.dart';

class TrackContextSheet extends ConsumerWidget {
  const TrackContextSheet({super.key, required this.track, this.playlistId});

  final Track track;
  final int? playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.s,
              bottom: AppSpacing.xs,
            ),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header with Artwork and Title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                ArtworkWidget(
                  artworkKey: track.artworkKey,
                  filePath: track.path,
                  title: track.title,
                  size: 48,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FutureBuilder<String?>(
                        future: db.getArtistName(track.artistId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.radio_rounded, color: Colors.amber),
            title: const Text('Start Track Radio'),
            subtitle: const Text('Queue similar genres, era & artist tracks'),
            onTap: () async {
              haptics.medium();
              Navigator.of(context).pop();
              final radioService = ref.read(trackRadioServiceProvider);
              final radioQueue = await radioService.startRadio(track);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Started Radio for "${track.title}" (${radioQueue.length} tracks)',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play_rounded),
            title: const Text('Play Next'),
            onTap: () {
              haptics.selection();
              playback.playNext(track.trackKey);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing next: ${track.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: const Text('Add to Queue'),
            onTap: () {
              haptics.selection();
              playback.addToQueue(track.trackKey);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added to queue: ${track.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: const Text('Add to Playlist'),
            onTap: () {
              haptics.selection();
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    AddToPlaylistSheet(trackKeys: [track.trackKey]),
              );
            },
          ),
          if (playlistId != null && playlistId! > 0)
            ListTile(
              leading: const Icon(
                Icons.playlist_remove_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Remove from Playlist',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                haptics.light();
                Navigator.of(context).pop();
                final playlistService = ref.read(playlistServiceProvider);
                await playlistService.removeTrackFromPlaylist(
                  playlistId!,
                  track.trackKey,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "${track.title}" from playlist'),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          playlistService.addTracksToPlaylist(playlistId!, [
                            track.trackKey,
                          ]);
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          StreamBuilder<Track?>(
            stream: db.watchTrack(track.trackKey),
            initialData: track,
            builder: (context, snapshot) {
              final isFav = snapshot.data?.isFavorite ?? track.isFavorite;
              return ListTile(
                leading: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  isFav ? 'Remove from Favorites' : 'Add to Favorites',
                ),
                onTap: () async {
                  haptics.selection();
                  await db.toggleFavorite(track.trackKey);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
          if (track.albumId != null)
            ListTile(
              leading: const Icon(Icons.album_rounded),
              title: const Text('Go to Album'),
              onTap: () {
                haptics.selection();
                Navigator.of(context).pop();
                context.push('/album/${track.albumId}');
              },
            ),
          if (track.artistId != null)
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Go to Artist'),
              onTap: () {
                haptics.selection();
                Navigator.of(context).pop();
                context.push('/artist/${track.artistId}');
              },
            ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Change Song Artwork'),
            subtitle: const Text('Custom photo or placeholder presets'),
            onTap: () {
              haptics.selection();
              Navigator.of(context).pop();
              SongCoverPickerSheet.show(context, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text('Edit Tags & Artwork'),
            onTap: () {
              haptics.selection();
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => TagEditorSheet(track: track),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lyrics_rounded),
            title: const Text('Edit Lyrics (LRC Studio)'),
            onTap: () {
              haptics.selection();
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LyricsEditorSheet(track: track),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.content_cut_rounded,
              color: Colors.tealAccent,
            ),
            title: const Text('Trim / Ringtone Studio'),
            subtitle: const Text(
              'Cut audio clip, set ringtone or notification',
            ),
            onTap: () {
              haptics.selection();
              Navigator.of(context).pop();
              context.push('/cutter?trackKey=${track.trackKey}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Track Details'),
            onTap: () {
              haptics.selection();
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => TrackInfoSheet(trackKey: track.trackKey),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ),
    );
  }
}
