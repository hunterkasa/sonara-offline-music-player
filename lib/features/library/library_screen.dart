import 'dart:async';

import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/library_scanner.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/domain/services/playlist_service.dart';
import 'package:sonara/features/playlist/playlist_cover_picker_sheet.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';
import 'package:sonara/shared/artwork/playlist_artwork_widget.dart';
import 'package:sonara/shared/cards/media_card.dart';
import 'package:sonara/shared/selection/multi_select_action_bar.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

import '../playlist/add_to_playlist_sheet.dart';

enum LibraryTab { playlists, songs, albums, artists, genres, folders }

enum SongSortOption {
  titleAsc('Title (A-Z)'),
  titleDesc('Title (Z-A)'),
  dateAddedDesc('Recently Added'),
  durationDesc('Duration (Longest)'),
  playCountDesc('Most Played');

  final String label;
  const SongSortOption(this.label);
}

class LibraryScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const LibraryScreen({super.key, this.initialTab});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late LibraryTab _currentTab;
  SongSortOption _sortOption = SongSortOption.titleAsc;
  bool _isGridView = false;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedTrackKeys = {};
  bool _isSelectionMode = false;
  bool _isFolderTreeView = false;
  String _currentFolderPath = '';

  @override
  void initState() {
    super.initState();
    _currentTab = _resolveTab(widget.initialTab);
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _currentTab = _resolveTab(widget.initialTab);
      });
    }
  }

  LibraryTab _resolveTab(String? tab) {
    return switch (tab?.toLowerCase()) {
      'playlists' || 'playlist' => LibraryTab.playlists,
      'albums' || 'album' => LibraryTab.albums,
      'artists' || 'artist' => LibraryTab.artists,
      'genres' || 'genre' => LibraryTab.genres,
      'folders' || 'folder' => LibraryTab.folders,
      'songs' || 'song' => LibraryTab.songs,
      _ => LibraryTab.songs,
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter, List<String> titles) {
    final lowerLetter = letter.toLowerCase();
    int targetIndex = -1;

    for (var i = 0; i < titles.length; i++) {
      final t = titles[i].trim().toLowerCase();
      if (lowerLetter == '#' && (t.isEmpty || !RegExp(r'^[a-z]').hasMatch(t))) {
        targetIndex = i;
        break;
      } else if (t.startsWith(lowerLetter)) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != -1 && _scrollController.hasClients) {
      final offset = (targetIndex * 64.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Sort Songs',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ...SongSortOption.values.map(
                  (option) => ListTile(
                    title: Text(option.label),
                    trailing: _sortOption == option
                        ? Icon(
                            Icons.check_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    selected: _sortOption == option,
                    onTap: () {
                      setState(() => _sortOption = option);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scanProgress = ref.watch(libraryScannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Library',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentTab == LibraryTab.songs) ...[
            IconButton(
              icon: Icon(
                _isSelectionMode
                    ? Icons.checklist_rtl_rounded
                    : Icons.checklist_rounded,
              ),
              tooltip: _isSelectionMode ? 'Exit Selection' : 'Select Songs',
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) _selectedTrackKeys.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort',
              onPressed: () => _showSortSheet(context),
            ),
          ],
          if (_currentTab == LibraryTab.folders)
            IconButton(
              icon: Icon(
                _isFolderTreeView
                    ? Icons.format_list_bulleted_rounded
                    : Icons.account_tree_outlined,
              ),
              tooltip: _isFolderTreeView ? 'Flat View' : 'Folder Tree',
              onPressed: () {
                setState(() {
                  _isFolderTreeView = !_isFolderTreeView;
                  _currentFolderPath = '';
                });
              },
            ),
          if (_currentTab == LibraryTab.albums ||
              _currentTab == LibraryTab.artists)
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
              tooltip: _isGridView ? 'List view' : 'Grid view',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Rescan Library',
            onPressed: () {
              ref
                  .read(libraryScannerProvider.notifier)
                  .scanLibrary(isFullScan: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live scan progress banner
          if (scanProgress.isScanning)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              color: colorScheme.primaryContainer.withValues(alpha: 0.7),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      scanProgress.statusMessage ?? 'Scanning...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (scanProgress.totalCount > 0)
                    Text(
                      '${scanProgress.scannedCount}/${scanProgress.totalCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

          // Pinned Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildFilterChip('Playlists', LibraryTab.playlists),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Songs', LibraryTab.songs),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Albums', LibraryTab.albums),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Artists', LibraryTab.artists),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Genres', LibraryTab.genres),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Folders', LibraryTab.folders),
              ],
            ),
          ),
          const Divider(height: 1.0),

          // Main Tab Body
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, LibraryTab tab) {
    final isSelected = _currentTab == tab;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentTab = tab;
          _selectedTrackKeys.clear();
          _isSelectionMode = false;
          _currentFolderPath = '';
        });
      },
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case LibraryTab.playlists:
        return _buildPlaylistsView();
      case LibraryTab.songs:
        return _buildSongsView();
      case LibraryTab.albums:
        return _buildAlbumsView();
      case LibraryTab.artists:
        return _buildArtistsView();
      case LibraryTab.genres:
        return _buildGenresView();
      case LibraryTab.folders:
        return _buildFoldersView();
    }
  }

  // ---------------------------------------------------------------------------
  // Songs View with A-Z Scrubber
  // ---------------------------------------------------------------------------
  Widget _buildSongsView() {
    final db = ref.watch(databaseProvider);
    final playback = ref.watch(playbackControllerProvider);
    final haptics = ref.watch(hapticServiceProvider);

    return StreamBuilder<List<Track>>(
      stream: _getSortedTracksStream(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tracks = snapshot.data!;
        if (tracks.isEmpty) {
          return _buildEmptyState('No songs found in your library');
        }

        final titles = tracks.map((t) => t.titleSort).toList();
        final isSelecting = _isSelectionMode || _selectedTrackKeys.isNotEmpty;

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(bottom: isSelecting ? 148.0 : 96.0),
              itemCount: tracks.length,
              itemExtent: 64.0,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isSelected = _selectedTrackKeys.contains(track.trackKey);

                return TrackTile(
                  track: track,
                  isSelectable: isSelecting,
                  isSelected: isSelected,
                  onSelectChanged: (val) {
                    haptics.selection();
                    setState(() {
                      if (val == true) {
                        _selectedTrackKeys.add(track.trackKey);
                      } else {
                        _selectedTrackKeys.remove(track.trackKey);
                        if (_selectedTrackKeys.isEmpty && !_isSelectionMode) {
                          _isSelectionMode = false;
                        }
                      }
                    });
                  },
                  onLongPress: () {
                    haptics.medium();
                    setState(() {
                      _isSelectionMode = true;
                      _selectedTrackKeys.add(track.trackKey);
                    });
                  },
                  onTap: () {
                    if (isSelecting) {
                      haptics.selection();
                      setState(() {
                        if (isSelected) {
                          _selectedTrackKeys.remove(track.trackKey);
                          if (_selectedTrackKeys.isEmpty && !_isSelectionMode) {
                            _isSelectionMode = false;
                          }
                        } else {
                          _selectedTrackKeys.add(track.trackKey);
                        }
                      });
                    } else {
                      playback.playQueue(
                        tracks.map((t) => t.trackKey).toList(),
                        initialIndex: index,
                      );
                    }
                  },
                );
              },
            ),
            // Sticky A-Z Scrubber
            if (!isSelecting)
              Positioned(
                right: 2.0,
                top: 16.0,
                bottom: 110.0,
                child: _buildAlphabetScrubber(titles),
              ),
            // Multi-Select Action Bar
            if (isSelecting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MultiSelectActionBar(
                  selectedCount: _selectedTrackKeys.length,
                  totalCount: tracks.length,
                  onClear: () {
                    haptics.selection();
                    setState(() {
                      _selectedTrackKeys.clear();
                      _isSelectionMode = false;
                    });
                  },
                  onSelectAll: () {
                    haptics.selection();
                    setState(() {
                      _selectedTrackKeys.addAll(tracks.map((t) => t.trackKey));
                    });
                  },
                  onPlay: () {
                    haptics.selection();
                    final selected = _selectedTrackKeys.toList();
                    if (selected.isNotEmpty) {
                      playback.playQueue(selected);
                    }
                  },
                  onAddToQueue: () async {
                    haptics.selection();
                    final selected = _selectedTrackKeys.toList();
                    for (final k in selected) {
                      await playback.addToQueue(k);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${selected.length} songs to queue',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    setState(() {
                      _selectedTrackKeys.clear();
                      _isSelectionMode = false;
                    });
                  },
                  onAddToPlaylist: () {
                    haptics.selection();
                    final selected = _selectedTrackKeys.toList();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => AddToPlaylistSheet(trackKeys: selected),
                    );
                  },
                  onFavorite: () async {
                    haptics.selection();
                    final selected = _selectedTrackKeys.toList();
                    await db.setFavoriteTracks(selected, true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${selected.length} songs to Favorites',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    setState(() {
                      _selectedTrackKeys.clear();
                      _isSelectionMode = false;
                    });
                  },
                  onDelete: () =>
                      _showBatchDeleteDialog(_selectedTrackKeys.toList()),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showBatchDeleteDialog(List<String> trackKeys) async {
    final haptics = ref.read(hapticServiceProvider);
    haptics.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Songs'),
        content: Text(
          'Are you sure you want to remove ${trackKeys.length} ${trackKeys.length == 1 ? 'song' : 'songs'} from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.deleteTracks(trackKeys);
      haptics.light();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${trackKeys.length} songs'),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _selectedTrackKeys.clear();
          _isSelectionMode = false;
        });
      }
    }
  }

  Stream<List<Track>> _getSortedTracksStream(AppDatabase db) {
    final query = db.select(db.tracks);
    switch (_sortOption) {
      case SongSortOption.titleAsc:
        query.orderBy([(t) => d.OrderingTerm.asc(t.titleSort)]);
        break;
      case SongSortOption.titleDesc:
        query.orderBy([(t) => d.OrderingTerm.desc(t.titleSort)]);
        break;
      case SongSortOption.dateAddedDesc:
        query.orderBy([(t) => d.OrderingTerm.desc(t.dateAdded)]);
        break;
      case SongSortOption.durationDesc:
        query.orderBy([(t) => d.OrderingTerm.desc(t.durationMs)]);
        break;
      case SongSortOption.playCountDesc:
        query.orderBy([(t) => d.OrderingTerm.desc(t.playCount)]);
        break;
    }
    return query.watch();
  }

  Widget _buildAlphabetScrubber(List<String> titles) {
    const letters = [
      '#',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: letters.map((letter) {
            return GestureDetector(
              onTap: () => _scrollToLetter(letter, titles),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 1.0,
                  horizontal: 2.0,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Albums View (List or Grid)
  // ---------------------------------------------------------------------------
  Widget _buildAlbumsView() {
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<Album>>(
      stream: (db.select(
        db.albums,
      )..orderBy([(a) => d.OrderingTerm.asc(a.titleSort)])).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final albums = snapshot.data!;
        if (albums.isEmpty) {
          return _buildEmptyState('No albums found');
        }

        if (_isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 96.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.78,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return MediaCard(
                title: album.title,
                subtitle: album.year != null ? '${album.year}' : null,
                artworkKey: album.artworkKey,
                onTap: () => context.push('/album/${album.id}'),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96.0),
          itemCount: albums.length,
          itemExtent: 72.0,
          itemBuilder: (context, index) {
            final album = albums[index];
            return ListTile(
              leading: ArtworkWidget(
                title: album.title,
                artworkKey: album.artworkKey,
                size: 52.0,
                borderRadius: 8.0,
              ),
              title: Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: album.year != null ? Text('${album.year}') : null,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/album/${album.id}'),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Artists View (List or Grid)
  // ---------------------------------------------------------------------------
  Widget _buildArtistsView() {
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<Artist>>(
      stream: (db.select(
        db.artists,
      )..orderBy([(a) => d.OrderingTerm.asc(a.nameSort)])).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists = snapshot.data!;
        if (artists.isEmpty) {
          return _buildEmptyState('No artists found');
        }

        if (_isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 96.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.85,
            ),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return MediaCard(
                title: artist.name,
                artworkKey: artist.artworkKey,
                isCircular: true,
                onTap: () => context.push('/artist/${artist.id}'),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96.0),
          itemCount: artists.length,
          itemExtent: 68.0,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 24.0,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/artist/${artist.id}'),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Genres View
  // ---------------------------------------------------------------------------
  Widget _buildGenresView() {
    final db = ref.watch(databaseProvider);
    final haptics = ref.read(hapticServiceProvider);

    return StreamBuilder<List<(Genre, int)>>(
      stream: db.watchGenresWithCount(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final genres = snapshot.data!;
        if (genres.isEmpty) {
          return _buildEmptyState('No genres found');
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96.0),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final (genre, count) = genres[index];
            return ListTile(
              leading: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.album_rounded,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                genre.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                count == 1 ? '1 song' : '$count songs',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                haptics.selection();
                context.push('/genre/${genre.id}');
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Folders View (Flat & Hierarchy Tree Modes)
  // ---------------------------------------------------------------------------
  Widget _buildFoldersView() {
    final haptics = ref.read(hapticServiceProvider);
    final foldersAsync = ref.watch(folderSummariesStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return foldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading folders: $e')),
      data: (folders) {
        if (folders.isEmpty) {
          return _buildEmptyState('No music folders found');
        }

        if (!_isFolderTreeView) {
          return _buildFlatFoldersList(folders, haptics, theme, colorScheme);
        }

        return _buildFolderTreeView(folders, haptics, theme, colorScheme);
      },
    );
  }

  Widget _buildFolderViewHeader(int folderCount, bool isTree) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final haptics = ref.read(hapticServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTree ? Icons.account_tree_outlined : Icons.folder_open_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isTree ? 'Folder Tree' : 'All Folders ($folderCount)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.format_list_bulleted_rounded, size: 16),
                label: Text('Flat'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.account_tree_rounded, size: 16),
                label: Text('Tree'),
              ),
            ],
            selected: {_isFolderTreeView},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (set) {
              haptics.selection();
              setState(() {
                _isFolderTreeView = set.first;
                _currentFolderPath = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFlatFoldersList(
    List<FolderSummary> folders,
    HapticService haptics,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildFolderViewHeader(folders.length, false),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 96.0),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                title: Text(
                  folder.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${folder.trackCount} ${folder.trackCount == 1 ? 'song' : 'songs'}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  haptics.selection();
                  context.push(
                    '/folder?path=${Uri.encodeQueryComponent(folder.path)}',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFolderTreeView(
    List<FolderSummary> folders,
    HapticService haptics,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    String norm(String p) =>
        p.replaceAll('\\', '/').replaceAll(RegExp(r'^/+|/+$'), '');

    final normalized = folders
        .map((f) => (path: norm(f.path), count: f.trackCount))
        .toList();

    final currentNorm = norm(_currentFolderPath);
    final prefix = currentNorm.isEmpty ? '' : '$currentNorm/';

    // Calculate subfolders and direct tracks at this level
    final Map<String, int> subfolderCounts = {};
    int directCount = 0;
    bool hasExactFolder = false;

    for (final item in normalized) {
      if (item.path == currentNorm && currentNorm.isNotEmpty) {
        directCount += item.count;
        hasExactFolder = true;
      } else if (prefix.isEmpty || item.path.startsWith(prefix)) {
        final remainder = prefix.isEmpty
            ? item.path
            : item.path.substring(prefix.length);
        if (remainder.isNotEmpty) {
          final firstSegment = remainder.split('/').first;
          subfolderCounts[firstSegment] =
              (subfolderCounts[firstSegment] ?? 0) + item.count;
        }
      }
    }

    final subfolderNames = subfolderCounts.keys.toList()..sort();
    final breadcrumbSegments = currentNorm.isEmpty
        ? <String>[]
        : currentNorm.split('/');

    return Column(
      children: [
        _buildFolderViewHeader(folders.length, true),

        // Interactive Breadcrumbs Row
        Container(
          width: double.infinity,
          color: colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    haptics.selection();
                    setState(() => _currentFolderPath = '');
                  },
                  borderRadius: BorderRadius.circular(4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.home_filled,
                          size: 16,
                          color: currentNorm.isEmpty
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Root',
                          style: TextStyle(
                            fontWeight: currentNorm.isEmpty
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: currentNorm.isEmpty
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (var i = 0; i < breadcrumbSegments.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      haptics.selection();
                      final target = breadcrumbSegments.take(i + 1).join('/');
                      setState(() => _currentFolderPath = target);
                    },
                    borderRadius: BorderRadius.circular(4.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      child: Text(
                        breadcrumbSegments[i],
                        style: TextStyle(
                          fontWeight: (i == breadcrumbSegments.length - 1)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (i == breadcrumbSegments.length - 1)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // List of entries: Parent navigation, Direct folder action, Subfolders
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96.0),
            children: [
              // Up to Parent Folder row
              if (currentNorm.isNotEmpty)
                ListTile(
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.drive_folder_upload_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: const Text(
                    '.. Up to Parent',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Back to previous folder level'),
                  onTap: () {
                    haptics.selection();
                    if (breadcrumbSegments.length <= 1) {
                      setState(() => _currentFolderPath = '');
                    } else {
                      final parent = breadcrumbSegments
                          .take(breadcrumbSegments.length - 1)
                          .join('/');
                      setState(() => _currentFolderPath = parent);
                    }
                  },
                ),

              // If current folder has direct tracks or matches an indexed folder
              if (hasExactFolder || directCount > 0)
                ListTile(
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.library_music_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'Songs in "${breadcrumbSegments.isNotEmpty ? breadcrumbSegments.last : currentNorm}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$directCount ${directCount == 1 ? 'song' : 'songs'} directly in this folder',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    haptics.selection();
                    context.push(
                      '/folder?path=${Uri.encodeQueryComponent(_currentFolderPath)}',
                    );
                  },
                ),

              // Immediate subfolders
              for (final sub in subfolderNames)
                ListTile(
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                  title: Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${subfolderCounts[sub]} ${subfolderCounts[sub] == 1 ? 'song' : 'songs'}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    haptics.selection();
                    final next = currentNorm.isEmpty
                        ? sub
                        : '$currentNorm/$sub';
                    setState(() => _currentFolderPath = next);
                  },
                ),

              if (subfolderNames.isEmpty && !hasExactFolder && directCount == 0)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: Text('Folder is empty')),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsView() {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final haptics = ref.read(hapticServiceProvider);
    final playlistService = ref.read(playlistServiceProvider);
    final playback = ref.read(playbackControllerProvider);

    return StreamBuilder<List<Track>>(
      stream: db.watchLikedTracks(),
      builder: (context, likedSnapshot) {
        final likedTracks = likedSnapshot.data ?? [];

        return StreamBuilder<List<Playlist>>(
          stream: db.watchAllPlaylists(),
          builder: (context, playlistSnapshot) {
            final playlists = playlistSnapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              children: [
                // Pinned Liked Songs item
                ListTile(
                  leading: const PlaylistArtworkWidget(
                    size: 52,
                    isLikedSongs: true,
                  ),
                  title: const Text(
                    'Liked Songs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${likedTracks.length} songs'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    haptics.selection();
                    context.push('/playlist/-1');
                  },
                ),
                const Divider(),

                // Create new playlist button
                ListTile(
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadii.cardRadius,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'Create Playlist',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Add your favorite tracks'),
                  onTap: () async {
                    haptics.selection();
                    final controller = TextEditingController();
                    try {
                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('New Playlist'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Playlist name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(controller.text.trim()),
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      );

                      if (name != null && name.isNotEmpty) {
                        final id = await playlistService.createPlaylist(
                          name: name,
                        );
                        if (context.mounted) {
                          unawaited(context.push('/playlist/$id'));
                        }
                      }
                    } finally {
                      controller.dispose();
                    }
                  },
                ),

                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No playlists yet. Create your first playlist above!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...playlists.map((p) {
                    return ListTile(
                      leading: PlaylistArtworkWidget(
                        coverUri: p.coverUri,
                        size: 52,
                        isSmart: p.isSmart,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        p.isSmart ? 'Smart Playlist' : 'Custom Playlist',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        haptics.selection();
                        context.push('/playlist/${p.id}');
                      },
                      onLongPress: () {
                        haptics.medium();
                        _showPlaylistOptionsSheet(
                          context,
                          p,
                          playlistService,
                          playback,
                          haptics,
                        );
                      },
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 64.0,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(libraryScannerProvider.notifier)
                    .scanLibrary(isFullScan: true);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Library'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistOptionsSheet(
    BuildContext context,
    Playlist playlist,
    PlaylistService playlistService,
    PlaybackController playback,
    HapticService haptics,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                title: Text(
                  playlist.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  playlist.isSmart ? 'Smart Playlist' : 'Custom Playlist',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Play'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final keys = await playlistService.getPlaylistTrackKeys(
                    playlist.id,
                  );
                  if (keys.isNotEmpty) {
                    unawaited(playback.playQueue(keys, initialIndex: 0));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.shuffle_rounded),
                title: const Text('Shuffle'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final keys = await playlistService.getPlaylistTrackKeys(
                    playlist.id,
                  );
                  if (keys.isNotEmpty) {
                    final shuffled = List<String>.from(keys)..shuffle();
                    unawaited(playback.playQueue(shuffled, initialIndex: 0));
                    unawaited(playback.setShuffle(true));
                  }
                },
              ),
              if (!playlist.isSmart) ...[
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Change Cover'),
                  onTap: () {
                    Navigator.pop(ctx);
                    PlaylistCoverPickerSheet.show(context, playlist);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Rename'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final controller = TextEditingController(
                      text: playlist.name,
                    );
                    try {
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Rename Playlist'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dCtx, controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (newName != null && newName.isNotEmpty) {
                        await playlistService.renamePlaylist(
                          playlist.id,
                          newName,
                        );
                      }
                    } finally {
                      controller.dispose();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Duplicate'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await playlistService.duplicatePlaylist(playlist.id);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Delete Playlist?'),
                        content: Text(
                          'Delete "${playlist.name}"? Tracks will remain in your library.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await playlistService.deletePlaylist(playlist.id);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
