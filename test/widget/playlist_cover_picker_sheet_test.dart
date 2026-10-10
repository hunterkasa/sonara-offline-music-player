import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/playlist/playlist_cover_picker_sheet.dart';

void main() {
  group('PlaylistCoverPickerSheet Widget Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'renders cover picker with gallery button and default presets',
      (tester) async {
        final playlistId = await db.createPlaylist(name: 'My Vibes');
        final playlist = await db.getPlaylist(playlistId);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(
                body: PlaylistCoverPickerSheet(playlist: playlist!),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Playlist Artwork'), findsOneWidget);
        expect(find.text('My Vibes'), findsOneWidget);
        expect(find.text('Choose Photo'), findsOneWidget);
        expect(find.text('Default Styles'), findsOneWidget);
        expect(find.text('Neon Synth'), findsOneWidget);
        expect(find.text('Sunset Chill'), findsOneWidget);
      },
    );

    testWidgets('tapping a preset updates the playlist cover in database', (
      tester,
    ) async {
      final playlistId = await db.createPlaylist(name: 'Chill Beats');
      final playlist = await db.getPlaylist(playlistId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(body: PlaylistCoverPickerSheet(playlist: playlist!)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on "Sunset Chill" preset
      final sunsetPresetFinder = find.text('Sunset Chill');
      expect(sunsetPresetFinder, findsOneWidget);
      await tester.tap(sunsetPresetFinder);
      await tester.pumpAndSettle();

      // Check database update
      final updated = await db.getPlaylist(playlistId);
      expect(updated!.coverUri, equals('preset:sunset_chill'));
      expect(find.text('Selected "Sunset Chill" preset'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      final resetPlaylist = await db.getPlaylist(playlistId);
      expect(resetPlaylist!.coverUri, isNull);
      expect(find.text('Cover reset to default'), findsOneWidget);
    });
  });
}
