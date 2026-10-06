import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/cue_parser.dart';
import 'package:sonara/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('importCueTracks inserts virtual tracks into database with cueStartMs and cueEndMs', () async {
    final cueTracks = [
      const CueTrack(
        trackNumber: 1,
        title: 'Shine On You Crazy Diamond (Parts I–V)',
        artist: 'Pink Floyd',
        album: 'Wish You Were Here',
        startTime: Duration.zero,
        endTime: Duration(minutes: 13, seconds: 32),
      ),
      const CueTrack(
        trackNumber: 2,
        title: 'Welcome to the Machine',
        artist: 'Pink Floyd',
        album: 'Wish You Were Here',
        startTime: Duration(minutes: 13, seconds: 32),
        endTime: Duration(minutes: 21, seconds: 0),
      ),
    ];

    final keys = await db.importCueTracks(
      audioPath: '/storage/emulated/0/Music/Wish You Were Here.flac',
      contentUri: 'content://media/external/audio/media/999',
      cueTracks: cueTracks,
      parentMediaStoreId: 999,
      parentFileSize: 350000000,
    );

    expect(keys.length, 2);

    final track1 = await db.getTrackByKey(keys[0]);
    expect(track1, isNotNull);
    expect(track1!.title, 'Shine On You Crazy Diamond (Parts I–V)');
    expect(track1.cueStartMs, 0);
    expect(
      track1.cueEndMs,
      const Duration(minutes: 13, seconds: 32).inMilliseconds,
    );
    expect(track1.path, '/storage/emulated/0/Music/Wish You Were Here.flac');

    final track2 = await db.getTrackByKey(keys[1]);
    expect(track2, isNotNull);
    expect(track2!.title, 'Welcome to the Machine');
    expect(
      track2.cueStartMs,
      const Duration(minutes: 13, seconds: 32).inMilliseconds,
    );
    expect(
      track2.cueEndMs,
      const Duration(minutes: 21, seconds: 0).inMilliseconds,
    );

    // Verify FTS search finds the virtual track
    final ftsResults = await db.searchTracksFts('Machine');
    expect(ftsResults.length, 1);
    expect(ftsResults.first.title, 'Welcome to the Machine');
  });

  test(
    'updateTrackMetadata updates track, album, and artist info in database',
    () async {
      final initialKeys = await db.importCueTracks(
        audioPath: '/storage/emulated/0/Music/test.mp3',
        contentUri: 'content://media/external/audio/media/1',
        cueTracks: [
          const CueTrack(
            trackNumber: 1,
            title: 'Old Title',
            artist: 'Old Artist',
            album: 'Old Album',
            startTime: Duration.zero,
          ),
        ],
      );

      final trackKey = initialKeys.first;

      await db.updateTrackMetadata(
        trackKey: trackKey,
        title: 'New Master Title',
        artist: 'New Super Artist',
        album: 'New Legendary Album',
        year: 2024,
        trackNo: 5,
        discNo: 1,
        genre: 'Progressive Metal',
      );

      final updated = await db.getTrackByKey(trackKey);
      expect(updated, isNotNull);
      expect(updated!.title, 'New Master Title');
      expect(updated.year, 2024);
      expect(updated.trackNo, 5);
      expect(updated.discNo, 1);

      final artistName = await db.getArtistName(updated.artistId);
      expect(artistName, 'New Super Artist');

      final genres = await db.getTrackGenres(updated.id);
      expect(genres, contains('Progressive Metal'));
    },
  );
}
