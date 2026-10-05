import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:sonara/audio/playback_controller.dart';
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
  Future<PlayResponse> play(PlayRequest request) async {
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
    return PlayResponse();
  }

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

  group('RealPlaybackController & SonaraAudioHandler', () {
    late AppDatabase db;
    late QueueManager queueManager;
    late SonaraAudioHandler audioHandler;
    late RealPlaybackController controller;

    setUp(() async {
      db = AppDatabase.inMemory();
      // Insert test tracks
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'track_$i',
                contentUri: 'content://media/external/audio/media/$i',
                path: '/storage/emulated/0/Music/track_$i.mp3',
                title: 'Track $i',
                titleSort: 'track $i',
                durationMs: 180000,
                sizeBytes: 4000000,
              ),
            );
      }

      queueManager = QueueManager(db: db);
      audioHandler = SonaraAudioHandler(
        queueManager: queueManager,
        db: db,
        enablePersistenceTimer: false,
      );
      controller = RealPlaybackController(audioHandler: audioHandler, db: db);
    });

    tearDown(() async {
      controller.dispose();
      await audioHandler.dispose();
      await db.close();
    });

    test('initial snapshot starts idle', () {
      expect(controller.currentSnapshot.state, equals(PlaybackState.idle));
      expect(controller.currentSnapshot.isPlaying, isFalse);
    });

    test('playQueue loads tracks into queue and updates snapshot', () async {
      await controller.playQueue(['track_1', 'track_2'], initialIndex: 0);

      expect(controller.currentQueue.length, equals(2));
      expect(queueManager.currentIndex, equals(0));
      expect(queueManager.currentTrack?.trackKey, equals('track_1'));
    });

    test('skipToNext advances active track in queue', () async {
      await controller.playQueue([
        'track_1',
        'track_2',
        'track_3',
      ], initialIndex: 0);
      expect(queueManager.currentIndex, equals(0));

      await controller.skipToNext();
      expect(queueManager.currentIndex, equals(1));
      expect(queueManager.currentTrack?.trackKey, equals('track_2'));
    });

    test('setShuffle updates queueManager and snapshot', () async {
      await controller.playQueue([
        'track_1',
        'track_2',
        'track_3',
      ], initialIndex: 0);
      expect(queueManager.shuffleEnabled, isFalse);

      await controller.setShuffle(true);
      expect(queueManager.shuffleEnabled, isTrue);

      await controller.setShuffle(false);
      expect(queueManager.shuffleEnabled, isFalse);
    });

    test('setRepeatMode updates queueManager repeat state', () async {
      await controller.playQueue(['track_1', 'track_2'], initialIndex: 0);

      await controller.setRepeatMode(1); // all
      expect(queueManager.repeatMode, equals(QueueRepeatMode.all));

      await controller.setRepeatMode(2); // one
      expect(queueManager.repeatMode, equals(QueueRepeatMode.one));

      await controller.setRepeatMode(0); // off
      expect(queueManager.repeatMode, equals(QueueRepeatMode.off));
    });

    test(
      'playNext inserts track directly after current item in queue',
      () async {
        await controller.playQueue(['track_1', 'track_3'], initialIndex: 0);
        await controller.playNext('track_2');

        expect(controller.currentQueue.length, equals(3));
        expect(controller.currentQueue[1].trackKey, equals('track_2'));
      },
    );

    test('addToQueue appends track to queue', () async {
      await controller.playQueue(['track_1'], initialIndex: 0);
      await controller.addToQueue('track_2');

      expect(controller.currentQueue.length, equals(2));
      expect(controller.currentQueue.last.trackKey, equals('track_2'));
    });

    test('setSpeed changes playback speed', () async {
      await controller.playQueue(['track_1'], initialIndex: 0);
      await controller.setSpeed(1.5);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.currentSnapshot.speed, equals(1.5));
    });

    test('reorderQueue reorders items in queue', () async {
      await controller.playQueue([
        'track_1',
        'track_2',
        'track_3',
      ], initialIndex: 0);
      await controller.reorderQueue(0, 2);
      expect(
        controller.currentQueue.map((t) => t.trackKey).toList(),
        equals(['track_2', 'track_3', 'track_1']),
      );
    });

    test('removeFromQueue removes item from queue', () async {
      await controller.playQueue([
        'track_1',
        'track_2',
        'track_3',
      ], initialIndex: 0);
      await controller.removeFromQueue(1);
      expect(controller.currentQueue.length, equals(2));
      expect(
        controller.currentQueue.map((t) => t.trackKey).toList(),
        equals(['track_1', 'track_3']),
      );
    });

    test('clearQueue empties queue and stops playback', () async {
      await controller.playQueue(['track_1', 'track_2'], initialIndex: 0);
      await controller.clearQueue();
      expect(controller.currentQueue.isEmpty, isTrue);
      expect(controller.currentSnapshot.currentTrackKey, isNull);
    });
  });
}
