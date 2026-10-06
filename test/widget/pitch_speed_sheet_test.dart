import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/now_playing/pitch_speed_sheet.dart';

class TestSheetPlaybackController extends StubPlaybackController {
  PlaybackSnapshot _snap = const PlaybackSnapshot(
    currentTrackKey: 'test_1',
    title: 'Pitch Test Track',
    artist: 'Pitch Test Artist',
    state: PlaybackState.playing,
    speed: 1.0,
    pitchSemitones: 2,
  );

  int setPitchCalls = 0;
  int lastPitchSemitones = 0;
  double lastSpeed = 1.0;

  @override
  PlaybackSnapshot get currentSnapshot => _snap;

  @override
  Stream<PlaybackSnapshot> get snapshotStream => Stream.value(_snap);

  @override
  Future<void> setPitchSemitones(int semitones) async {
    setPitchCalls++;
    lastPitchSemitones = semitones;
    _snap = PlaybackSnapshot(
      currentTrackKey: _snap.currentTrackKey,
      title: _snap.title,
      artist: _snap.artist,
      state: _snap.state,
      speed: _snap.speed,
      pitchSemitones: semitones,
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    lastSpeed = speed;
    _snap = PlaybackSnapshot(
      currentTrackKey: _snap.currentTrackKey,
      title: _snap.title,
      artist: _snap.artist,
      state: _snap.state,
      speed: speed,
      pitchSemitones: _snap.pitchSemitones,
    );
  }
}

void main() {
  group('PitchSpeedSheet Widget Tests', () {
    late AppDatabase db;
    late TestSheetPlaybackController controller;

    setUp(() {
      db = AppDatabase.inMemory();
      controller = TestSheetPlaybackController();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'PitchSpeedSheet renders key transposition and speed controls',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: const MaterialApp(home: Scaffold(body: PitchSpeedSheet())),
          ),
        );

        expect(find.text('Tempo & Key Transposition'), findsOneWidget);
        expect(find.text('Key Transposition'), findsOneWidget);
        expect(find.text('Playback Speed'), findsOneWidget);
        expect(find.text('+2 semitones'), findsOneWidget);
        expect(find.text('Major 2nd Up'), findsOneWidget);
        expect(find.text('Reset Key'), findsOneWidget);

        // Verify speed chips
        expect(find.text('1.0x'), findsWidgets);
        expect(find.text('1.25x'), findsOneWidget);

        // Tap Reset Key button
        await tester.tap(find.text('Reset Key'));
        await tester.pump();

        expect(controller.lastPitchSemitones, equals(0));
        expect(controller.setPitchCalls, greaterThanOrEqualTo(1));

        // Tap 1.25x chip
        await tester.tap(find.text('1.25x'));
        await tester.pump();
        expect(controller.lastSpeed, equals(1.25));
      },
    );
  });
}
