import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:sonara/audio/sonara_audio_handler.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/queue_manager.dart';

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  FakeAudioPlayerPlatform(super.id);

  final _eventController = StreamController<PlaybackEventMessage>.broadcast();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: const Duration(minutes: 3),
        duration: const Duration(minutes: 3),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _eventController.close();
    return DisposeResponse();
  }
}

class FakeJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      FakeAudioPlayerPlatform(request.id);

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async => DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async => DisposeAllPlayersResponse();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
  });

  group('SonaraAudioHandler MediaBrowser / Android Auto Support', () {
    late AppDatabase db;
    late QueueManager queueManager;
    late SonaraAudioHandler audioHandler;

    setUp(() async {
      db = AppDatabase.inMemory();

      // Seed Artist & Album
      final artistId = await db.getOrCreateArtist('Starlight Trio');
      final albumId = await db.getOrCreateAlbum(
        title: 'Cosmic Journey',
        artistId: artistId,
        year: 2025,
      );

      // Seed Tracks
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'auto_track_$i',
                contentUri: 'content://media/external/audio/media/$i',
                path: '/storage/music/auto_track_$i.mp3',
                title: 'Journey Part $i',
                titleSort: 'journey part $i',
                durationMs: 180000,
                sizeBytes: 4000000,
                artistId: drift.Value(artistId),
                albumId: drift.Value(albumId),
                isFavorite: drift.Value(i == 1),
              ),
            );
      }

      // Seed Playlist
      final playlistId = await db.createPlaylist(name: 'Auto Roadtrip');
      await db
          .into(db.playlistTracks)
          .insert(
            PlaylistTracksCompanion.insert(
              playlistId: playlistId,
              trackKey: 'auto_track_1',
              position: 0,
              addedAt: 1000,
            ),
          );
      await db
          .into(db.playlistTracks)
          .insert(
            PlaylistTracksCompanion.insert(
              playlistId: playlistId,
              trackKey: 'auto_track_2',
              position: 1,
              addedAt: 1001,
            ),
          );

      queueManager = QueueManager(db: db);
      audioHandler = SonaraAudioHandler(
        queueManager: queueManager,
        db: db,
        enablePersistenceTimer: false,
      );
    });

    tearDown(() async {
      await audioHandler.dispose();
      await db.close();
    });

    test(
      'getChildren(root) returns the 5 top-level browsing categories',
      () async {
        final rootItems = await audioHandler.getChildren(
          AudioService.browsableRootId,
        );

        expect(rootItems.length, equals(5));
        final ids = rootItems.map((item) => item.id).toList();
        expect(
          ids,
          containsAll([
            'root_playlists',
            'root_liked',
            'root_artists',
            'root_albums',
            'root_recents',
          ]),
        );
        for (final item in rootItems) {
          expect(item.playable, isFalse);
        }
      },
    );

    test(
      'getChildren(root_playlists) lists playlists and items inside',
      () async {
        final playlists = await audioHandler.getChildren('root_playlists');
        expect(playlists.length, equals(1));
        expect(playlists.first.title, equals('Auto Roadtrip'));

        final playlistTracks = await audioHandler.getChildren(
          playlists.first.id,
        );
        expect(playlistTracks.length, equals(2));
        expect(playlistTracks.first.title, equals('Journey Part 1'));
        expect(playlistTracks.first.playable, isTrue);
      },
    );

    test('getChildren(root_liked) lists favorite tracks', () async {
      final liked = await audioHandler.getChildren('root_liked');
      expect(liked.length, equals(1));
      expect(liked.first.title, equals('Journey Part 1'));
      expect(liked.first.playable, isTrue);
    });

    test('getChildren(root_artists) and getChildren(root_albums) return proper hierarchies', () async {
      final artists = await audioHandler.getChildren('root_artists');
      expect(artists.length, equals(1));
      expect(artists.first.title, equals('Starlight Trio'));

      final artistTracks = await audioHandler.getChildren(artists.first.id);
      expect(artistTracks.length, equals(3));

      final albums = await audioHandler.getChildren('root_albums');
      expect(albums.length, equals(1));
      expect(albums.first.title, equals('Cosmic Journey'));

      final albumTracks = await audioHandler.getChildren(albums.first.id);
      expect(albumTracks.length, equals(3));
    });

    test('getItem returns single resolved media item', () async {
      final item = await audioHandler.getItem('auto_track_1');
      expect(item, isNotNull);
      expect(item!.title, equals('Journey Part 1'));
      expect(item.artist, equals('Starlight Trio'));
      expect(item.album, equals('Cosmic Journey'));
    });
  });
}
