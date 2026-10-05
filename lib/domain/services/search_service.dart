import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

final searchServiceProvider = Provider<SearchService>((ref) {
  final db = ref.watch(databaseProvider);
  return SearchService(db);
});

enum SearchFilter {
  all('All'),
  songs('Songs'),
  albums('Albums'),
  artists('Artists'),
  playlists('Playlists');

  final String label;
  const SearchFilter(this.label);
}

class SearchResultGroup {
  final dynamic topResult; // Track | Album | Artist | Playlist
  final List<Track> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  const SearchResultGroup({
    this.topResult,
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  bool get isEmpty =>
      songs.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;
}

class SearchService {
  final AppDatabase _db;
  static const _recentSearchesKey = 'recent_searches_json';

  SearchService(this._db);

  /// Execute instant search across all entities
  Future<SearchResultGroup> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchResultGroup();
    }

    final songs = await _db.searchTracksFts(trimmed, limit: 30);
    final albums = await _db.searchAlbums(trimmed, limit: 15);
    final artists = await _db.searchArtists(trimmed, limit: 15);
    final playlists = await _db.searchPlaylists(trimmed, limit: 10);

    // Pick top result (closest match to query string)
    dynamic topResult;
    final lower = trimmed.toLowerCase();

    // Check exact or prefix artist
    for (final a in artists) {
      if (a.name.toLowerCase() == lower ||
          a.name.toLowerCase().startsWith(lower)) {
        topResult = a;
        break;
      }
    }
    // Check album
    if (topResult == null) {
      for (final al in albums) {
        if (al.title.toLowerCase() == lower ||
            al.title.toLowerCase().startsWith(lower)) {
          topResult = al;
          break;
        }
      }
    }
    // Check track
    if (topResult == null && songs.isNotEmpty) {
      topResult = songs.first;
    }

    return SearchResultGroup(
      topResult: topResult,
      songs: songs,
      albums: albums,
      artists: artists,
      playlists: playlists,
    );
  }

  /// Load recent searches from settings
  Future<List<String>> getRecentSearches() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(_recentSearchesKey))).getSingleOrNull();

    if (row == null) return [];
    try {
      final list = jsonDecode(row.valueJson) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add search term to history
  Future<void> addRecentSearch(String term) async {
    final clean = term.trim();
    if (clean.isEmpty) return;

    final existing = await getRecentSearches();
    existing.remove(clean);
    existing.insert(0, clean);
    if (existing.length > 20) {
      existing.removeRange(20, existing.length);
    }

    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _recentSearchesKey,
            valueJson: jsonEncode(existing),
          ),
        );
  }

  /// Remove single search term
  Future<void> removeRecentSearch(String term) async {
    final existing = await getRecentSearches();
    existing.remove(term);
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _recentSearchesKey,
            valueJson: jsonEncode(existing),
          ),
        );
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    await (_db.delete(
      _db.appSettings,
    )..where((s) => s.key.equals(_recentSearchesKey))).go();
  }
}
