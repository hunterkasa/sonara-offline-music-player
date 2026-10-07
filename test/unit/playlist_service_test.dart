import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/playlist_service.dart';

void main() {
  late AppDatabase db;
  late PlaylistService playlistService;

  setUp(() async {
    db = AppDatabase.inMemory();
    playlistService = PlaylistService(db);

    // Insert dummy tracks
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_1',
            contentUri: 'content://audio/1',
            path: '/music/track1.mp3',
            relativeDir: const Value('music'),
            title: 'Track One',
            titleSort: 'track one',
            durationMs: 180000,
            sizeBytes: 3000000,
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_2',
            contentUri: 'content://audio/2',
            path: '/music/track2.mp3',
            relativeDir: const Value('music'),
            title: 'Track Two',
            titleSort: 'track two',
            durationMs: 200000,
            sizeBytes: 4000000,
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_3',
            contentUri: 'content://audio/3',
            path: '/music/track3.mp3',
            relativeDir: const Value('music'),
            title: 'Track Three',
            titleSort: 'track three',
            durationMs: 220000,
            sizeBytes: 5000000,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('PlaylistService CRUD & Reordering Tests', () {
    test('createPlaylist creates and stores a new playlist', () async {
      final id = await playlistService.createPlaylist(name: 'My Favorites');
      expect(id, isPositive);

      final playlist = await playlistService.getPlaylist(id);
      expect(playlist, isNotNull);
      expect(playlist!.name, equals('My Favorites'));
      expect(playlist.isSmart, isFalse);
    });

    test('renamePlaylist updates playlist title', () async {
      final id = await playlistService.createPlaylist(name: 'Old Name');
      await playlistService.renamePlaylist(id, 'New Name');

      final playlist = await playlistService.getPlaylist(id);
      expect(playlist!.name, equals('New Name'));
    });

    test('deletePlaylist removes playlist and its associated tracks', () async {
      final id = await playlistService.createPlaylist(name: 'To Delete');
      await playlistService.addTracksToPlaylist(id, ['track_1', 'track_2']);

      final tracksBefore = await playlistService.getPlaylistTrackKeys(id);
      expect(tracksBefore.length, equals(2));

      await playlistService.deletePlaylist(id);
      final playlist = await playlistService.getPlaylist(id);
      expect(playlist, isNull);

      final tracksAfter = await playlistService.getPlaylistTrackKeys(id);
      expect(tracksAfter, isEmpty);
    });

    test(
      'duplicatePlaylist creates a full copy of the playlist and track entries',
      () async {
        final id = await playlistService.createPlaylist(name: 'Original');
        await playlistService.addTracksToPlaylist(id, ['track_1', 'track_2']);

        final dupId = await playlistService.duplicatePlaylist(id);
        expect(dupId, isNot(equals(id)));

        final dupPlaylist = await playlistService.getPlaylist(dupId);
        expect(dupPlaylist!.name, equals('Original (Copy)'));

        final dupTracks = await playlistService.getPlaylistTrackKeys(dupId);
        expect(dupTracks, equals(['track_1', 'track_2']));
      },
    );

    test(
      'addTracksToPlaylist and removeTrackFromPlaylist manage tracks correctly',
      () async {
        final id = await playlistService.createPlaylist(name: 'Track Test');
        await playlistService.addTracksToPlaylist(id, ['track_1', 'track_2']);

        var keys = await playlistService.getPlaylistTrackKeys(id);
        expect(keys, equals(['track_1', 'track_2']));

        await playlistService.removeTrackFromPlaylist(id, 'track_1');
        keys = await playlistService.getPlaylistTrackKeys(id);
        expect(keys, equals(['track_2']));
      },
    );

    test('reorderTracks updates positions cleanly', () async {
      final id = await playlistService.createPlaylist(name: 'Reorder Test');
      await playlistService.addTracksToPlaylist(id, [
        'track_1',
        'track_2',
        'track_3',
      ]);

      var keys = await playlistService.getPlaylistTrackKeys(id);
      expect(keys, equals(['track_1', 'track_2', 'track_3']));

      // Move track_1 (index 0) to position 1 (after track_2)
      await playlistService.reorderTracks(id, 0, 1);
      keys = await playlistService.getPlaylistTrackKeys(id);
      expect(keys, equals(['track_2', 'track_1', 'track_3']));

      // Move track_3 (index 2) to position 0 (beginning)
      await playlistService.reorderTracks(id, 2, 0);
      keys = await playlistService.getPlaylistTrackKeys(id);
      expect(keys, equals(['track_3', 'track_2', 'track_1']));
    });
  });
}
