import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/cue_parser.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/data/sources/artwork_service.dart';
import 'package:sonara/features/tag_editor/tag_editor_sheet.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.inMemory();
    tempDir = await Directory.systemTemp.createTemp('tag_editor_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets(
    'TagEditorSheet renders fields, allows edits and saves metadata',
    (tester) async {
      // Seed initial track
      final keys = await db.importCueTracks(
        audioPath: '/storage/emulated/0/Music/sample.mp3',
        contentUri: 'content://media/external/audio/media/10',
        cueTracks: [
          const CueTrack(
            trackNumber: 1,
            title: 'Initial Song',
            artist: 'Initial Artist',
            album: 'Initial Album',
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
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TagEditorSheet(track: track),
                    );
                  },
                  child: const Text('Open Editor'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Verify fields render
      expect(find.text('Edit Tags & Artwork'), findsOneWidget);
      expect(find.text('Track Title'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('Album'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Pick Image'), findsOneWidget);

      // Edit Title field
      final titleField = find.widgetWithText(TextField, 'Initial Song');
      expect(titleField, findsOneWidget);

      await tester.enterText(titleField, 'Edited Master Song');
      await tester.pump();

      // Tap Pick Image button
      await tester.tap(find.text('Pick Image'));
      await tester.pump();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      // Verify database was updated
      final updated = await db.getTrackByKey(track.trackKey);
      expect(updated?.title, 'Edited Master Song');
    },
  );
}
