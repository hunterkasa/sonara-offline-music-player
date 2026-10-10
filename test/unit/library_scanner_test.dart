import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/services/permission_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/sources/artwork_service.dart';
import 'package:sonara/data/sources/mediastore_source.dart';
import 'package:sonara/domain/services/library_scanner.dart';

class FakeMediaStoreSource implements MediaStoreSource {
  List<MediaStoreItem> items = [];
  List<int> knownIds = [];
  final StreamController<void> _observerController =
      StreamController<void>.broadcast();

  @override
  Future<List<MediaStoreItem>> queryAudioFiles({
    int minDurationMs = 30000,
    int modifiedSinceSec = 0,
  }) async {
    return items;
  }

  @override
  Future<List<int>> getKnownMediaIds() async {
    return knownIds;
  }

  @override
  Stream<void> observeMediaStore() => _observerController.stream;

  void dispose() {
    _observerController.close();
  }
}

class FakePermissionService implements PermissionService {
  AudioPermissionStatus status = AudioPermissionStatus.granted;

  @override
  Future<AudioPermissionStatus> checkAudioPermission() async => status;

  @override
  Future<AudioPermissionStatus> requestAudioPermission() async => status;

  @override
  Future<bool> checkNotificationPermission() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> openSettings() async => true;
}

void main() {
  group('LibraryScanner', () {
    late AppDatabase db;
    late FakeMediaStoreSource mediaStore;
    late FakePermissionService permissions;
    late ArtworkService artworkService;
    late LibraryScanner scanner;

    setUp(() {
      db = AppDatabase.inMemory();
      mediaStore = FakeMediaStoreSource();
      permissions = FakePermissionService();
      artworkService = ArtworkService();

      scanner = LibraryScanner(
        db: db,
        mediaStore: mediaStore,
        permissions: permissions,
        artworkService: artworkService,
      );
    });

    tearDown(() async {
      scanner.dispose();
      mediaStore.dispose();
      await db.close();
    });

    test('scans and indexes tracks into database', () async {
      mediaStore.items = [
        const MediaStoreItem(
          id: 101,
          contentUri: 'content://media/external/audio/media/101',
          albumArtUri: 'content://media/external/audio/albumart/1',
          title: 'Track One',
          artist: 'Artist A',
          album: 'Album X',
          durationMs: 180000,
          path: '/storage/emulated/0/Music/01.mp3',
          sizeBytes: 5000000,
          dateAdded: 1600000000,
          dateModified: 1600000000,
          albumId: 1,
          trackNumber: 1,
          mimeType: 'audio/mpeg',
          year: 2024,
        ),
        const MediaStoreItem(
          id: 102,
          contentUri: 'content://media/external/audio/media/102',
          albumArtUri: 'content://media/external/audio/albumart/1',
          title: 'Track Two',
          artist: 'Artist A',
          album: 'Album X',
          durationMs: 210000,
          path: '/storage/emulated/0/Music/02.mp3',
          sizeBytes: 6000000,
          dateAdded: 1600000000,
          dateModified: 1600000000,
          albumId: 1,
          trackNumber: 2,
          mimeType: 'audio/mpeg',
          year: 2024,
        ),
      ];
      mediaStore.knownIds = [101, 102];

      await scanner.scanLibrary(isFullScan: true);

      final tracks = await db.select(db.tracks).get();
      expect(tracks.length, 2);
      expect(tracks.first.title, 'Track One');
      expect(tracks.last.title, 'Track Two');

      final artists = await db.select(db.artists).get();
      expect(artists.length, 1);
      expect(artists.first.name, 'Artist A');

      final albums = await db.select(db.albums).get();
      expect(albums.length, 1);
      expect(albums.first.title, 'Album X');
    });

    test('handles denied permission without scanning', () async {
      permissions.status = AudioPermissionStatus.denied;
      await scanner.scanLibrary();

      final tracks = await db.select(db.tracks).get();
      expect(tracks, isEmpty);
      expect(scanner.state.isScanning, false);
    });

    test('reconciles deleted files during full scan', () async {
      // First scan: 2 tracks
      mediaStore.items = [
        const MediaStoreItem(
          id: 201,
          contentUri: 'content://media/external/audio/media/201',
          albumArtUri: '',
          title: 'Existing Track',
          artist: 'Artist',
          album: 'Album',
          durationMs: 120000,
          path: '/storage/emulated/0/Music/201.mp3',
          sizeBytes: 3000000,
          dateAdded: 1600000000,
          dateModified: 1600000000,
          albumId: 2,
          trackNumber: 1,
          mimeType: 'audio/mpeg',
          year: 2024,
        ),
      ];
      mediaStore.knownIds = [201];
      await scanner.scanLibrary(isFullScan: true);

      var tracks = await db.select(db.tracks).get();
      expect(tracks.length, 1);
      expect(tracks.first.isMissing, false);

      // Second scan: track 201 is no longer in known IDs (deleted)
      mediaStore.items = [];
      mediaStore.knownIds = [999]; // 201 missing
      await scanner.scanLibrary(isFullScan: true);

      tracks = await db.select(db.tracks).get();
      expect(tracks.length, 1);
      expect(tracks.first.isMissing, true);
    });

    test(
      'extracts and associates genres into genres and trackGenres tables',
      () async {
        mediaStore.items = [
          const MediaStoreItem(
            id: 301,
            contentUri: 'content://media/external/audio/media/301',
            albumArtUri: '',
            title: 'Rock Song',
            artist: 'Rock Band',
            album: 'Rock Album',
            durationMs: 150000,
            path: '/storage/emulated/0/Music/rock.mp3',
            sizeBytes: 4000000,
            dateAdded: 1600000000,
            dateModified: 1600000000,
            albumId: 3,
            trackNumber: 1,
            mimeType: 'audio/mpeg',
            year: 2024,
            genre: 'Rock',
          ),
          const MediaStoreItem(
            id: 302,
            contentUri: 'content://media/external/audio/media/302',
            albumArtUri: '',
            title: 'Jazz Song',
            artist: 'Jazz Band',
            album: 'Jazz Album',
            durationMs: 200000,
            path: '/storage/emulated/0/Music/jazz.mp3',
            sizeBytes: 5000000,
            dateAdded: 1600000000,
            dateModified: 1600000000,
            albumId: 4,
            trackNumber: 1,
            mimeType: 'audio/mpeg',
            year: 2024,
            genre: 'Jazz',
          ),
        ];
        mediaStore.knownIds = [301, 302];

        await scanner.scanLibrary(isFullScan: true);

        final genres = await db.select(db.genres).get();
        expect(genres.length, 2);
        expect(
          genres.map((g) => g.name).toSet(),
          containsAll({'Rock', 'Jazz'}),
        );

        final rockGenre = genres.firstWhere((g) => g.name == 'Rock');
        final rockTracks = await db.getTracksForGenre(rockGenre.id);
        expect(rockTracks.length, 1);
        expect(rockTracks.first.title, 'Rock Song');

        final genresWithCount = await db.watchGenresWithCount().first;
        expect(genresWithCount.length, 2);
        expect(genresWithCount.firstWhere((g) => g.$1.name == 'Rock').$2, 1);
      },
    );

    test(
      'handles empty, invalid, and relative paths without crashing',
      () async {
        mediaStore.items = [
          const MediaStoreItem(
            id: 401,
            contentUri: 'content://media/external/audio/media/401',
            albumArtUri: '',
            title: 'Empty Path Song',
            artist: 'Ghost Artist',
            album: 'Ghost Album',
            durationMs: 120000,
            path: '', // Scoped storage empty path
            sizeBytes: 1000000,
            dateAdded: 1600000000,
            dateModified: 1600000000,
            albumId: 5,
            trackNumber: 1,
            mimeType: 'audio/mpeg',
            year: 2024,
          ),
          const MediaStoreItem(
            id: 402,
            contentUri: 'content://media/external/audio/media/402',
            albumArtUri: '',
            title: 'Relative Path Song',
            artist: 'Ghost Artist',
            album: 'Ghost Album',
            durationMs: 140000,
            path: 'relative/sub/song.mp3', // Relative path
            sizeBytes: 1500000,
            dateAdded: 1600000000,
            dateModified: 1600000000,
            albumId: 5,
            trackNumber: 2,
            mimeType: 'audio/mpeg',
            year: 2024,
          ),
        ];
        mediaStore.knownIds = [401, 402];

        await scanner.scanLibrary(isFullScan: true);

        final tracks = await db.select(db.tracks).get();
        expect(tracks.length, 2);
        expect(
          tracks.map((t) => t.title),
          containsAll({'Empty Path Song', 'Relative Path Song'}),
        );
      },
    );

    test('handles non-Latin metadata and UTF-8 artwork keys safely', () async {
      mediaStore.items = [
        const MediaStoreItem(
          id: 501,
          contentUri: 'content://media/external/audio/media/501',
          albumArtUri: '',
          title: '夜に駆ける (Yoru ni Kakeru)',
          artist: 'YOASOBI - 幾田りら',
          album: 'THE BOOK - 音のアルバム',
          durationMs: 260000,
          path: '/storage/emulated/0/Music/yoasobi.mp3',
          sizeBytes: 8000000,
          dateAdded: 1600000000,
          dateModified: 1600000000,
          albumId: 6,
          trackNumber: 1,
          mimeType: 'audio/mpeg',
          year: 2021,
          genre: 'J-Pop',
        ),
      ];
      mediaStore.knownIds = [501];

      await scanner.scanLibrary(isFullScan: true);

      final tracks = await db.select(db.tracks).get();
      expect(tracks.length, 1);
      expect(tracks.first.title, '夜に駆ける (Yoru ni Kakeru)');

      // Verify artwork key with non-Latin text doesn't throw
      final key = ArtworkService.generateArtworkKey('YOASOBI - 幾田りら - 音のアルバム');
      expect(key, isNotEmpty);

      // Verify gradient fallback with extreme/negative seed
      final gradient = ArtworkService.generateGradientFallback(
        'extreme_seed_test_123',
      );
      expect(gradient.colors.length, 2);
    });

    test(
      'resets isMissing to false when previously missing track is rescanned',
      () async {
        mediaStore.items = [
          const MediaStoreItem(
            id: 601,
            contentUri: 'content://media/external/audio/media/601',
            albumArtUri: '',
            title: 'Restored Song',
            artist: 'Artist R',
            album: 'Album R',
            durationMs: 200000,
            path: '/storage/emulated/0/Music/restored.mp3',
            sizeBytes: 4000000,
            dateAdded: 1600000000,
            dateModified: 1600000000,
            albumId: 7,
            trackNumber: 1,
            mimeType: 'audio/mpeg',
            year: 2024,
          ),
        ];
        mediaStore.knownIds = [601];

        // Initial scan
        await scanner.scanLibrary(isFullScan: true);
        var track = (await db.select(db.tracks).get()).first;
        expect(track.isMissing, isFalse);

        // Simulate track missing (e.g. unmounted SD card)
        await db.markTrackMissing(track.trackKey);
        track = (await db.select(db.tracks).get()).first;
        expect(track.isMissing, isTrue);

        // Rescan with track present again
        await scanner.scanLibrary(isFullScan: true);
        track = (await db.select(db.tracks).get()).first;
        expect(track.isMissing, isFalse);
      },
    );
  });
}
