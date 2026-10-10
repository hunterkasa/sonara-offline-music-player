import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/features/queue/queue_sheet.dart';

class _MockQueueController extends StubPlaybackController {
  _MockQueueController(this._queue);

  final List<Track> _queue;
  int? reorderedOldIndex;
  int? reorderedNewIndex;

  @override
  PlaybackSnapshot get currentSnapshot => PlaybackSnapshot(
    currentTrackKey: _queue.isNotEmpty ? _queue.first.trackKey : null,
    title: _queue.isNotEmpty ? _queue.first.title : '',
    artist: 'Test Artist',
    state: PlaybackState.playing,
    duration: const Duration(minutes: 3),
  );

  @override
  Stream<PlaybackSnapshot> get snapshotStream => Stream.value(currentSnapshot);

  @override
  List<Track> get currentQueue => _queue;

  @override
  Stream<List<Track>> get queueStream => Stream.value(_queue);

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    reorderedOldIndex = oldIndex;
    reorderedNewIndex = newIndex;
  }
}

Track _makeTrack(String key, String title) {
  return Track(
    id: key.hashCode,
    trackKey: key,
    contentUri: 'content://audio/$key',
    path: '/music/$key.mp3',
    relativeDir: 'Music',
    title: title,
    titleSort: title.toLowerCase(),
    durationMs: 180000,
    sizeBytes: 5000000,
    hasLyrics: false,
    playCount: 0,
    skipCount: 0,
    isFavorite: false,
    isHidden: false,
    isMissing: false,
    rating: 0,
  );
}

void main() {
  group('QueueSheet Tests', () {
    late _MockQueueController controller;
    late List<Track> tracks;

    setUp(() {
      tracks = [
        _makeTrack('t1', 'Song One'),
        _makeTrack('t2', 'Song Two'),
        _makeTrack('t3', 'Song Three'),
      ];
      controller = _MockQueueController(tracks);
    });

    testWidgets('QueueSheet renders queue tracks with compact drag handles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [playbackControllerProvider.overrideWithValue(controller)],
          child: const MaterialApp(home: Scaffold(body: QueueSheet())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAY QUEUE'), findsOneWidget);
      expect(find.text('3 tracks'), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);

      // Verify drag handle '=' icons exist for items
      expect(find.byIcon(Icons.drag_handle_rounded), findsWidgets);
    });

    testWidgets(
      'Pulling down queue header with short distance dismisses the sheet',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playbackControllerProvider.overrideWithValue(controller),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const QueueSheet(),
                        );
                      },
                      child: const Text('Open Queue'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Open the queue bottom sheet
        await tester.tap(find.text('Open Queue'));
        await tester.pumpAndSettle();

        expect(find.byType(QueueSheet), findsOneWidget);

        // Pull down from the PLAY QUEUE header area by 45 pixels
        await tester.drag(find.text('PLAY QUEUE'), const Offset(0, 45));
        await tester.pumpAndSettle();

        // Sheet is dismissed with short distance pull
        expect(find.byType(QueueSheet), findsNothing);
      },
    );

    testWidgets('Dragging = icon reorders queue tracks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [playbackControllerProvider.overrideWithValue(controller)],
          child: const MaterialApp(home: Scaffold(body: QueueSheet())),
        ),
      );
      await tester.pumpAndSettle();

      final dragHandles = find.byIcon(Icons.drag_handle_rounded);
      expect(dragHandles, findsWidgets);

      // Drag first item's handle downwards past the 56px extent using TestGesture
      final drag = await tester.startGesture(
        tester.getCenter(dragHandles.first),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await drag.moveBy(const Offset(0, 20));
      await drag.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pumpAndSettle();

      expect(controller.reorderedOldIndex, isNotNull);
    });

    testWidgets(
      'QueueSheet renders duplicate tracks in queue without duplicate key assertion crash',
      (WidgetTester tester) async {
        final duplicateQueue = [
          _makeTrack('t1', 'Song One'),
          _makeTrack('t2', 'Song Two'),
          _makeTrack('t1', 'Song One'),
        ];
        final duplicateController = _MockQueueController(duplicateQueue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playbackControllerProvider.overrideWithValue(duplicateController),
            ],
            child: const MaterialApp(home: Scaffold(body: QueueSheet())),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Song One'), findsNWidgets(3));
      },
    );
  });
}
