import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/data/sources/artwork_service.dart';
import 'package:sonara/domain/services/daily_mix_service.dart';
import 'package:sonara/domain/services/track_radio_service.dart';
import 'package:sonara/shared/cards/daily_mix_card.dart';
import 'package:sonara/shared/cards/todays_pick_card.dart';

class MockPlaybackController extends StubPlaybackController {
  List<String> lastPlayedQueue = [];
  int lastInitialIndex = -1;

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    lastPlayedQueue = trackKeys;
    lastInitialIndex = initialIndex;
  }
}

void main() {
  late AppDatabase db;
  late MockPlaybackController mockPlayback;
  late TrackRadioService radioService;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    db = AppDatabase.inMemory();
    mockPlayback = MockPlaybackController();
    radioService = TrackRadioService(db: db, playbackController: mockPlayback);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const sampleTrack = Track(
    id: 1,
    trackKey: 'sample_key_1',
    contentUri: 'content://music/1',
    path: '/storage/sample_1.mp3',
    relativeDir: 'Music',
    title: 'Starman',
    titleSort: 'starman',
    durationMs: 250000,
    sizeBytes: 3000000,
    hasLyrics: false,
    playCount: 12,
    skipCount: 0,
    isFavorite: true,
    isHidden: false,
    isMissing: false,
    rating: 5,
  );

  testWidgets('TodaysPickCard renders metadata and triggers playback', (
    WidgetTester tester,
  ) async {
    const pick = TodaysPick(
      track: sampleTrack,
      artistName: 'David Bowie',
      albumTitle: 'The Rise and Fall of Ziggy Stardust',
      reason: 'In your heavy rotation',
      dateLabel: 'Wed, Oct 7',
      queue: [sampleTrack],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          playbackControllerProvider.overrideWithValue(mockPlayback),
          trackRadioServiceProvider.overrideWithValue(radioService),
          artworkServiceProvider.overrideWithValue(ArtworkService(tempDir)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TodaysPickCard(pick: pick)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S PICK • WED, OCT 7"), findsOneWidget);
    expect(find.text('Starman'), findsOneWidget);
    expect(find.text('David Bowie'), findsOneWidget);
    expect(find.text('The Rise and Fall of Ziggy Stardust'), findsOneWidget);
    expect(find.text('In your heavy rotation'), findsOneWidget);
    expect(find.text('Start Radio (1 songs)'), findsOneWidget);

    // Check play button exists and triggers playQueue
    final playBtn = find.byIcon(Icons.play_arrow_rounded);
    expect(playBtn, findsWidgets);
    await tester.tap(playBtn.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(mockPlayback.lastPlayedQueue, contains('sample_key_1'));
  });

  testWidgets(
    'DailyMixCard renders Spotify-style card and triggers play queue',
    (WidgetTester tester) async {
      const mix = DailyMix(
        id: -101,
        index: 1,
        title: 'Daily Mix 1',
        subtitle: 'David Bowie, Queen, Elton John',
        description: 'Featuring David Bowie, Queen and more',
        tracks: [sampleTrack],
        primaryColor: Color(0xFF00B4D8),
        secondaryColor: Color(0xFF03045E),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            playbackControllerProvider.overrideWithValue(mockPlayback),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DailyMixCard(mix: mix)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY MIX'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Daily Mix 1'), findsOneWidget);
      expect(find.text('David Bowie, Queen, Elton John'), findsOneWidget);

      // Tap circular play FAB
      final playIcon = find.byIcon(Icons.play_arrow_rounded);
      expect(playIcon, findsOneWidget);
      await tester.tap(playIcon);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(mockPlayback.lastPlayedQueue, equals(['sample_key_1']));
    },
  );
}
