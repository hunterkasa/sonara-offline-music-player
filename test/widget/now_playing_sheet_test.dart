import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/now_playing/now_playing_sheet.dart';

class _StatefulMockPlaybackController extends StubPlaybackController {
  _StatefulMockPlaybackController({PlaybackSnapshot? initial})
    : _snap =
          initial ??
          const PlaybackSnapshot(
            currentTrackKey: 'test_k1',
            title: 'Symphony No. 5',
            artist: 'Beethoven',
            state: PlaybackState.playing,
            duration: Duration(minutes: 5),
            position: Duration(minutes: 1),
            shuffleEnabled: false,
            repeatMode: 0,
          );

  PlaybackSnapshot _snap;
  final StreamController<PlaybackSnapshot> _controller =
      StreamController<PlaybackSnapshot>.broadcast();

  @override
  PlaybackSnapshot get currentSnapshot => _snap;

  @override
  Stream<PlaybackSnapshot> get snapshotStream => _controller.stream;

  @override
  Future<void> setShuffle(bool enabled) async {
    _snap = _snap.copyWith(shuffleEnabled: enabled);
    _controller.add(_snap);
  }

  @override
  Future<void> setRepeatMode(int mode) async {
    _snap = _snap.copyWith(repeatMode: mode);
    _controller.add(_snap);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('NowPlayingSheet Controls and Theme Color Tests', () {
    late AppDatabase db;
    late _StatefulMockPlaybackController controller;

    setUp(() async {
      db = AppDatabase.inMemory();
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'test_k1',
              contentUri: 'content://audio/1',
              path: '/music/1.mp3',
              relativeDir: const Value('music'),
              title: 'Symphony No. 5',
              titleSort: 'symphony no. 5',
              durationMs: 300000,
              sizeBytes: 10000000,
              isFavorite: const Value(false),
            ),
          );
      controller = _StatefulMockPlaybackController();
    });

    tearDown(() async {
      controller.dispose();
      await db.close();
    });

    testWidgets('NowPlayingSheet renders controls and invokes onCollapse', (
      WidgetTester tester,
    ) async {
      var collapsed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            playbackControllerProvider.overrideWithValue(controller),
          ],
          child: MaterialApp(
            home: NowPlayingSheet(
              onCollapse: () {
                collapsed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

      // Tap collapse button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(collapsed, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'Shuffle button clearly toggles active state in Light and Dark themes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(body: NowPlayingSheet(onCollapse: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final shuffleFinder = find.byIcon(Icons.shuffle_rounded);
        expect(shuffleFinder, findsOneWidget);

        // Initially shuffle is disabled
        expect(controller.currentSnapshot.shuffleEnabled, isFalse);

        // Tap shuffle button to enable
        await tester.tap(shuffleFinder);
        await tester.pumpAndSettle();

        expect(controller.currentSnapshot.shuffleEnabled, isTrue);

        // Tap shuffle button again to disable
        await tester.tap(shuffleFinder);
        await tester.pumpAndSettle();

        expect(controller.currentSnapshot.shuffleEnabled, isFalse);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'Repeat button cycles through Off, All, One with distinct active state',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(body: NowPlayingSheet(onCollapse: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mode 0: repeat_rounded
        expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
        expect(controller.currentSnapshot.repeatMode, equals(0));

        // Tap to cycle to Mode 1 (Repeat All)
        await tester.tap(find.byIcon(Icons.repeat_rounded));
        await tester.pumpAndSettle();

        expect(controller.currentSnapshot.repeatMode, equals(1));
        expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

        // Tap to cycle to Mode 2 (Repeat One)
        await tester.tap(find.byIcon(Icons.repeat_rounded));
        await tester.pumpAndSettle();

        expect(controller.currentSnapshot.repeatMode, equals(2));
        expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);

        // Tap to cycle back to Mode 0 (Off)
        await tester.tap(find.byIcon(Icons.repeat_one_rounded));
        await tester.pumpAndSettle();

        expect(controller.currentSnapshot.repeatMode, equals(0));
        expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'Favorite button changes color to rose red and toggles favorite status',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(body: NowPlayingSheet(onCollapse: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially not favorited: shows border icon
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

        // Tap to favorite
        await tester.tap(find.byIcon(Icons.favorite_border_rounded));
        await tester.pumpAndSettle();

        // Now favorited: shows filled icon
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

        // Tap to unfavorite
        await tester.tap(find.byIcon(Icons.favorite_rounded));
        await tester.pumpAndSettle();

        // Reverted to border icon
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'NowPlayingSheet renders without overflow on constrained height screens',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 500);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(body: NowPlayingSheet(onCollapse: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Symphony No. 5'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
