import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/audio_intent_service.dart';
import 'package:sonara/core/services/widget_service.dart';
import 'package:sonara/data/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late StubPlaybackController controller;
  late AudioIntentService intentService;
  String? navigatedRoute;

  setUp(() {
    db = AppDatabase.inMemory();
    controller = StubPlaybackController();
    navigatedRoute = null;
    intentService = AudioIntentService(
      playbackController: controller,
      db: db,
      onNavigate: (route) => navigatedRoute = route,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AudioIntentService', () {
    test('handles existing track URI and plays track', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'track_existing',
              contentUri: 'content://media/external/audio/media/100',
              path: '/music/song.mp3',
              title: 'Song 100',
              titleSort: 'song 100',
              durationMs: 120000,
              sizeBytes: 1000000,
            ),
          );

      await intentService.handleAudioUri(
        'content://media/external/audio/media/100',
      );
      expect(controller.currentSnapshot.isPlaying, isTrue);
    });

    test('handles unindexed external file URI gracefully', () async {
      await intentService.handleAudioUri(
        'file:///storage/emulated/0/Download/new_track.mp3',
      );
      expect(controller.currentSnapshot.isPlaying, isTrue);

      final allTracks = await db.getAllTracks();
      expect(allTracks.any((t) => t.path.contains('new_track.mp3')), isTrue);
    });

    test('handles sonara://shuffle deep link', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'shuf_1',
              contentUri: 'content://media/1',
              path: '/p1',
              title: 'Track A',
              titleSort: 'track a',
              durationMs: 60000,
              sizeBytes: 5000,
            ),
          );

      await intentService.handleAudioUri('sonara://shuffle');
      expect(controller.currentSnapshot.isPlaying, isTrue);
    });

    test('handles sonara://favorites deep link', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'fav_1',
              contentUri: 'content://media/2',
              path: '/p2',
              title: 'Fav A',
              titleSort: 'fav a',
              durationMs: 60000,
              sizeBytes: 5000,
              isFavorite: const Value(true),
            ),
          );

      await intentService.handleAudioUri('sonara://favorites');
      expect(controller.currentSnapshot.isPlaying, isTrue);
    });

    test('handles sonara://search deep link via navigation callback', () async {
      await intentService.handleAudioUri('sonara://search');
      expect(navigatedRoute, equals('/search'));
    });
  });

  group('WidgetService', () {
    test('updates widget without throwing unhandled exceptions', () async {
      final widgetService = WidgetService(playbackController: controller);
      await expectLater(
        widgetService.updateWidget(
          title: 'Test Song',
          artist: 'Test Artist',
          isPlaying: true,
        ),
        completes,
      );
      widgetService.dispose();
    });
  });
}
