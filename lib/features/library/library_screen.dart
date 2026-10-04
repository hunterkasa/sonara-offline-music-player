import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/library_scanner.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';
import 'package:sonara/shared/cards/media_card.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

enum LibraryTab { songs, albums, artists, genres, folders }

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
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryTab _currentTab = LibraryTab.songs;
  SongSortOption _sortOption = SongSortOption.titleAsc;
  bool _isGridView = false;
  final ScrollController _scrollController = ScrollController();

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
          if (_currentTab == LibraryTab.songs)
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort',
              onPressed: () => _showSortSheet(context),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(libraryScannerProvider.notifier)
                    .scanLibrary(isFullScan: true);
              },
              child: _buildTabContent(),
            ),
          ),
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
        setState(() => _currentTab = tab);
      },
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
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

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 96.0),
              itemCount: tracks.length,
              itemExtent: 64.0,
              itemBuilder: (context, index) {
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
              },
            ),
            // Sticky A-Z Scrubber
            Positioned(
              right: 2.0,
              top: 16.0,
              bottom: 110.0,
              child: _buildAlphabetScrubber(titles),
            ),
          ],
        );
      },
    );
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

    return StreamBuilder<List<Genre>>(
      stream: (db.select(
        db.genres,
      )..orderBy([(g) => d.OrderingTerm.asc(g.name)])).watch(),
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
            final genre = genres[index];
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
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Folders View
  // ---------------------------------------------------------------------------
  Widget _buildFoldersView() {
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<Track>>(
      stream: (db.select(
        db.tracks,
      )..orderBy([(t) => d.OrderingTerm.asc(t.path)])).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tracks = snapshot.data!;
        if (tracks.isEmpty) {
          return _buildEmptyState('No music folders found');
        }

        final folderMap = <String, int>{};
        for (final t in tracks) {
          final dir = t.relativeDir.isNotEmpty ? t.relativeDir : 'Root';
          folderMap[dir] = (folderMap[dir] ?? 0) + 1;
        }

        final folders = folderMap.entries.toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96.0),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return ListTile(
              leading: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              title: Text(
                folder.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${folder.value} tracks'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
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
}
