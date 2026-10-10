import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/daily_mix_service.dart';
import 'package:sonara/domain/services/m3u_service.dart';
import 'package:sonara/domain/services/playlist_service.dart';
import 'package:sonara/features/playlist/playlist_cover_picker_sheet.dart';
import 'package:sonara/features/playlist/playlist_track_picker_sheet.dart';
import 'package:sonara/shared/artwork/playlist_artwork_widget.dart';
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

  void _openTrackPicker(
    BuildContext context,
    int playlistId,
    List<Track> currentTracks,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlaylistTrackPickerSheet(
        playlistId: playlistId,
        currentTrackKeys: currentTracks.map((t) => t.trackKey).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLikedSongs = playlistId == -1;
    final isDailyMix = playlistId <= -101 && playlistId >= -110;
    final mixIndex = isDailyMix ? ((-playlistId) - 101) : 0;
    final mixGradient = isDailyMix
        ? DailyMixService.mixGradients[mixIndex %
              DailyMixService.mixGradients.length]
        : null;

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
        if (playlist == null && !isLikedSongs && !isDailyMix) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Playlist not found')),
          );
        }

        final title = isLikedSongs
            ? 'Liked Songs'
            : (playlist?.name ?? 'Playlist');
        final isSmart =
            isLikedSongs || isDailyMix || (playlist?.isSmart ?? false);
        final tracks = tracksAsync.value ?? [];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                stretch: true,
                backgroundColor: colorScheme.surface,
                actions: [
                  if (!isSmart)
                    IconButton(
                      icon: const Icon(Icons.playlist_add_rounded),
                      tooltip: 'Add / Remove Songs',
                      onPressed: () {
                        haptics.selection();
                        _openTrackPicker(context, playlistId, tracks);
                      },
                    ),
                  if (!isLikedSongs &&
                      !isDailyMix &&
                      playlist != null &&
                      playlist.id > 0) ...[
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
                        if (value == 'change_cover') {
                          await PlaylistCoverPickerSheet.show(
                            context,
                            playlist,
                          );
                        } else if (value == 'rename') {
                          await _showRenameDialog(context, ref, playlist);
                        } else if (value == 'duplicate') {
                          final newId = await playlistService.duplicatePlaylist(
                            playlist.id,
                          );
                          if (context.mounted && newId > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Playlist duplicated'),
                                behavior: SnackBarBehavior.floating,
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
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'change_cover',
                          child: Row(
                            children: [
                              Icon(Icons.image_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Change Cover'),
                            ],
                          ),
                        ),
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
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  title: Text(
                    title,
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
                              isLikedSongs
                                  ? Colors.purple.shade900.withValues(
                                      alpha: 0.6,
                                    )
                                  : isDailyMix
                                  ? mixGradient!.$1.withValues(alpha: 0.7)
                                  : (PlaylistCoverPresets.getPreset(
                                              playlist?.coverUri,
                                            ) !=
                                            null
                                        ? PlaylistCoverPresets.getPreset(
                                                playlist?.coverUri,
                                              )!.gradient.colors.first
                                              .withValues(alpha: 0.6)
                                        : colorScheme.primaryContainer
                                              .withValues(alpha: 0.6)),
                              colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap:
                              (!isLikedSongs &&
                                  !isDailyMix &&
                                  playlist != null &&
                                  playlist.id > 0)
                              ? () {
                                  haptics.selection();
                                  PlaylistCoverPickerSheet.show(
                                    context,
                                    playlist,
                                  );
                                }
                              : null,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadii.cardRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: PlaylistArtworkWidget(
                                  coverUri: playlist?.coverUri,
                                  size: 110,
                                  isLikedSongs: isLikedSongs,
                                  isDailyMix: isDailyMix,
                                  dailyMixIndex: mixIndex,
                                  isSmart: isSmart,
                                  heroTag: 'playlist_art_$playlistId',
                                ),
                              ),
                              if (!isLikedSongs &&
                                  !isDailyMix &&
                                  playlist != null &&
                                  playlist.id > 0)
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons & metadata
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${tracks.length} tracks • ${_formatTotalDuration(tracks)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isDailyMix)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [mixGradient!.$1, mixGradient.$2],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DAILY MIX',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else if (isSmart && !isLikedSongs)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'AUTO-SYNC',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (playlist?.description != null &&
                          playlist!.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          playlist.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
                                      unawaited(
                                        playback.playQueue(
                                          keys,
                                          initialIndex: 0,
                                        ),
                                      );
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
                                      final shuffled = List<String>.from(keys)
                                        ..shuffle();
                                      unawaited(
                                        playback.playQueue(
                                          shuffled,
                                          initialIndex: 0,
                                        ),
                                      );
                                      unawaited(playback.setShuffle(true));
                                    }
                                  : null,
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('Shuffle'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (tracks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLikedSongs
                                ? Icons.favorite_border_rounded
                                : Icons.music_note_rounded,
                            size: 56,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            isLikedSongs
                                ? 'No liked songs yet.\nTap the heart icon on any song to add it here!'
                                : 'This playlist is empty.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (!isSmart) ...[
                            const SizedBox(height: AppSpacing.m),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                haptics.selection();
                                _openTrackPicker(context, playlistId, tracks);
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Songs'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else if (isSmart)
                // Regular list for smart playlists
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = tracks[index];
                    return TrackTile(
                      track: track,
                      trackNumber: index + 1,
                      onTap: () {
                        haptics.selection();
                        final keys = tracks.map((t) => t.trackKey).toList();
                        unawaited(
                          playback.playQueue(keys, initialIndex: index),
                        );
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
                    );
                  }, childCount: tracks.length),
                )
              else
                // Reorderable list for custom playlists with working drag handle
                SliverReorderableList(
                  itemCount: tracks.length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final elevation = Tween<double>(
                          begin: 0,
                          end: 6,
                        ).evaluate(animation);
                        return Material(
                          elevation: elevation,
                          color: colorScheme.surfaceContainerHigh,
                          shadowColor: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  onReorderItem: (oldIndex, newIndex) {
                    haptics.light();
                    final targetIndex = oldIndex < newIndex
                        ? newIndex - 1
                        : newIndex;
                    unawaited(
                      playlistService.reorderTracks(
                        playlist!.id,
                        oldIndex,
                        targetIndex,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Material(
                      key: ValueKey(
                        'playlist_${playlist!.id}_${track.trackKey}_$index',
                      ),
                      color: Colors.transparent,
                      child: TrackTile(
                        track: track,
                        trackNumber: index + 1,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                              ),
                              color: colorScheme.onSurfaceVariant,
                              tooltip: 'Track options',
                              onPressed: () {
                                haptics.medium();
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (ctx) => TrackContextSheet(
                                    track: track,
                                    playlistId: playlist.id,
                                  ),
                                );
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                width: 36,
                                height: 48,
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          haptics.selection();
                          final keys = tracks.map((t) => t.trackKey).toList();
                          unawaited(
                            playback.playQueue(keys, initialIndex: index),
                          );
                        },
                        onMore: () {
                          haptics.medium();
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) => TrackContextSheet(
                              track: track,
                              playlistId: playlist.id,
                            ),
                          );
                        },
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export playlist: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Playlist Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (newName != null && newName.isNotEmpty) {
        await ref
            .read(playlistServiceProvider)
            .renamePlaylist(playlist.id, newName);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: const Text(
          'This action cannot be undone. Songs will remain in your library.',
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
