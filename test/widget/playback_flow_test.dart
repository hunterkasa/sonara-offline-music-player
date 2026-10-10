import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/models/audio_settings.dart';
import 'package:sonara/features/now_playing/now_playing_sheet.dart';
import 'package:sonara/shared/mini_player/mini_player.dart';

class TestPlaybackController implements PlaybackController {
  PlaybackSnapshot _snapshot = const PlaybackSnapshot(
    currentTrackKey: 'test_1',
    title: 'Initial Track',
    artist: 'Initial Artist',
    state: PlaybackState.idle,
    duration: Duration(minutes: 3),
  );

  final _controller = StreamController<PlaybackSnapshot>.broadcast();
  int _queueIndex = 0;
  final List<String> _queue = ['test_1', 'test_2', 'test_3'];

  @override
  PlaybackSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<PlaybackSnapshot> get snapshotStream async* {
    yield _snapshot;
    yield* _controller.stream;
  }

  @override
  List<Track> get currentQueue => const [];

  @override
  Stream<List<Track>> get queueStream => Stream.value(const []);

  void _emit(PlaybackSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(_snapshot);
  }

  @override
  Future<void> play() async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: PlaybackState.playing,
        position: _snapshot.position,
        duration: _snapshot.duration,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
      ),
    );
  }

  @override
  Future<void> pause() async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: PlaybackState.paused,
        position: _snapshot.position,
        duration: _snapshot.duration,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
      ),
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
  Future<void> playTrack(String trackKey) async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: trackKey,
        title: 'Playing $trackKey',
        artist: 'Artist',
        state: PlaybackState.playing,
        duration: const Duration(minutes: 3),
      ),
    );
  }

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    _queueIndex = initialIndex;
    final key = trackKeys.isNotEmpty ? trackKeys[_queueIndex] : 'test_1';
    _emit(
      PlaybackSnapshot(
        currentTrackKey: key,
        title: 'Golden Track ${_queueIndex + 1}',
        artist: 'Golden Artist',
        state: PlaybackState.playing,
        duration: const Duration(minutes: 3),
        shuffleEnabled: shuffle,
      ),
    );
  }

  @override
  Future<void> skipToNext() async {
    _queueIndex = (_queueIndex + 1) % _queue.length;
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _queue[_queueIndex],
        title: 'Golden Track ${_queueIndex + 1}',
        artist: 'Golden Artist',
        state: PlaybackState.playing,
        duration: const Duration(minutes: 3),
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
      ),
    );
  }

  @override
  Future<void> skipToPrevious() async {
    _queueIndex = (_queueIndex - 1 + _queue.length) % _queue.length;
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _queue[_queueIndex],
        title: 'Golden Track ${_queueIndex + 1}',
        artist: 'Golden Artist',
        state: PlaybackState.playing,
        duration: const Duration(minutes: 3),
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
      ),
    );
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queueIndex = index;
      _emit(
        PlaybackSnapshot(
          currentTrackKey: _queue[_queueIndex],
          title: 'Golden Track ${_queueIndex + 1}',
          artist: 'Golden Artist',
          state: PlaybackState.playing,
          duration: const Duration(minutes: 3),
          shuffleEnabled: _snapshot.shuffleEnabled,
          repeatMode: _snapshot.repeatMode,
        ),
      );
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: _snapshot.state,
        position: position,
        duration: _snapshot.duration,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
      ),
    );
  }

  @override
  Future<void> setShuffle(bool enabled) async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: _snapshot.state,
        position: _snapshot.position,
        duration: _snapshot.duration,
        shuffleEnabled: enabled,
        repeatMode: _snapshot.repeatMode,
      ),
    );
  }

  @override
  Future<void> setRepeatMode(int mode) async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: _snapshot.state,
        position: _snapshot.position,
        duration: _snapshot.duration,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: mode,
      ),
    );
  }

  @override
  Future<void> playNext(String trackKey) async {}

  @override
  Future<void> addToQueue(String trackKey) async {}

  @override
  Future<void> setSpeed(double speed) async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: _snapshot.state,
        position: _snapshot.position,
        duration: _snapshot.duration,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
        speed: speed,
        pitchSemitones: _snapshot.pitchSemitones,
      ),
    );
  }

  @override
  Future<void> setPitchSemitones(int semitones) async {
    _emit(
      PlaybackSnapshot(
        currentTrackKey: _snapshot.currentTrackKey,
        title: _snapshot.title,
        artist: _snapshot.artist,
        state: _snapshot.state,
        position: _snapshot.position,
        duration: _snapshot.duration,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatMode: _snapshot.repeatMode,
        speed: _snapshot.speed,
        pitchSemitones: semitones,
      ),
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

void main() {
  group('Playback Flow Golden Path', () {
    late TestPlaybackController controller;

    setUp(() {
      controller = TestPlaybackController();
    });

    testWidgets('MiniPlayer updates on playback and opens NowPlayingSheet', (
      WidgetTester tester,
    ) async {
      var isExpanded = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [playbackControllerProvider.overrideWithValue(controller)],
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Stack(
                    children: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.playQueue([
                              'test_1',
                              'test_2',
                            ], initialIndex: 0);
                          },
                          child: const Text('Start Playback'),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: MiniPlayer(
                          onTap: () {
                            setState(() => isExpanded = true);
                          },
                        ),
                      ),
                      if (isExpanded)
                        Positioned.fill(
                          child: NowPlayingSheet(
                            onCollapse: () {
                              setState(() => isExpanded = false);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // MiniPlayer initially shows initial track
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Initial Track'), findsOneWidget);

      // Tap start playback
      await tester.tap(find.text('Start Playback'));
      await tester.pump();

      // MiniPlayer reflects playing track
      expect(find.text('Golden Track 1'), findsOneWidget);

      // Tap MiniPlayer to expand NowPlayingSheet
      await tester.tap(find.byType(MiniPlayer));
      await tester.pump();

      expect(isExpanded, isTrue);
      expect(find.byType(NowPlayingSheet), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('Golden Track 1'), findsWidgets);

      // Tap Next button in full player
      await tester.tap(find.byIcon(Icons.skip_next_rounded).last);
      await tester.pump();

      // Verifies active track advanced to track 2
      expect(find.text('Golden Track 2'), findsWidgets);

      // Tap Shuffle button
      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();
      expect(controller.currentSnapshot.shuffleEnabled, isTrue);

      // Tap Repeat button
      await tester.tap(find.byIcon(Icons.repeat_rounded));
      await tester.pump();
      expect(controller.currentSnapshot.repeatMode, equals(1));

      // Test scrubber slider interaction
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();

      // Collapse NowPlayingSheet
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(isExpanded, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
