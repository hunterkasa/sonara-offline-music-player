import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/cue_parser.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/data/sources/artwork_service.dart';
import 'package:sonara/shared/sheets/song_cover_picker_sheet.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.inMemory();
    tempDir = await Directory.systemTemp.createTemp('song_cover_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets(
    'SongCoverPickerSheet renders, selects presets, and resets artwork',
    (tester) async {
      final keys = await db.importCueTracks(
        audioPath: '/storage/emulated/0/Music/track.mp3',
        contentUri: 'content://media/external/audio/media/100',
        cueTracks: [
          const CueTrack(
            trackNumber: 1,
            title: 'Sample Song',
            artist: 'Sample Artist',
            album: 'Sample Album',
            startTime: Duration.zero,
          ),
        ],
      );

      final track = (await db.getTrackByKey(keys.first))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            artworkServiceProvider.overrideWithValue(ArtworkService(tempDir)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SongCoverPickerSheet.show(context, track),
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify Header and Options
      expect(find.text('Song Icon & Artwork'), findsOneWidget);
      expect(find.text('Sample Song'), findsOneWidget);
      expect(find.text('Choose Photo'), findsOneWidget);
      expect(find.text('Default Styles'), findsOneWidget);

      // Verify presets are displayed
      expect(find.text('Neon Synth'), findsOneWidget);
      expect(find.text('Midnight Vibes'), findsOneWidget);

      // Tap on a preset (e.g. Neon Synth)
      await tester.tap(find.text('Neon Synth'));
      await tester.pumpAndSettle();

      // Verify SnackBar and selected checkmark
      expect(find.text('Selected "Neon Synth" preset'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Verify database updated
      final updatedTrack = await db.getTrackByKey(track.trackKey);
      expect(updatedTrack?.artworkKey, equals('preset:neon_synth'));

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Verify reset in database
      expect(find.text('Song artwork reset to default'), findsOneWidget);
      final resetTrack = await db.getTrackByKey(track.trackKey);
      expect(resetTrack?.artworkKey, isNull);
    },
  );
}
