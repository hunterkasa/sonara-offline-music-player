import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/cue_parser.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/lyrics_service.dart';
import 'package:sonara/features/lyrics/lyrics_editor_sheet.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late File sampleAudio;

  setUp(() async {
    db = AppDatabase.inMemory();
    tempDir = await Directory.systemTemp.createTemp('lyrics_editor_test_');
    sampleAudio = File('${tempDir.path}/song.mp3');
    await sampleAudio.writeAsBytes([0, 0, 0, 0]);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets(
    'LyricsEditorSheet renders lines, allows stamping, offset adjustments and saves LRC',
    (tester) async {
      final keys = await db.importCueTracks(
        audioPath: sampleAudio.path,
        contentUri: 'content://media/external/audio/media/99',
        cueTracks: [
          const CueTrack(
            trackNumber: 1,
            title: 'Studio Song',
            artist: 'Studio Artist',
            album: 'Studio Album',
            startTime: Duration.zero,
          ),
        ],
      );

      final track = (await db.getTrackByKey(keys.first))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            lyricsServiceProvider.overrideWithValue(LyricsService(db: db)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => LyricsEditorSheet(track: track),
                    );
                  },
                  child: const Text('Open Lyrics Studio'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Lyrics Studio'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verify main components render
      expect(find.text('LRC Lyrics Studio'), findsOneWidget);
      expect(find.text('Speed:'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('±100ms'), findsOneWidget);
      expect(find.text('Save .lrc'), findsOneWidget);

      // Initial lines exist
      expect(find.text('First verse starts here...'), findsOneWidget);
      expect(find.text('STAMP LINE 1 / 3'), findsOneWidget);

      // Stamp line 1
      await tester.tap(find.text('STAMP LINE 1 / 3'));
      await tester.pumpAndSettle();

      // Active stamp index advanced to line 2
      expect(find.text('STAMP LINE 2 / 3'), findsOneWidget);

      // Adjust offset +100ms
      await tester.tap(find.byTooltip('Offset +100ms'));
      await tester.pumpAndSettle();

      // Save .lrc
      await tester.tap(find.text('Save .lrc'));
      await tester.pumpAndSettle();

      // Verify .lrc file was written next to the sample audio file
      final lrcFile = File('${tempDir.path}/song.lrc');
      expect(lrcFile.existsSync(), isTrue);
      final lrcContent = lrcFile.readAsStringSync();
      expect(lrcContent, contains('[ti:Studio Song]'));
      expect(lrcContent, contains('First verse starts here...'));

      // Verify DB flag hasLyrics is updated
      final updated = await db.getTrackByKey(track.trackKey);
      expect(updated?.hasLyrics, isTrue);
    },
  );

  testWidgets('LyricsEditorSheet allows pasting plain lyrics via dialog', (
    tester,
  ) async {
    final keys = await db.importCueTracks(
      audioPath: sampleAudio.path,
      contentUri: 'content://media/external/audio/media/100',
      cueTracks: [
        const CueTrack(
          trackNumber: 2,
          title: 'Paste Lyric Song',
          artist: 'Paste Artist',
          album: 'Paste Album',
          startTime: Duration.zero,
        ),
      ],
    );

    final track = (await db.getTrackByKey(keys.first))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          lyricsServiceProvider.overrideWithValue(LyricsService(db: db)),
        ],
        child: MaterialApp(
          home: Scaffold(body: LyricsEditorSheet(track: track)),
        ),
      ),
    );

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Open Paste Dialog
    await tester.tap(find.byTooltip('Paste Plain Text'));
    await tester.pumpAndSettle();

    expect(find.text('Edit / Paste Plain Lyrics'), findsOneWidget);
    expect(find.text('Apply Lines'), findsOneWidget);

    // Enter new lyrics text
    final textField = find.widgetWithText(
      TextField,
      'First verse starts here...',
    );
    if (textField.evaluate().isNotEmpty) {
      await tester.enterText(
        textField,
        'New Line One\nNew Line Two\nNew Line Three\nNew Line Four',
      );
    } else {
      await tester.enterText(
        find.byType(TextField).last,
        'New Line One\nNew Line Two\nNew Line Three\nNew Line Four',
      );
    }
    await tester.pump();

    // Apply lines
    await tester.tap(find.text('Apply Lines'));
    await tester.pumpAndSettle();

    // Verify dialog closed and new lines rendered
    expect(find.text('New Line One'), findsOneWidget);
    expect(find.text('New Line Four'), findsOneWidget);
    expect(find.text('STAMP LINE 1 / 4'), findsOneWidget);
  });
}
