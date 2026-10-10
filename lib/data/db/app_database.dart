import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import '../../core/utils/cue_parser.dart';
import '../../core/utils/metadata_utils.dart';
import '../../core/utils/track_key.dart';

part 'app_database.g.dart';

class FolderSummary {
  final String path;
  final int trackCount;

  const FolderSummary({required this.path, required this.trackCount});
}

@DriftDatabase(
  tables: [
    Tracks,
    Artists,
    Albums,
    Genres,
    TrackGenres,
    Playlists,
    PlaylistTracks,
    QueueStateTable,
    PlayHistory,
    LibraryFolders,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE VIRTUAL TABLE IF NOT EXISTS tracks_fts USING fts5('
        'track_key UNINDEXED, '
        'title, '
        'artist, '
        'album, '
        'genre'
        ');',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tracks, tracks.cueStartMs);
        await m.addColumn(tracks, tracks.cueEndMs);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'sonara.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  /// Fast in-memory database constructor for testing
  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Observe tracks reactive stream
  Stream<List<Track>> watchAllTracks({bool includeHidden = false}) {
    if (includeHidden) {
      return (select(
        tracks,
      )..orderBy([(t) => OrderingTerm.asc(t.titleSort)])).watch();
    }
    return (select(tracks)
          ..where((t) => t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.titleSort)]))
        .watch();
  }

  /// Count tracks
  Future<int> getTrackCount() async {
    final count = tracks.id.count();
    final query = selectOnly(tracks)..addColumns([count]);
    final result = await query.map((row) => row.read(count)).getSingle();
    return result ?? 0;
  }

  /// Full-text search using FTS5 with sanitized tokens
  Future<List<String>> searchTrackKeysFts(String term) async {
    final tokens = term
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll(RegExp(r'["\*\(\)\:\^\-]'), '').trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];

    final ftsQuery = tokens.map((t) => '"$t"*').join(' ');
    try {
      final rows = await customSelect(
        'SELECT track_key FROM tracks_fts WHERE tracks_fts MATCH ?',
        variables: [Variable.withString(ftsQuery)],
      ).get();

      return rows.map((row) => row.read<String>('track_key')).toList();
    } catch (_) {
      return [];
    }
  }

  /// Full-text search returning full Track entities
  Future<List<Track>> searchTracksFts(String term, {int limit = 50}) async {
    final keys = await searchTrackKeysFts(term);
    if (keys.isEmpty) return [];
    final targetKeys = keys.take(limit).toList();
    return getTracksByKeys(targetKeys);
  }

  /// Clear all track, album, and artist data from DB
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(trackGenres).go();
      await delete(playlistTracks).go();
      await delete(tracks).go();
      await delete(albums).go();
      await delete(artists).go();
      await delete(genres).go();
      await delete(appSettings).go();
      await delete(queueStateTable).go();
      await customStatement('DELETE FROM tracks_fts;');
    });
  }

  /// Get track by unique trackKey
  Future<Track?> getTrackByKey(String trackKey) {
    return (select(
      tracks,
    )..where((t) => t.trackKey.equals(trackKey))).getSingleOrNull();
  }

  /// Get list of tracks matching given keys preserving order (batched to prevent SQLite variable limits)
  Future<List<Track>> getTracksByKeys(List<String> keys) async {
    if (keys.isEmpty) return [];
    final fetched = <Track>[];
    const chunkSize = 250;
    for (var i = 0; i < keys.length; i += chunkSize) {
      final chunk = keys.sublist(
        i,
        (i + chunkSize < keys.length) ? i + chunkSize : keys.length,
      );
      final batchResult = await (select(
        tracks,
      )..where((t) => t.trackKey.isIn(chunk))).get();
      fetched.addAll(batchResult);
    }
    final map = {for (final t in fetched) t.trackKey: t};
    final ordered = <Track>[];
    for (final key in keys) {
      final t = map[key];
      if (t != null) ordered.add(t);
    }
    return ordered;
  }

  /// Get artist name by ID
  Future<String?> getArtistName(int? artistId) async {
    if (artistId == null) return null;
    final row = await (select(
      artists,
    )..where((a) => a.id.equals(artistId))).getSingleOrNull();
    return row?.name;
  }

  /// Get album title by ID
  Future<String?> getAlbumTitle(int? albumId) async {
    if (albumId == null) return null;
    final row = await (select(
      albums,
    )..where((a) => a.id.equals(albumId))).getSingleOrNull();
    return row?.title;
  }

  /// Reconcile decoder duration with tracks table
  Future<void> updateTrackDuration(String trackKey, int durationMs) async {
    await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
      TracksCompanion(durationMs: Value(durationMs)),
    );
  }

  /// Mark track as missing when file not found
  Future<void> markTrackMissing(String trackKey) async {
    await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
      const TracksCompanion(isMissing: Value(true)),
    );
  }

  /// Toggle favorite status of a track
  Future<bool> toggleFavorite(String trackKey) async {
    final track = await getTrackByKey(trackKey);
    if (track == null) return false;
    final newFavorite = !track.isFavorite;
    await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
      TracksCompanion(isFavorite: Value(newFavorite)),
    );
    return newFavorite;
  }

  /// Watch a track by key reactively
  Stream<Track?> watchTrack(String trackKey) {
    return (select(
      tracks,
    )..where((t) => t.trackKey.equals(trackKey))).watchSingleOrNull();
  }

  /// Watch all liked tracks reactively
  Stream<List<Track>> watchLikedTracks() {
    return (select(tracks)
          ..where((t) => t.isFavorite.equals(true) & t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)]))
        .watch();
  }

  /// Watch all playlists
  Stream<List<Playlist>> watchAllPlaylists() {
    return (select(
      playlists,
    )..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();
  }

  /// Get playlist by ID
  Future<Playlist?> getPlaylist(int id) {
    return (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Watch a single playlist
  Stream<Playlist?> watchPlaylist(int id) {
    return (select(
      playlists,
    )..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  /// Create a new playlist
  Future<int> createPlaylist({
    required String name,
    String? description,
    bool isSmart = false,
    String? rulesJson,
    String? coverUri,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return into(playlists).insert(
      PlaylistsCompanion.insert(
        name: name,
        description: Value(description),
        isSmart: Value(isSmart),
        rulesJson: Value(rulesJson),
        coverUri: Value(coverUri),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Rename an existing playlist
  Future<void> renamePlaylist(int id, String newName) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(name: Value(newName), updatedAt: Value(now)),
    );
  }

  /// Update playlist cover (custom file path or preset URI)
  Future<void> updatePlaylistCover(int id, String? coverUri) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(coverUri: Value(coverUri), updatedAt: Value(now)),
    );
  }

  /// Delete a playlist and its associated track links
  Future<void> deletePlaylist(int id) async {
    await transaction(() async {
      await (delete(
        playlistTracks,
      )..where((pt) => pt.playlistId.equals(id))).go();
      await (delete(playlists)..where((p) => p.id.equals(id))).go();
    });
  }

  /// Duplicate a playlist
  Future<int> duplicatePlaylist(int id) async {
    final source = await getPlaylist(id);
    if (source == null) return -1;
    final trackKeys = await getPlaylistTrackKeys(id);
    final newId = await createPlaylist(
      name: '${source.name} (Copy)',
      description: source.description,
      isSmart: source.isSmart,
      rulesJson: source.rulesJson,
      coverUri: source.coverUri,
    );
    if (trackKeys.isNotEmpty) {
      await addTracksToPlaylist(newId, trackKeys);
    }
    return newId;
  }

  /// Watch tracks belonging to a playlist in order
  Stream<List<Track>> watchPlaylistTracks(int playlistId) {
    final query =
        select(playlistTracks).join([
            innerJoin(
              tracks,
              tracks.trackKey.equalsExp(playlistTracks.trackKey),
            ),
          ])
          ..where(playlistTracks.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistTracks.position)]);

    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(tracks)).toList(),
    );
  }

  /// Get track keys for a playlist in order
  Future<List<String>> getPlaylistTrackKeys(int playlistId) async {
    final rows =
        await (select(playlistTracks)
              ..where((pt) => pt.playlistId.equals(playlistId))
              ..orderBy([(pt) => OrderingTerm.asc(pt.position)]))
            .get();
    return rows.map((r) => r.trackKey).toList();
  }

  /// Get tracks for a playlist
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final query =
        select(playlistTracks).join([
            innerJoin(
              tracks,
              tracks.trackKey.equalsExp(playlistTracks.trackKey),
            ),
          ])
          ..where(playlistTracks.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistTracks.position)]);
    final rows = await query.get();
    return rows.map((r) => r.readTable(tracks)).toList();
  }

  /// Get tracks for an album
  Future<List<Track>> getTracksForAlbum(int albumId) async {
    return (select(tracks)
          ..where((t) => t.albumId.equals(albumId) & t.isHidden.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.trackNo),
            (t) => OrderingTerm.asc(t.title),
          ]))
        .get();
  }

  /// Get tracks for an artist
  Future<List<Track>> getTracksForArtist(int artistId) async {
    return (select(tracks)
          ..where((t) => t.artistId.equals(artistId) & t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .get();
  }

  /// Get liked tracks
  Future<List<Track>> getLikedTracks() async {
    return (select(tracks)
          ..where((t) => t.isFavorite.equals(true) & t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)]))
        .get();
  }

  /// Get recently played tracks
  Future<List<Track>> getRecentlyPlayedTracks({int limit = 25}) async {
    return (select(tracks)
          ..where((t) => t.lastPlayedAt.isNotNull() & t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
          ..limit(limit))
        .get();
  }

  /// Add tracks to a playlist
  Future<void> addTracksToPlaylist(
    int playlistId,
    List<String> trackKeys,
  ) async {
    if (trackKeys.isEmpty) return;
    await transaction(() async {
      final currentMaxPosRow =
          await (select(playlistTracks)
                ..where((pt) => pt.playlistId.equals(playlistId))
                ..orderBy([(pt) => OrderingTerm.desc(pt.position)])
                ..limit(1))
              .getSingleOrNull();
      var nextPos = (currentMaxPosRow?.position ?? -1) + 1;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      for (final key in trackKeys) {
        await into(playlistTracks).insert(
          PlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackKey: key,
            position: nextPos++,
            addedAt: now,
          ),
        );
      }

      await (update(playlists)..where((p) => p.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(now)),
      );
    });
  }

  /// Remove track from a playlist (removes single occurrence by position/id)
  Future<void> removeTrackFromPlaylist(int playlistId, String trackKey) async {
    await transaction(() async {
      final target =
          await (select(playlistTracks)
                ..where(
                  (pt) =>
                      pt.playlistId.equals(playlistId) &
                      pt.trackKey.equals(trackKey),
                )
                ..orderBy([(pt) => OrderingTerm.asc(pt.position)])
                ..limit(1))
              .getSingleOrNull();

      if (target != null) {
        await (delete(
          playlistTracks,
        )..where((pt) => pt.id.equals(target.id))).go();
      }

      // Compact positions
      final remaining =
          await (select(playlistTracks)
                ..where((pt) => pt.playlistId.equals(playlistId))
                ..orderBy([(pt) => OrderingTerm.asc(pt.position)]))
              .get();
      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].position != i) {
          await (update(playlistTracks)
                ..where((pt) => pt.id.equals(remaining[i].id)))
              .write(PlaylistTracksCompanion(position: Value(i)));
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await (update(playlists)..where((p) => p.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(now)),
      );
    });
  }

  /// Reorder tracks inside a playlist
  Future<void> reorderPlaylistTracks(
    int playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    await transaction(() async {
      final list =
          await (select(playlistTracks)
                ..where((pt) => pt.playlistId.equals(playlistId))
                ..orderBy([(pt) => OrderingTerm.asc(pt.position)]))
              .get();

      if (oldIndex < 0 ||
          oldIndex >= list.length ||
          newIndex < 0 ||
          newIndex >= list.length) {
        return;
      }
      if (oldIndex == newIndex) return;

      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);

      for (var i = 0; i < list.length; i++) {
        await (update(playlistTracks)..where((pt) => pt.id.equals(list[i].id)))
            .write(PlaylistTracksCompanion(position: Value(i)));
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await (update(playlists)..where((p) => p.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(now)),
      );
    });
  }

  /// Record completed listen: increment playCount, update lastPlayedAt, insert history
  Future<void> recordPlayCompleted(
    String trackKey, {
    int listenedMs = 0,
    String? source,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await transaction(() async {
      final track = await getTrackByKey(trackKey);
      if (track != null) {
        await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
          TracksCompanion(
            playCount: Value(track.playCount + 1),
            lastPlayedAt: Value(now),
          ),
        );
      }
      await into(playHistory).insert(
        PlayHistoryCompanion.insert(
          trackKey: trackKey,
          startedAt: now - (listenedMs ~/ 1000),
          listenedMs: listenedMs,
          completed: const Value(true),
          source: Value(source),
        ),
      );
    });
  }

  /// Record track skipped early: increment skipCount
  Future<void> recordSkip(String trackKey) async {
    final track = await getTrackByKey(trackKey);
    if (track != null) {
      await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
        TracksCompanion(skipCount: Value(track.skipCount + 1)),
      );
    }
  }

  /// Watch top tracks by play count
  Stream<List<Track>> watchTopTracks({int limit = 15}) {
    return (select(tracks)
          ..where(
            (t) => t.playCount.isBiggerThanValue(0) & t.isHidden.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
          ..limit(limit))
        .watch();
  }

  /// Get all play history items within an optional epoch timestamp range
  Future<List<PlayHistoryData>> getPlayHistoryInRange({
    int? startEpochSeconds,
    int? endEpochSeconds,
  }) {
    final query = select(playHistory);
    if (startEpochSeconds != null) {
      query.where((ph) => ph.startedAt.isBiggerOrEqualValue(startEpochSeconds));
    }
    if (endEpochSeconds != null) {
      query.where((ph) => ph.startedAt.isSmallerOrEqualValue(endEpochSeconds));
    }
    return (query..orderBy([(ph) => OrderingTerm.desc(ph.startedAt)])).get();
  }

  /// Watch recently played tracks
  Stream<List<Track>> watchRecentlyPlayedTracks({int limit = 20}) {
    return (select(tracks)
          ..where((t) => t.lastPlayedAt.isNotNull() & t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
          ..limit(limit))
        .watch();
  }

  /// Watch recently added tracks
  Stream<List<Track>> watchRecentlyAddedTracks({int limit = 20}) {
    return (select(tracks)
          ..where((t) => t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])
          ..limit(limit))
        .watch();
  }

  /// Watch top artists based on track play counts
  Stream<List<Artist>> watchTopArtists({int limit = 10}) {
    final query =
        select(artists)
            .join([innerJoin(tracks, tracks.artistId.equalsExp(artists.id))])
          ..groupBy([artists.id])
          ..orderBy([OrderingTerm.desc(tracks.playCount.sum())])
          ..limit(limit);

    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(artists)).toList(),
    );
  }

  /// Search albums by query string
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(albums)
          ..where((a) => a.titleSort.like(pattern))
          ..limit(limit))
        .get();
  }

  /// Search artists by query string
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(artists)
          ..where((a) => a.nameSort.like(pattern))
          ..limit(limit))
        .get();
  }

  /// Get all artists
  Future<List<Artist>> getAllArtists() {
    return (select(
      artists,
    )..orderBy([(a) => OrderingTerm.asc(a.nameSort)])).get();
  }

  /// Get all albums
  Future<List<Album>> getAllAlbums() {
    return (select(
      albums,
    )..orderBy([(a) => OrderingTerm.asc(a.titleSort)])).get();
  }

  /// Search playlists by query string
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20}) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(playlists)
          ..where((p) => p.name.lower().like(pattern))
          ..limit(limit))
        .get();
  }

  /// Persist current queue state
  Future<void> saveQueueState({
    required String? currentTrackKey,
    required int positionMs,
    required bool shuffle,
    required int repeatMode,
    required int seed,
    required String queueJson,
  }) async {
    await into(queueStateTable).insertOnConflictUpdate(
      QueueStateTableCompanion(
        id: const Value(1),
        currentTrackKey: Value(currentTrackKey),
        positionMs: Value(positionMs),
        shuffle: Value(shuffle),
        repeatMode: Value(repeatMode),
        seed: Value(seed),
        queueJson: Value(queueJson),
      ),
    );
  }

  /// Retrieve saved queue state
  Future<QueueStateTableData?> getQueueState() {
    return (select(
      queueStateTable,
    )..where((q) => q.id.equals(1))).getSingleOrNull();
  }

  /// Get app setting by key
  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.valueJson;
  }

  /// Save or update app setting by key
  Future<void> setSetting(String key, String valueJson) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), valueJson: Value(valueJson)),
    );
  }

  /// Watch app setting changes by key
  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.valueJson);
  }

  /// Set track hidden state
  Future<void> setTrackHidden(String trackKey, bool isHidden) async {
    await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
      TracksCompanion(isHidden: Value(isHidden)),
    );
  }

  /// Delete track completely from database
  Future<void> deleteTrack(String trackKey) async {
    await transaction(() async {
      await (delete(
        playlistTracks,
      )..where((pt) => pt.trackKey.equals(trackKey))).go();
      await (delete(tracks)..where((t) => t.trackKey.equals(trackKey))).go();
      await customStatement('DELETE FROM tracks_fts WHERE track_key = ?;', [
        trackKey,
      ]);
    });
  }

  /// Get all active (or all) tracks for duplicates & backup
  Future<List<Track>> getAllTracks({bool includeHidden = false}) {
    if (includeHidden) {
      return (select(
        tracks,
      )..orderBy([(t) => OrderingTerm.asc(t.titleSort)])).get();
    }
    return (select(tracks)
          ..where((t) => t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.titleSort)]))
        .get();
  }

  /// Get all active track keys without materializing full Track models
  Future<List<String>> getAllTrackKeys({bool includeHidden = false}) async {
    final query = selectOnly(tracks)..addColumns([tracks.trackKey]);
    if (!includeHidden) {
      query.where(tracks.isHidden.equals(false));
    }
    query.orderBy([OrderingTerm.asc(tracks.titleSort)]);
    final rows = await query.get();
    return rows.map((r) => r.read(tracks.trackKey)!).toList();
  }

  /// Get targeted ID and MediaStore ID pairs for fast reconciliation
  Future<List<(int id, int mediaStoreId)>> getMediaStoreTrackIds() async {
    final query = selectOnly(tracks)
      ..addColumns([tracks.id, tracks.mediaStoreId])
      ..where(tracks.mediaStoreId.isNotNull());
    final rows = await query.get();
    return rows.map((r) {
      return (r.read(tracks.id)!, r.read(tracks.mediaStoreId)!);
    }).toList();
  }

  /// Get all playlists for backup
  Future<List<Playlist>> getAllPlaylists() {
    return select(playlists).get();
  }

  /// Get all playlist track entries for backup
  Future<List<PlaylistTrack>> getAllPlaylistTracks() {
    return select(playlistTracks).get();
  }

  /// Get all play history entries for backup
  Future<List<PlayHistoryData>> getAllPlayHistory() {
    return select(playHistory).get();
  }

  /// Get all app settings for backup
  Future<List<AppSetting>> getAllSettings() {
    return select(appSettings).get();
  }

  /// Debug-only synthetic data seeder for 20,000 tracks
  Future<void> seedSyntheticData({int count = 20000}) async {
    await transaction(() async {
      // Create sample artists
      final artistIds = <int>[];
      for (var i = 1; i <= 50; i++) {
        final id = await into(artists).insert(
          ArtistsCompanion.insert(
            name: 'Synthetic Artist $i',
            nameSort: 'synthetic artist $i',
          ),
          mode: InsertMode.insertOrIgnore,
        );
        artistIds.add(id);
      }

      // Create sample albums
      final albumIds = <int>[];
      for (var i = 1; i <= 100; i++) {
        final artistId = artistIds[i % artistIds.length];
        final id = await into(albums).insert(
          AlbumsCompanion.insert(
            title: 'Synthetic Album $i',
            titleSort: 'synthetic album $i',
            albumArtistId: Value(artistId),
            year: Value(2000 + (i % 25)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        albumIds.add(id);
      }

      // Chunk inserts in batches of 500
      const batchSize = 500;
      for (var chunk = 0; chunk < count; chunk += batchSize) {
        final end = (chunk + batchSize < count) ? chunk + batchSize : count;
        final trackBatch = <TracksCompanion>[];
        for (var i = chunk + 1; i <= end; i++) {
          final artistId = artistIds[i % artistIds.length];
          final albumId = albumIds[i % albumIds.length];
          final trackKey =
              'synthetic_track_key_${i.toString().padLeft(6, '0')}';

          trackBatch.add(
            TracksCompanion.insert(
              trackKey: trackKey,
              contentUri: 'content://media/external/audio/media/$i',
              path: '/storage/emulated/0/Music/synthetic_$i.mp3',
              relativeDir: const Value('Music'),
              title: 'Synthetic Track $i',
              titleSort: 'synthetic track $i',
              artistId: Value(artistId),
              albumId: Value(albumId),
              trackNo: Value((i % 12) + 1),
              discNo: const Value(1),
              year: Value(2000 + (i % 25)),
              durationMs: 180000 + (i % 60000),
              sizeBytes: 5000000 + (i * 100),
            ),
          );
        }
        await batch((b) {
          b.insertAll(tracks, trackBatch, mode: InsertMode.insertOrReplace);
        });
      }
    });
  }

  /// Get or create artist by name
  Future<int> getOrCreateArtist(String name) async {
    final existing = await (select(
      artists,
    )..where((a) => a.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    try {
      return await into(artists).insert(
        ArtistsCompanion(
          name: Value(name),
          nameSort: Value(MetadataUtils.normalizeSortName(name)),
        ),
      );
    } catch (_) {
      final fallback = await (select(
        artists,
      )..where((a) => a.name.equals(name))).getSingleOrNull();
      if (fallback != null) return fallback.id;
      rethrow;
    }
  }

  /// Get or create album by title and artist
  Future<int> getOrCreateAlbum({
    required String title,
    required int artistId,
    int? year,
    String? artworkKey,
  }) async {
    final existing =
        await (select(albums)..where(
              (a) => a.title.equals(title) & a.albumArtistId.equals(artistId),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    // Check if album already exists under 'Various Artists'
    final variousArtist = await (select(
      artists,
    )..where((a) => a.name.equals('Various Artists'))).getSingleOrNull();
    if (variousArtist != null) {
      final variousAlbum =
          await (select(albums)..where(
                (a) =>
                    a.title.equals(title) &
                    a.albumArtistId.equals(variousArtist.id),
              ))
              .getSingleOrNull();
      if (variousAlbum != null) return variousAlbum.id;
    }

    try {
      return await into(albums).insert(
        AlbumsCompanion(
          title: Value(title),
          titleSort: Value(MetadataUtils.normalizeSortName(title)),
          albumArtistId: Value(artistId),
          year: Value(year),
          artworkKey: Value(artworkKey),
        ),
      );
    } catch (_) {
      final fallback =
          await (select(albums)..where(
                (a) => a.title.equals(title) & a.albumArtistId.equals(artistId),
              ))
              .getSingleOrNull();
      if (fallback != null) return fallback.id;
      rethrow;
    }
  }

  /// Get or create genre by name
  Future<int> getOrCreateGenre(String name) async {
    final existing = await (select(
      genres,
    )..where((g) => g.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    try {
      return await into(genres).insert(GenresCompanion(name: Value(name)));
    } catch (_) {
      final fallback = await (select(
        genres,
      )..where((g) => g.name.equals(name))).getSingleOrNull();
      if (fallback != null) return fallback.id;
      rethrow;
    }
  }

  /// Get list of genre names for a track
  Future<List<String>> getTrackGenres(int trackId) async {
    final query = select(trackGenres).join([
      innerJoin(genres, genres.id.equalsExp(trackGenres.genreId)),
    ])..where(trackGenres.trackId.equals(trackId));

    final rows = await query.get();
    return rows.map((r) => r.readTable(genres).name).toList();
  }

  /// Get a map of track ID to list of genre names for all tracks
  Future<Map<int, List<String>>> getAllTrackGenresMap() async {
    final query = select(trackGenres)
        .join([innerJoin(genres, genres.id.equalsExp(trackGenres.genreId))]);
    final rows = await query.get();
    final map = <int, List<String>>{};
    for (final r in rows) {
      final trackId = r.readTable(trackGenres).trackId;
      final genreName = r.readTable(genres).name;
      map.putIfAbsent(trackId, () => []).add(genreName);
    }
    return map;
  }

  /// Get a genre by its ID
  Future<Genre?> getGenreById(int id) {
    return (select(genres)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  /// Watch a genre by its ID
  Stream<Genre?> watchGenre(int id) {
    return (select(genres)..where((g) => g.id.equals(id))).watchSingleOrNull();
  }

  /// Watch all tracks belonging to a genre in alphabetical order
  Stream<List<Track>> watchTracksForGenre(int genreId) {
    final query =
        select(trackGenres)
            .join([innerJoin(tracks, tracks.id.equalsExp(trackGenres.trackId))])
          ..where(
            trackGenres.genreId.equals(genreId) & tracks.isHidden.equals(false),
          )
          ..orderBy([OrderingTerm.asc(tracks.titleSort)]);
    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(tracks)).toList(),
    );
  }

  /// Get all tracks belonging to a genre
  Future<List<Track>> getTracksForGenre(int genreId) async {
    final query =
        select(trackGenres)
            .join([innerJoin(tracks, tracks.id.equalsExp(trackGenres.trackId))])
          ..where(
            trackGenres.genreId.equals(genreId) & tracks.isHidden.equals(false),
          )
          ..orderBy([OrderingTerm.asc(tracks.titleSort)]);
    final rows = await query.get();
    return rows.map((r) => r.readTable(tracks)).toList();
  }

  /// Watch all genres with their track counts
  Stream<List<(Genre, int)>> watchGenresWithCount() {
    final countExp = trackGenres.trackId.count();
    final query =
        select(genres).join([
            leftOuterJoin(
              trackGenres,
              trackGenres.genreId.equalsExp(genres.id),
            ),
          ])
          ..addColumns([countExp])
          ..groupBy([genres.id])
          ..orderBy([OrderingTerm.asc(genres.name)]);

    return query.watch().map((rows) {
      return rows.map((r) {
        final genre = r.readTable(genres);
        final count = r.read(countExp) ?? 0;
        return (genre, count);
      }).toList();
    });
  }

  /// Watch distinct folders with song counts without loading full Track rows
  Stream<List<FolderSummary>> watchFolderSummaries() {
    final countExp = tracks.id.count();
    final query = selectOnly(tracks)
      ..addColumns([tracks.relativeDir, countExp])
      ..where(tracks.isHidden.equals(false))
      ..groupBy([tracks.relativeDir])
      ..orderBy([OrderingTerm.asc(tracks.relativeDir)]);

    return query.watch().map((rows) {
      return rows.map((r) {
        final dir = r.read(tracks.relativeDir) ?? '';
        final count = r.read(countExp) ?? 0;
        return FolderSummary(
          path: dir.isNotEmpty ? dir : 'Root',
          trackCount: count,
        );
      }).toList();
    });
  }

  /// Watch all tracks belonging to a folder (relative directory)
  Stream<List<Track>> watchTracksForFolder(String folderPath) {
    final isRoot = folderPath == 'Root' || folderPath.isEmpty;
    return (select(tracks)
          ..where((t) {
            if (isRoot) {
              return (t.relativeDir.equals('') | t.relativeDir.equals('Root')) &
                  t.isHidden.equals(false);
            }
            return t.relativeDir.equals(folderPath) & t.isHidden.equals(false);
          })
          ..orderBy([(t) => OrderingTerm.asc(t.titleSort)]))
        .watch();
  }

  /// Get all tracks belonging to a folder (relative directory)
  Future<List<Track>> getTracksForFolder(String folderPath) async {
    final isRoot = folderPath == 'Root' || folderPath.isEmpty;
    return (select(tracks)
          ..where((t) {
            if (isRoot) {
              return (t.relativeDir.equals('') | t.relativeDir.equals('Root')) &
                  t.isHidden.equals(false);
            }
            return t.relativeDir.equals(folderPath) & t.isHidden.equals(false);
          })
          ..orderBy([(t) => OrderingTerm.asc(t.titleSort)]))
        .get();
  }

  /// Watch single album by ID
  Stream<Album?> watchAlbum(int albumId) {
    return (select(
      albums,
    )..where((a) => a.id.equals(albumId))).watchSingleOrNull();
  }

  /// Watch album tracks ordered by disc, track number, and title
  Stream<List<Track>> watchAlbumTracks(int albumId) {
    return (select(tracks)
          ..where((t) => t.albumId.equals(albumId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.discNo),
            (t) => OrderingTerm.asc(t.trackNo),
            (t) => OrderingTerm.asc(t.titleSort),
          ]))
        .watch();
  }

  /// Watch single artist by ID
  Stream<Artist?> watchArtist(int artistId) {
    return (select(
      artists,
    )..where((a) => a.id.equals(artistId))).watchSingleOrNull();
  }

  /// Watch artist tracks ordered by play count and title
  Stream<List<Track>> watchArtistTracks(int artistId) {
    return (select(tracks)
          ..where((t) => t.artistId.equals(artistId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.playCount),
            (t) => OrderingTerm.asc(t.titleSort),
          ]))
        .watch();
  }

  /// Watch artist albums ordered by release year
  Stream<List<Album>> watchArtistAlbums(int artistId) {
    return (select(albums)
          ..where((a) => a.albumArtistId.equals(artistId))
          ..orderBy([(a) => OrderingTerm.desc(a.year)]))
        .watch();
  }

  /// Updates track metadata across tracks, artists, albums, and FTS5 index
  Future<void> updateTrackMetadata({
    required String trackKey,
    required String title,
    required String artist,
    required String album,
    int? year,
    int? trackNo,
    int? discNo,
    String? genre,
    String? artworkKey,
  }) async {
    await transaction(() async {
      final currentTrack = await (select(
        tracks,
      )..where((t) => t.trackKey.equals(trackKey))).getSingleOrNull();
      if (currentTrack == null) return;

      final artistId = await getOrCreateArtist(artist);
      final albumId = await getOrCreateAlbum(
        title: album,
        artistId: artistId,
        year: year,
        artworkKey: artworkKey ?? currentTrack.artworkKey,
      );

      await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
        TracksCompanion(
          title: Value(title),
          titleSort: Value(MetadataUtils.normalizeSortName(title)),
          artistId: Value(artistId),
          albumId: Value(albumId),
          albumArtistId: Value(artistId),
          year: Value(year),
          trackNo: Value(trackNo),
          discNo: Value(discNo),
          artworkKey: artworkKey != null
              ? Value(artworkKey)
              : const Value.absent(),
        ),
      );

      if (genre != null && genre.trim().isNotEmpty) {
        final genreId = await getOrCreateGenre(genre.trim());
        await into(trackGenres).insertOnConflictUpdate(
          TrackGenresCompanion(
            trackId: Value(currentTrack.id),
            genreId: Value(genreId),
          ),
        );
      }

      await customStatement(
        'INSERT OR REPLACE INTO tracks_fts(track_key, title, artist, album, genre) VALUES (?, ?, ?, ?, ?)',
        [trackKey, title, artist, album, genre ?? ''],
      );
    });
  }

  /// Updates or resets the artwork key / custom cover URI for a single track
  Future<void> updateTrackArtwork(String trackKey, String? artworkKey) async {
    await (update(tracks)..where((t) => t.trackKey.equals(trackKey))).write(
      TracksCompanion(artworkKey: Value(artworkKey)),
    );
  }

  /// Imports virtual tracks parsed from a CUE sheet
  Future<List<String>> importCueTracks({
    required String audioPath,
    required String contentUri,
    required List<CueTrack> cueTracks,
    String? artworkKey,
    int? parentMediaStoreId,
    int? parentFileSize,
  }) async {
    final importedKeys = <String>[];
    await transaction(() async {
      for (final ct in cueTracks) {
        final artistId = await getOrCreateArtist(ct.artist);
        final albumId = await getOrCreateAlbum(
          title: ct.album,
          artistId: artistId,
          artworkKey: artworkKey,
        );

        final cueTrackKey = TrackKeyUtil.generate(
          title: ct.title,
          artist: ct.artist,
          album: ct.album,
          durationMs: ct.duration?.inMilliseconds ?? 0,
          sizeBytes: parentFileSize ?? 0,
        );

        await into(tracks).insertOnConflictUpdate(
          TracksCompanion(
            trackKey: Value(cueTrackKey),
            mediaStoreId: Value(parentMediaStoreId),
            contentUri: Value(contentUri),
            path: Value(audioPath),
            relativeDir: Value(p.dirname(audioPath)),
            title: Value(ct.title),
            titleSort: Value(MetadataUtils.normalizeSortName(ct.title)),
            artistId: Value(artistId),
            albumId: Value(albumId),
            albumArtistId: Value(artistId),
            trackNo: Value(ct.trackNumber),
            durationMs: Value(ct.duration?.inMilliseconds ?? 0),
            sizeBytes: Value(parentFileSize ?? 0),
            artworkKey: Value(artworkKey),
            cueStartMs: Value(ct.startTime.inMilliseconds),
            cueEndMs: Value(ct.endTime?.inMilliseconds),
          ),
        );

        await customStatement(
          'INSERT OR REPLACE INTO tracks_fts(track_key, title, artist, album, genre) VALUES (?, ?, ?, ?, ?)',
          [cueTrackKey, ct.title, ct.artist, ct.album, ''],
        );

        importedKeys.add(cueTrackKey);
      }
    });
    return importedKeys;
  }
}
