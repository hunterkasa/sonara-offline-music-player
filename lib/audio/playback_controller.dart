import 'dart:async';

import 'package:audio_service/audio_service.dart' as as_service;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/database_provider.dart';
import '../domain/models/audio_settings.dart';
import '../domain/services/audio_settings_service.dart';
import '../domain/services/listening_stats_service.dart';
import '../domain/services/queue_manager.dart';
import 'sonara_audio_handler.dart';

enum PlaybackState { idle, loading, playing, paused, error }

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.currentTrackKey,
    this.title = '',
    this.artist = '',
    this.artworkUri,
    this.state = PlaybackState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffleEnabled = false,
    this.repeatMode = 0,
    this.speed = 1.0,
    this.pitchSemitones = 0,
  });

  final String? currentTrackKey;
  final String title;
  final String artist;
  final String? artworkUri;
  final PlaybackState state;
  final Duration position;
  final Duration duration;
  final bool shuffleEnabled;
  final int repeatMode;
  final double speed;
  final int pitchSemitones;

  bool get isPlaying => state == PlaybackState.playing;
}

abstract class PlaybackController {
  PlaybackSnapshot get currentSnapshot;
  Stream<PlaybackSnapshot> get snapshotStream;
  List<Track> get currentQueue;
  Stream<List<Track>> get queueStream;

  Future<void> play();
  Future<void> playTrack(String trackKey);
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  });
  Future<void> playNext(String trackKey);
  Future<void> addToQueue(String trackKey);
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> seek(Duration position);
  Future<void> setShuffle(bool enabled);
  Future<void> setRepeatMode(int mode);
  Future<void> setSpeed(double speed);
  Future<void> setPitchSemitones(int semitones);
  Future<void> reorderQueue(int oldIndex, int newIndex);
  Future<void> removeFromQueue(int index);
  Future<void> clearQueue();
  Future<void> applyAudioSettings(AudioSettings settings);
}

class StubPlaybackController implements PlaybackController {
  PlaybackSnapshot _snapshot = const PlaybackSnapshot(
    title: 'Welcome to Sonara',
    artist: 'Ready to play local music',
  );

  @override
  PlaybackSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<PlaybackSnapshot> get snapshotStream => Stream.value(_snapshot);

  @override
  List<Track> get currentQueue => const [];

  @override
  Stream<List<Track>> get queueStream => Stream.value(const []);

  @override
  Future<void> play() async {
    _snapshot = PlaybackSnapshot(
      currentTrackKey: _snapshot.currentTrackKey,
      title: _snapshot.title,
      artist: _snapshot.artist,
      state: PlaybackState.playing,
    );
  }

  @override
  Future<void> playTrack(String trackKey) async {
    _snapshot = PlaybackSnapshot(
      currentTrackKey: trackKey,
      title: 'Playing track',
      artist: 'Local audio',
      state: PlaybackState.playing,
    );
  }

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    if (trackKeys.isNotEmpty) {
      await playTrack(trackKeys[initialIndex.clamp(0, trackKeys.length - 1)]);
    }
  }

  @override
  Future<void> playNext(String trackKey) async {}

  @override
  Future<void> addToQueue(String trackKey) async {}

  @override
  Future<void> pause() async {
    _snapshot = PlaybackSnapshot(
      currentTrackKey: _snapshot.currentTrackKey,
      title: _snapshot.title,
      artist: _snapshot.artist,
      state: PlaybackState.paused,
    );
  }

  @override
  Future<void> togglePlayPause() async {
    if (_snapshot.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setShuffle(bool enabled) async {}

  @override
  Future<void> setRepeatMode(int mode) async {}

  @override
  Future<void> setSpeed(double speed) async {
    _snapshot = PlaybackSnapshot(
      currentTrackKey: _snapshot.currentTrackKey,
      title: _snapshot.title,
      artist: _snapshot.artist,
      artworkUri: _snapshot.artworkUri,
      state: _snapshot.state,
      position: _snapshot.position,
      duration: _snapshot.duration,
      shuffleEnabled: _snapshot.shuffleEnabled,
      repeatMode: _snapshot.repeatMode,
      speed: speed,
      pitchSemitones: _snapshot.pitchSemitones,
    );
  }

  @override
  Future<void> setPitchSemitones(int semitones) async {
    _snapshot = PlaybackSnapshot(
      currentTrackKey: _snapshot.currentTrackKey,
      title: _snapshot.title,
      artist: _snapshot.artist,
      artworkUri: _snapshot.artworkUri,
      state: _snapshot.state,
      position: _snapshot.position,
      duration: _snapshot.duration,
      shuffleEnabled: _snapshot.shuffleEnabled,
      repeatMode: _snapshot.repeatMode,
      speed: _snapshot.speed,
      pitchSemitones: semitones,
    );
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {}

  @override
  Future<void> removeFromQueue(int index) async {}

  @override
  Future<void> clearQueue() async {}

  @override
  Future<void> applyAudioSettings(AudioSettings settings) async {}
}

class RealPlaybackController implements PlaybackController {
  RealPlaybackController({
    required SonaraAudioHandler audioHandler,
    required this.db,
    this.statsService,
  }) : _handler = audioHandler {
    _initStreams();
  }

  final SonaraAudioHandler _handler;
  final AppDatabase db;
  final ListeningStatsService? statsService;
  final _snapshotController = StreamController<PlaybackSnapshot>.broadcast();
  PlaybackSnapshot _currentSnapshot = const PlaybackSnapshot();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void _initStreams() {
    _subscriptions.add(_handler.playbackState.listen((_) => _updateSnapshot()));
    _subscriptions.add(
      _handler.mediaItem.listen((media) {
        statsService?.onTrackChanged(
          media?.id,
          media?.duration?.inMilliseconds ?? 0,
        );
        _updateSnapshot();
      }),
    );
    _subscriptions.add(
      _handler.queueManager.stateStream.listen((_) => _updateSnapshot()),
    );
    int lastPositionMs = 0;
    _subscriptions.add(
      _handler.player.positionStream.listen((pos) {
        statsService?.onPositionUpdate(
          pos.inMilliseconds,
          _handler.player.playing,
        );
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (!_handler.player.playing || (nowMs - lastPositionMs) >= 200) {
          lastPositionMs = nowMs;
          _updateSnapshot();
        }
      }),
    );
    _updateSnapshot();
  }

  void _updateSnapshot() {
    final media = _handler.mediaItem.value;
    final state = _handler.playbackState.value;
    final queueState = _handler.queueManager.state;
    final position = _handler.player.position;

    PlaybackState status;
    if (state.playing) {
      status = PlaybackState.playing;
    } else if (state.processingState ==
            as_service.AudioProcessingState.loading ||
        state.processingState == as_service.AudioProcessingState.buffering) {
      status = PlaybackState.loading;
    } else if (state.processingState == as_service.AudioProcessingState.error) {
      status = PlaybackState.error;
    } else if (media != null) {
      status = PlaybackState.paused;
    } else {
      status = PlaybackState.idle;
    }

    _currentSnapshot = PlaybackSnapshot(
      currentTrackKey: media?.id,
      title: media?.title ?? '',
      artist: media?.artist ?? '',
      artworkUri: media?.artUri?.toString(),
      state: status,
      position: position,
      duration: media?.duration ?? Duration.zero,
      shuffleEnabled: queueState.shuffleEnabled,
      repeatMode: queueState.repeatMode.index,
      speed: state.speed,
      pitchSemitones: _handler.pitchSemitones,
    );

    _snapshotController.add(_currentSnapshot);
  }

  @override
  PlaybackSnapshot get currentSnapshot => _currentSnapshot;

  @override
  Stream<PlaybackSnapshot> get snapshotStream async* {
    yield _currentSnapshot;
    yield* _snapshotController.stream;
  }

  @override
  List<Track> get currentQueue => _handler.queueManager.queue;

  @override
  Stream<List<Track>> get queueStream async* {
    yield _handler.queueManager.queue;
    yield* _handler.queueManager.stateStream.map((s) => s.queue);
  }

  @override
  Future<void> play() => _handler.play();

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> togglePlayPause() async {
    if (_currentSnapshot.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> skipToNext() => _handler.skipToNext();

  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> setShuffle(bool enabled) async {
    _handler.queueManager.setShuffle(enabled);
  }

  @override
  Future<void> setRepeatMode(int mode) async {
    final repeat = (mode >= 0 && mode < QueueRepeatMode.values.length)
        ? QueueRepeatMode.values[mode]
        : QueueRepeatMode.off;
    _handler.queueManager.setRepeatMode(repeat);
  }

  @override
  Future<void> playTrack(String trackKey) async {
    final track = await db.getTrackByKey(trackKey);
    if (track != null) {
      await _handler.playTrack(track);
    }
  }

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    final tracks = await db.getTracksByKeys(trackKeys);
    if (tracks.isNotEmpty) {
      await _handler.playQueue(
        tracks,
        initialIndex: initialIndex,
        shuffle: shuffle,
      );
    }
  }

  @override
  Future<void> playNext(String trackKey) async {
    final track = await db.getTrackByKey(trackKey);
    if (track != null) {
      _handler.queueManager.playNext(track);
    }
  }

  @override
  Future<void> addToQueue(String trackKey) async {
    final track = await db.getTrackByKey(trackKey);
    if (track != null) {
      _handler.queueManager.addToQueue(track);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
  }

  @override
  Future<void> setPitchSemitones(int semitones) async {
    await _handler.setPitchSemitones(semitones);
    _updateSnapshot();
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    _handler.queueManager.reorder(oldIndex, newIndex);
  }

  @override
  Future<void> removeFromQueue(int index) async {
    _handler.queueManager.removeAt(index);
  }

  @override
  Future<void> clearQueue() async {
    _handler.queueManager.clear();
    await _handler.stop();
  }

  @override
  Future<void> applyAudioSettings(AudioSettings settings) =>
      _handler.applyAudioSettings(settings);

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _snapshotController.close();
  }
}

final audioHandlerProvider = Provider<SonaraAudioHandler?>((ref) => null);

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  if (audioHandler != null) {
    final db = ref.watch(databaseProvider);
    final stats = ref.watch(listeningStatsServiceProvider);
    final controller = RealPlaybackController(
      audioHandler: audioHandler,
      db: db,
      statsService: stats,
    );
    ref.listen<AudioSettings>(audioSettingsProvider, (prev, next) {
      controller.applyAudioSettings(next);
    }, fireImmediately: true);
    ref.onDispose(controller.dispose);
    return controller;
  }
  return StubPlaybackController();
});

final playbackSnapshotProvider = StreamProvider<PlaybackSnapshot>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.snapshotStream;
});

final queueListProvider = StreamProvider<List<Track>>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.queueStream;
});
