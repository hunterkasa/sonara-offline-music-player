import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/lyrics/lyrics_sheet.dart';
import 'package:sonara/features/now_playing/now_playing_sheet.dart';
import 'package:sonara/features/queue/queue_sheet.dart';
import 'package:sonara/features/sleep_timer/sleep_timer_sheet.dart';
import 'package:sonara/features/speed/speed_sheet.dart';

class MockPlaybackController extends StubPlaybackController {
  PlaybackSnapshot _snap = const PlaybackSnapshot(
    currentTrackKey: 'k1',
    title: 'Phase 3 Symphony',
    artist: 'Antigravity Ensemble',
    state: PlaybackState.playing,
    duration: Duration(minutes: 4),
    position: Duration(minutes: 1),
  );

  @override
  PlaybackSnapshot get currentSnapshot => _snap;

  @override
  Stream<PlaybackSnapshot> get snapshotStream => Stream.value(_snap);

  @override
  List<Track> get currentQueue => const [
    Track(
      id: 1,
      trackKey: 'k1',
      contentUri: 'content://test/1',
      path: '/test/1.flac',
      relativeDir: 'Music',
      title: 'Phase 3 Symphony',
      titleSort: 'phase 3 symphony',
      durationMs: 240000,
      sizeBytes: 25000000,
      hasLyrics: true,
      playCount: 0,
      skipCount: 0,
      isFavorite: false,
      isHidden: false,
      isMissing: false,
      rating: 0,
    ),
  ];

  @override
  Stream<List<Track>> get queueStream => Stream.value(currentQueue);

  @override
  Future<void> setSpeed(double speed) async {
    _snap = PlaybackSnapshot(
      currentTrackKey: _snap.currentTrackKey,
      title: _snap.title,
      artist: _snap.artist,
      state: _snap.state,
      duration: _snap.duration,
      position: _snap.position,
      speed: speed,
    );
  }
}

void main() {
  group('Phase 3 Now Playing & Sheets Widget Tests', () {
    late AppDatabase db;
    late MockPlaybackController controller;

    setUp(() {
      db = AppDatabase.inMemory();
      controller = MockPlaybackController();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'NowPlayingSheet renders title, controls, and responds to secondary sheets',
      (tester) async {
        var collapsed = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NowPlayingSheet(onCollapse: () => collapsed = true),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify title and artist are visible
        expect(find.text('Phase 3 Symphony'), findsOneWidget);
        expect(find.text('Antigravity Ensemble'), findsOneWidget);

        // Verify transport buttons
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);

        // Verify collapse button triggers callback
        await tester.tap(find.byTooltip('Collapse'));
        await tester.pumpAndSettle();
        expect(collapsed, isTrue);

        // Verify opening SpeedSheet
        await tester.tap(find.byTooltip('Playback Speed'));
        await tester.pumpAndSettle();
        expect(find.byType(SpeedSheet), findsOneWidget);
        expect(find.text('PLAYBACK SPEED'), findsOneWidget);

        // Dismiss SpeedSheet
        Navigator.pop(tester.element(find.byType(SpeedSheet)));
        await tester.pumpAndSettle();

        // Verify opening SleepTimerSheet
        await tester.tap(find.byTooltip('Sleep Timer'));
        await tester.pumpAndSettle();
        expect(find.byType(SleepTimerSheet), findsOneWidget);
        expect(find.text('SLEEP TIMER'), findsOneWidget);

        // Dismiss SleepTimerSheet
        Navigator.pop(tester.element(find.byType(SleepTimerSheet)));
        await tester.pumpAndSettle();

        // Verify opening QueueSheet
        await tester.tap(find.byTooltip('Queue'));
        await tester.pumpAndSettle();
        expect(find.byType(QueueSheet), findsOneWidget);
        expect(find.text('PLAY QUEUE'), findsOneWidget);

        // Dismiss QueueSheet
        Navigator.pop(tester.element(find.byType(QueueSheet)));
        await tester.pumpAndSettle();

        // Verify opening LyricsSheet
        await tester.tap(find.byTooltip('Lyrics'));
        await tester.pumpAndSettle();
        expect(find.byType(LyricsSheet), findsOneWidget);
        expect(find.text('LYRICS'), findsOneWidget);

        // Dismiss LyricsSheet
        Navigator.pop(tester.element(find.byType(LyricsSheet)));
        await tester.pumpAndSettle();

        // Flush unmounted streams and Drift cleanup timers
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
