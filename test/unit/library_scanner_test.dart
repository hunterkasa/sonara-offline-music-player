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
  });
}
