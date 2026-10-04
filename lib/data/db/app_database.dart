import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

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
  int get schemaVersion => 1;

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

  /// Observe all non-hidden tracks reactive stream
  Stream<List<Track>> watchAllTracks() {
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

  /// Full-text search using FTS5
  Future<List<String>> searchTrackKeysFts(String term) async {
    final cleanTerm = term.replaceAll('"', '""');
    final rows = await customSelect(
      'SELECT track_key FROM tracks_fts WHERE tracks_fts MATCH ?',
      variables: [Variable.withString('$cleanTerm*')],
    ).get();

    return rows.map((row) => row.read<String>('track_key')).toList();
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

  /// Get list of tracks matching given keys preserving order
  Future<List<Track>> getTracksByKeys(List<String> keys) async {
    if (keys.isEmpty) return [];
    final fetched = await (select(
      tracks,
    )..where((t) => t.trackKey.isIn(keys))).get();
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
}
