import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  bool get isPlaying => state == PlaybackState.playing;
}

abstract class PlaybackController {
  PlaybackSnapshot get currentSnapshot;
  Stream<PlaybackSnapshot> get snapshotStream;

  Future<void> play();
  Future<void> playTrack(String trackKey);
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> seek(Duration position);
  Future<void> setShuffle(bool enabled);
  Future<void> setRepeatMode(int mode);
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
}

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  return StubPlaybackController();
});

final playbackSnapshotProvider = StreamProvider<PlaybackSnapshot>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.snapshotStream;
});
