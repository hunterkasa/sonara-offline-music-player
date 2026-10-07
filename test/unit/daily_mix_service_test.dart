import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/daily_mix_service.dart';
import 'package:sonara/domain/services/playlist_service.dart';
import 'package:sonara/domain/services/track_radio_service.dart';

class MockPlaybackController extends StubPlaybackController {
  List<String> lastPlayedQueue = [];
  int lastInitialIndex = -1;

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    lastPlayedQueue = trackKeys;
    lastInitialIndex = initialIndex;
  }
}

void main() {
  late AppDatabase db;
  late MockPlaybackController playback;
  late TrackRadioService radioService;
  late DailyMixService dailyMixService;
  late PlaylistService playlistService;

  setUp(() {
    db = AppDatabase.inMemory();
    playback = MockPlaybackController();
    radioService = TrackRadioService(db: db, playbackController: playback);
    dailyMixService = DailyMixService(db: db, radioService: radioService);
    playlistService = PlaylistService(db, dailyMixService);
  });

  tearDown(() async {
    await db.close();
  });

  group('DailyMixService - Today\'s Pick', () {
    test('returns null when library is empty', () async {
      final pick = await dailyMixService.getTodaysPick();
      expect(pick, isNull);
    });

    test('picks deterministically by date', () async {
      final artistId = await db.getOrCreateArtist('Radiohead');
      final albumId = await db.getOrCreateAlbum(
        title: 'OK Computer',
        artistId: artistId,
      );

      for (var i = 1; i <= 5; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'track_$i',
                contentUri: 'content://track_$i',
                path: '/music/track_$i.mp3',
                title: 'Track $i',
                titleSort: 'track $i',
                artistId: drift.Value(artistId),
                albumId: drift.Value(albumId),
                durationMs: 200000,
                sizeBytes: 1000000,
              ),
            );
      }

      final dateA = DateTime(2026, 10, 7);
      final pick1 = await dailyMixService.getTodaysPick(date: dateA);
      final pick2 = await dailyMixService.getTodaysPick(date: dateA);

      expect(pick1, isNotNull);
      expect(pick2, isNotNull);
      expect(pick1!.track.trackKey, equals(pick2!.track.trackKey));
      expect(pick1.artistName, equals('Radiohead'));
      expect(pick1.albumTitle, equals('OK Computer'));
      expect(pick1.dateLabel, contains('Oct 7'));
    });

    test('prefers favorite or played tracks', () async {
      final artistId = await db.getOrCreateArtist('Pink Floyd');
      final albumId = await db.getOrCreateAlbum(
        title: 'The Wall',
        artistId: artistId,
      );

      // 4 normal tracks
      for (var i = 1; i <= 4; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'normal_$i',
                contentUri: 'content://normal_$i',
                path: '/music/normal_$i.mp3',
                title: 'Normal $i',
                titleSort: 'normal $i',
                artistId: drift.Value(artistId),
                albumId: drift.Value(albumId),
                durationMs: 200000,
                sizeBytes: 1000000,
              ),
            );
      }

      // 1 favorite track
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'fav_track',
              contentUri: 'content://fav_track',
              path: '/music/fav_track.mp3',
              title: 'Comfortably Numb',
              titleSort: 'comfortably numb',
              artistId: drift.Value(artistId),
              albumId: drift.Value(albumId),
              durationMs: 380000,
              sizeBytes: 5000000,
              isFavorite: const drift.Value(true),
            ),
          );

      final pick = await dailyMixService.getTodaysPick(
        date: DateTime(2026, 10, 7),
      );
      expect(pick, isNotNull);
      expect(pick!.track.trackKey, equals('fav_track'));
      expect(pick.reason, equals('From your favorites'));
    });
  });

  group('DailyMixService - Daily Mixes Clustering', () {
    test('returns empty list when library has 0 tracks', () async {
      final mixes = await dailyMixService.getDailyMixes();
      expect(mixes, isEmpty);
    });

    test('returns 1 mix for small library (<= 15 tracks)', () async {
      final artistId = await db.getOrCreateArtist('The Beatles');
      final albumId = await db.getOrCreateAlbum(
        title: 'Abbey Road',
        artistId: artistId,
      );

      for (var i = 1; i <= 5; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'beatles_$i',
                contentUri: 'content://beatles_$i',
                path: '/music/beatles_$i.mp3',
                title: 'Beatles Song $i',
                titleSort: 'beatles song $i',
                artistId: drift.Value(artistId),
                albumId: drift.Value(albumId),
                durationMs: 180000,
                sizeBytes: 1000000,
              ),
            );
      }

      final mixes = await dailyMixService.getDailyMixes();
      expect(mixes.length, equals(1));
      expect(mixes[0].id, equals(-101));
      expect(mixes[0].title, equals('Daily Mix 1'));
      expect(mixes[0].tracks.length, equals(5));
      expect(mixes[0].subtitle, contains('The Beatles'));
    });

    test('clusters into multiple mixes when multiple genres exist', () async {
      final rockArtist = await db.getOrCreateArtist('Led Zeppelin');
      final jazzArtist = await db.getOrCreateArtist('Miles Davis');
      final popArtist = await db.getOrCreateArtist('Dua Lipa');

      final rockAlbum = await db.getOrCreateAlbum(
        title: 'Led Zeppelin IV',
        artistId: rockArtist,
      );
      final jazzAlbum = await db.getOrCreateAlbum(
        title: 'Kind of Blue',
        artistId: jazzArtist,
      );
      final popAlbum = await db.getOrCreateAlbum(
        title: 'Future Nostalgia',
        artistId: popArtist,
      );

      final rockGenre = await db.getOrCreateGenre('Rock');
      final jazzGenre = await db.getOrCreateGenre('Jazz');
      final popGenre = await db.getOrCreateGenre('Pop');

      // Insert 6 Rock tracks
      for (var i = 1; i <= 6; i++) {
        final id = await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'rock_$i',
                contentUri: 'content://rock_$i',
                path: '/music/rock_$i.mp3',
                title: 'Rock Song $i',
                titleSort: 'rock song $i',
                artistId: drift.Value(rockArtist),
                albumId: drift.Value(rockAlbum),
                durationMs: 240000,
                sizeBytes: 2000000,
              ),
            );
        await db
            .into(db.trackGenres)
            .insert(
              TrackGenresCompanion.insert(trackId: id, genreId: rockGenre),
            );
      }

      // Insert 6 Jazz tracks
      for (var i = 1; i <= 6; i++) {
        final id = await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'jazz_$i',
                contentUri: 'content://jazz_$i',
                path: '/music/jazz_$i.mp3',
                title: 'Jazz Song $i',
                titleSort: 'jazz song $i',
                artistId: drift.Value(jazzArtist),
                albumId: drift.Value(jazzAlbum),
                durationMs: 300000,
                sizeBytes: 2500000,
              ),
            );
        await db
            .into(db.trackGenres)
            .insert(
              TrackGenresCompanion.insert(trackId: id, genreId: jazzGenre),
            );
      }

      // Insert 6 Pop tracks (total 18 tracks > 15)
      for (var i = 1; i <= 6; i++) {
        final id = await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'pop_$i',
                contentUri: 'content://pop_$i',
                path: '/music/pop_$i.mp3',
                title: 'Pop Song $i',
                titleSort: 'pop song $i',
                artistId: drift.Value(popArtist),
                albumId: drift.Value(popAlbum),
                durationMs: 200000,
                sizeBytes: 1800000,
              ),
            );
        await db
            .into(db.trackGenres)
            .insert(
              TrackGenresCompanion.insert(trackId: id, genreId: popGenre),
            );
      }

      final mixes = await dailyMixService.getDailyMixes(
        date: DateTime(2026, 10, 7),
      );
      expect(mixes.length, equals(3));
      expect(mixes[0].id, equals(-101));
      expect(mixes[1].id, equals(-102));
      expect(mixes[2].id, equals(-103));

      expect(mixes[0].title, equals('Daily Mix 1'));
      expect(mixes[1].title, equals('Daily Mix 2'));
      expect(mixes[2].title, equals('Daily Mix 3'));

      // Check lookup by ID
      final mixLookup = await dailyMixService.getDailyMixById(
        -101,
        date: DateTime(2026, 10, 7),
      );
      expect(mixLookup, isNotNull);
      expect(mixLookup!.id, equals(-101));
    });
  });

  group('PlaylistService Integration with Daily Mixes', () {
    test('PlaylistService resolves virtual daily mix by ID', () async {
      final artistId = await db.getOrCreateArtist('Adele');
      final albumId = await db.getOrCreateAlbum(
        title: '30',
        artistId: artistId,
      );

      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'adele_$i',
                contentUri: 'content://adele_$i',
                path: '/music/adele_$i.mp3',
                title: 'Easy On Me $i',
                titleSort: 'easy on me $i',
                artistId: drift.Value(artistId),
                albumId: drift.Value(albumId),
                durationMs: 220000,
                sizeBytes: 1500000,
              ),
            );
      }

      final playlist = await playlistService.getPlaylist(-101);
      expect(playlist, isNotNull);
      expect(playlist!.id, equals(-101));
      expect(playlist.name, equals('Daily Mix 1'));
      expect(playlist.isSmart, isTrue);

      final trackKeys = await playlistService.getPlaylistTrackKeys(-101);
      expect(trackKeys.length, equals(3));
      expect(trackKeys, contains('adele_1'));
    });
  });
}
