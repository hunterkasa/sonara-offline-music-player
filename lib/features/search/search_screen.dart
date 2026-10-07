import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
import '../../domain/services/search_service.dart';
import '../../shared/artwork/artwork_widget.dart';
import '../../shared/cards/media_card.dart';
import '../../shared/track_tile/track_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilter _selectedFilter = SearchFilter.all;
  SearchResultGroup _results = const SearchResultGroup();
  List<String> _recentSearches = [];
  Timer? _debounceTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final searchService = ref.read(searchServiceProvider);
    final recents = await searchService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = recents;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = const SearchResultGroup();
        _isLoading = false;
      });
      _loadRecentSearches();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      final searchService = ref.read(searchServiceProvider);
      final res = await searchService.search(query);
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    });
  }

  void _executeSearch(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _onSearchChanged(term);
  }

  void _onResultInteracted() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchServiceProvider).addRecentSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final haptics = ref.read(hapticServiceProvider);
    final isQueryEmpty = _searchController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Search Input Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Songs, artists, albums, or playlists',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.s),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        haptics.light();
                        _searchController.clear();
                        _onSearchChanged('');
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
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          // Filter Chips (when search query is present)
          if (!isQueryEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  children: SearchFilter.values.map((filter) {
                    final selected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        label: Text(filter.label),
                        selected: selected,
                        onSelected: (val) {
                          haptics.selection();
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Search Content or Empty State
          if (isQueryEmpty)
            ..._buildEmptyState(context, colorScheme, theme, haptics)
          else
            ..._buildSearchResults(context, colorScheme, theme, haptics),
        ],
      ),
    );
  }

  List<Widget> _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    HapticService haptics,
  ) {
    return [
      // Recent Searches
      if (_recentSearches.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    haptics.light();
                    await ref.read(searchServiceProvider).clearRecentSearches();
                    setState(() {
                      _recentSearches = [];
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _recentSearches.map((term) {
                return InputChip(
                  label: Text(term),
                  avatar: const Icon(Icons.history_rounded, size: 18),
                  onPressed: () {
                    haptics.selection();
                    _executeSearch(term);
                  },
                  onDeleted: () async {
                    haptics.light();
                    await ref
                        .read(searchServiceProvider)
                        .removeRecentSearch(term);
                    await _loadRecentSearches();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],

      // Browse All / Genres
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.s,
          ),
          child: Text(
            'Browse All',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.s,
            crossAxisSpacing: AppSpacing.s,
            childAspectRatio: 1.8,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final genres = [
              ('Rock', Colors.deepOrangeAccent),
              ('Pop', Colors.pinkAccent),
              ('Hip-Hop', Colors.amberAccent),
              ('Classical', Colors.lightBlueAccent),
              ('Jazz', Colors.indigoAccent),
              ('Electronic', Colors.tealAccent),
              ('Metal', Colors.blueGrey),
              ('Indie', Colors.purpleAccent),
            ];
            final item = genres[index % genres.length];
            final accent = item.$2;
            return InkWell(
              onTap: () {
                haptics.selection();
                _executeSearch(item.$1);
              },
              borderRadius: AppRadii.cardRadius,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: AppRadii.cardRadius,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.20),
                      colorScheme.surfaceContainerHigh,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.$1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 20,
                      color: accent.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            );
          }, childCount: 8),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  List<Widget> _buildSearchResults(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    HapticService haptics,
  ) {
    if (_results.isEmpty && !_isLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'No results found for "${_searchController.text}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Check for spelling errors or try a different keyword',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final playback = ref.read(playbackControllerProvider);

    return [
      // Top Result (only if 'all' filter is selected and topResult is present)
      if (_selectedFilter == SearchFilter.all &&
          _results.topResult != null) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Text(
              'Top Result',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: _buildTopResultCard(context, colorScheme, theme, haptics),
          ),
        ),
      ],

      // Songs
      if ((_selectedFilter == SearchFilter.all ||
              _selectedFilter == SearchFilter.songs) &&
          _results.songs.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Text(
              'Songs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = _results.songs[index];
              return TrackTile(
                track: track,
                onTap: () {
                  haptics.selection();
                  _onResultInteracted();
                  playback.playTrack(track.trackKey);
                },
              );
            },
            childCount: _selectedFilter == SearchFilter.all
                ? _results.songs.length.clamp(0, 5)
                : _results.songs.length,
          ),
        ),
      ],

      // Albums
      if ((_selectedFilter == SearchFilter.all ||
              _selectedFilter == SearchFilter.albums) &&
          _results.albums.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Text(
              'Albums',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_selectedFilter == SearchFilter.all)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                itemCount: _results.albums.length,
                itemBuilder: (context, index) {
                  final album = _results.albums[index];
                  return SizedBox(
                    width: 140.0,
                    child: MediaCard(
                      title: album.title,
                      subtitle: album.year != null ? '${album.year}' : null,
                      artworkKey: album.artworkKey,
                      onTap: () {
                        haptics.selection();
                        _onResultInteracted();
                        context.push('/album/${album.id}');
                      },
                    ),
                  );
                },
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.s,
                crossAxisSpacing: AppSpacing.s,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final album = _results.albums[index];
                return MediaCard(
                  title: album.title,
                  subtitle: album.year != null ? '${album.year}' : null,
                  artworkKey: album.artworkKey,
                  onTap: () {
                    haptics.selection();
                    _onResultInteracted();
                    context.push('/album/${album.id}');
                  },
                );
              }, childCount: _results.albums.length),
            ),
          ),
      ],

      // Artists
      if ((_selectedFilter == SearchFilter.all ||
              _selectedFilter == SearchFilter.artists) &&
          _results.artists.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Text(
              'Artists',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final artist = _results.artists[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person_rounded, color: colorScheme.primary),
                ),
                title: Text(
                  artist.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Artist'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  haptics.selection();
                  _onResultInteracted();
                  context.push('/artist/${artist.id}');
                },
              );
            },
            childCount: _selectedFilter == SearchFilter.all
                ? _results.artists.length.clamp(0, 4)
                : _results.artists.length,
          ),
        ),
      ],

      // Playlists
      if ((_selectedFilter == SearchFilter.all ||
              _selectedFilter == SearchFilter.playlists) &&
          _results.playlists.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Text(
              'Playlists',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final playlist = _results.playlists[index];
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadii.cardRadius,
                ),
                child: Icon(
                  playlist.isSmart
                      ? Icons.auto_awesome_rounded
                      : Icons.queue_music_rounded,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                playlist.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(playlist.isSmart ? 'Smart Playlist' : 'Playlist'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                haptics.selection();
                _onResultInteracted();
                context.push('/playlist/${playlist.id}');
              },
            );
          }, childCount: _results.playlists.length),
        ),
      ],

      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  Widget _buildTopResultCard(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    HapticService haptics,
  ) {
    final top = _results.topResult;
    String title = '';
    String subtitle = '';
    String typeTag = '';
    VoidCallback? onTap;

    if (top is Track) {
      title = top.title;
      subtitle = 'Song • ${top.trackKey}';
      typeTag = 'SONG';
      onTap = () {
        haptics.selection();
        _onResultInteracted();
        ref.read(playbackControllerProvider).playTrack(top.trackKey);
      };
    } else if (top is Album) {
      title = top.title;
      subtitle = top.year != null ? 'Album • ${top.year}' : 'Album';
      typeTag = 'ALBUM';
      onTap = () {
        haptics.selection();
        _onResultInteracted();
        context.push('/album/${top.id}');
      };
    } else if (top is Artist) {
      title = top.name;
      subtitle = 'Artist';
      typeTag = 'ARTIST';
      onTap = () {
        haptics.selection();
        _onResultInteracted();
        context.push('/artist/${top.id}');
      };
    } else if (top is Playlist) {
      title = top.name;
      subtitle = top.isSmart ? 'Smart Playlist' : 'Playlist';
      typeTag = 'PLAYLIST';
      onTap = () {
        haptics.selection();
        _onResultInteracted();
        context.push('/playlist/${top.id}');
      };
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              if (top is Album)
                ArtworkWidget(
                  title: top.title,
                  artworkKey: top.artworkKey,
                  size: 72,
                  borderRadius: AppRadii.artwork,
                )
              else if (top is Artist)
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                )
              else if (top is Playlist)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadii.cardRadius,
                  ),
                  child: Icon(
                    top.isSmart
                        ? Icons.auto_awesome_rounded
                        : Icons.queue_music_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                )
              else if (top is Track)
                ArtworkWidget(
                  title: top.title,
                  filePath: top.path,
                  size: 72,
                  borderRadius: AppRadii.artwork,
                ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeTag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
