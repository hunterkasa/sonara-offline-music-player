import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/playlist_service.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';

class PlaylistTrackPickerSheet extends ConsumerStatefulWidget {
  final int playlistId;
  final List<String> currentTrackKeys;

  const PlaylistTrackPickerSheet({
    super.key,
    required this.playlistId,
    required this.currentTrackKeys,
  });

  @override
  ConsumerState<PlaylistTrackPickerSheet> createState() =>
      _PlaylistTrackPickerSheetState();
}

class _PlaylistTrackPickerSheetState
    extends ConsumerState<PlaylistTrackPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selectedKeys;
  late final Set<String> _initialKeys;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set<String>.from(widget.currentTrackKeys);
    _initialKeys = Set<String>.from(widget.currentTrackKeys);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final db = ref.watch(databaseProvider);
    final haptics = ref.read(hapticServiceProvider);
    final playlistService = ref.read(playlistServiceProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadii.sheetRadius,
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add / Remove Songs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedKeys.length} songs selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: () async {
                        haptics.selection();
                        // Find added keys and removed keys
                        final toAdd = _selectedKeys
                            .difference(_initialKeys)
                            .toList();
                        final toRemove = _initialKeys
                            .difference(_selectedKeys)
                            .toList();

                        if (toAdd.isNotEmpty) {
                          await playlistService.addTracksToPlaylist(
                            widget.playlistId,
                            toAdd,
                          );
                        }
                        for (final key in toRemove) {
                          await playlistService.removeTrackFromPlaylist(
                            widget.playlistId,
                            key,
                          );
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Updated playlist (+${toAdd.length}, -${toRemove.length})',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search songs to add...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll<double>(0.0),
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    colorScheme.surfaceContainerHigh,
                  ),
                  shape: const WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              const Divider(height: 1),

              // Track List
              Expanded(
                child: StreamBuilder<List<Track>>(
                  stream: db.watchAllTracks(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allTracks = snapshot.data!;
                    final filtered = allTracks.where((t) {
                      if (_searchQuery.isEmpty) return true;
                      return t.title.toLowerCase().contains(_searchQuery) ||
                          t.path.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No songs in library'
                              : 'No matches found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final track = filtered[index];
                        final isSelected = _selectedKeys.contains(
                          track.trackKey,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            haptics.selection();
                            setState(() {
                              if (checked == true) {
                                _selectedKeys.add(track.trackKey);
                              } else {
                                _selectedKeys.remove(track.trackKey);
                              }
                            });
                          },
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: ArtworkWidget(
                                artworkKey: track.artworkKey,
                                filePath: track.path,
                                title: track.title,
                                size: 44,
                              ),
                            ),
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${track.durationMs ~/ 60000}:${((track.durationMs % 60000) ~/ 1000).toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
